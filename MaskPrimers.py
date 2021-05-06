#!/home/ezio/anaconda3/bin/python3.6
"""
Removes primers and annotates sequences with primer and barcode identifiers
"""
# Info
__author__ = 'Jason Anthony Vander Heiden'
from presto import __version__, __date__

# Imports
import os
from argparse import ArgumentParser
from collections import OrderedDict
from textwrap import dedent

# Presto imports
from presto.Defaults import default_delimiter, default_out_args, default_primer_gap_penalty, default_primer_max_error, \
                            default_primer_max_len, default_primer_start, default_barcode_field, default_primer_field
from presto.Commandline import CommonHelpFormatter, checkArgs, getCommonArgParser, parseCommonArgs
from presto.Sequence import localAlignment, compilePrimers, extractAlignment, getDNAScoreDict, \
                            maskSeq, reverseComplement, scoreAlignment
from presto.IO import readPrimerFile, printLog
from presto.Multiprocessing import SeqResult, manageProcesses, feedSeqQueue, \
                                   processSeqQueue, collectSeqQueue


def extractPrimers(data, start, length, rev_primer=False, mode='mask', barcode=False,
                   barcode_field=default_barcode_field, primer_field=default_primer_field,
                   delimiter=default_delimiter):
    """
    Extracts primer sequences directly

    Arguments:
      data : SeqData object containing a single SeqRecord object to process.
      start : position where subsequence starts.
      length : the length of the subsequence to extract.
      rev_primer : if True extract relative to the tail end of the sequence.
      mode : defines the action taken; one of 'cut', 'mask', 'tag' or 'trim'.
      barcode : if True add sequence preceding primer to description.
      barcode_field : name of the output barcode annotation.
      primer_field : name of the output primer annotation.
      delimiter : a tuple of delimiters for (annotations, field/values, value lists).

    Returns:
      presto.Multiprocessing.SeqResult: result object.
    """
    # Define result object
    result = SeqResult(data.id, data.data)

    # Align primers
    align = extractAlignment(data.data, start=start, length=length, rev_primer=rev_primer)
    if not align:
        result.log['ALIGN'] = None
        return result

    # Create output sequence
    out_seq = maskSeq(align, mode=mode, barcode=barcode, barcode_field=barcode_field,
                      primer_field=primer_field, delimiter=delimiter)
    result.results = out_seq
    result.valid = True

    # Update log with successful alignment results
    result.log['PRIMER'] = align.primer
    result.log['PRSTART'] = align.start
    if 'barcode' in out_seq.annotations:
        result.log['BARCODE'] = out_seq.annotations['barcode']
    if not align.rev_primer:
        align_cut = len(align.align_seq) - align.gaps
        result.log['INSEQ'] = align.align_seq + str(align.seq.seq[align_cut:])
        result.log['ALIGN'] = align.align_primer
        result.log['OUTSEQ'] = str(out_seq.seq).rjust(len(result.data.seq) + align.gaps)
    else:
        align_cut = len(align.seq) - len(align.align_seq) + align.gaps
        result.log['INSEQ'] = str(align.seq.seq[:align_cut]) + align.align_seq
        result.log['ALIGN'] = align.align_primer.rjust(len(result.data.seq) + align.gaps)
        result.log['OUTSEQ'] = str(out_seq.seq)

    return result


def alignPrimers(data, primers, primers_regex=None, max_error=default_primer_max_error,
                 max_len=default_primer_max_len, rev_primer=False, skip_rc=False, mode='mask',
                 barcode=False, barcode_field=default_barcode_field, primer_field=default_primer_field,
                 gap_penalty=default_primer_gap_penalty, score_dict=getDNAScoreDict(mask_score=(0, 1), gap_score=(0, 0)),
                 delimiter=default_delimiter):
    """
    Performs pairwise local alignment of a list of short sequences against a long sequence

    Arguments:
      data : SeqData object containing a single SeqRecord object to process.
      primers : dictionary of {names: short IUPAC ambiguous sequence strings}.
      primers_regex : optional dictionary of {names: compiled primer regular expressions}.
      max_error : maximum acceptable error rate for a valid alignment.
      max_len : maximum length of sample sequence to align.
      rev_primer : if True align with the tail end of the sequence.
      skip_rc : if True do not check reverse complement sequences.
      mode : defines the action taken; one of 'cut', 'mask', 'tag' or 'trim'.
      barcode : if True add sequence preceding primer to description.
      barcode_field : name of the output barcode annotation.
      primer_field : name of the output primer annotation.
      gap_penalty : a tuple of positive (gap open, gap extend) penalties.
      score_dict : optional dictionary of {(char1, char2): score} alignment scores
      delimiter : a tuple of delimiters for (annotations, field/values, value lists).

    Returns:
      presto.Multiprocessing.SeqResult: result object.
    """
    # Define result object
    result = SeqResult(data.id, data.data)

    # Align primers
    align = localAlignment(data.data, primers, primers_regex=primers_regex, max_error=max_error,
                           max_len=max_len, rev_primer=rev_primer, skip_rc=skip_rc,
                           gap_penalty=gap_penalty, score_dict=score_dict)
    if not align:
        # Update log if no alignment
        result.log['ALIGN'] = None
        return result

    # Create output sequence
    out_seq = maskSeq(align, mode=mode, barcode=barcode, barcode_field=barcode_field,
                      primer_field=primer_field, delimiter=delimiter)
    result.results = out_seq
    result.valid = bool(align.error <= max_error) if len(out_seq) > 0 else False

    # Update log with successful alignment results
    result.log['SEQORIENT'] = out_seq.annotations['seqorient']
    result.log['PRIMER'] = align.primer
    result.log['PRORIENT'] = 'RC' if align.rev_primer else 'F'
    result.log['PRSTART'] = align.start
    if 'barcode' in out_seq.annotations:
        result.log['BARCODE'] = out_seq.annotations['barcode']
    if not align.rev_primer:
        align_cut = len(align.align_seq) - align.gaps
        result.log['INSEQ'] = align.align_seq + \
                              str(align.seq.seq[align_cut:])
        result.log['ALIGN'] = align.align_primer
        result.log['OUTSEQ'] = str(out_seq.seq).rjust(len(result.data.seq) + align.gaps)
    else:
        align_cut = len(align.seq) - len(align.align_seq) + align.gaps
        result.log['INSEQ'] = str(align.seq.seq[:align_cut]) + align.align_seq
        result.log['ALIGN'] = align.align_primer.rjust(len(result.data.seq) + align.gaps)
        result.log['OUTSEQ'] = str(out_seq.seq)
    result.log['ERROR'] = align.error

    return result


def scorePrimers(data, primers, max_error=default_primer_max_error, start=default_primer_start, rev_primer=False, mode='mask',
                 barcode=False, barcode_field=default_barcode_field, primer_field=default_primer_field,
                 score_dict=getDNAScoreDict(mask_score=(0, 1), gap_score=(0, 0)),
                 delimiter=default_delimiter):
    """
    Performs a simple fixed position alignment of primers

    Arguments:
      data : SeqData object containing a single SeqRecord object to process.
      primers : dictionary of {names: short IUPAC ambiguous sequence strings}.
      max_error : maximum acceptable error rate for a valid alignment
      start : position where primer alignment starts.
      rev_primer : if True align with the tail end of the sequence.
      mode : defines the action taken; one of 'cut', 'mask', 'tag' or 'trim'.
      barcode : if True add sequence preceding primer to description.
      barcode_field : name of the output barcode annotation.
      primer_field : name of the output primer annotation.
      score_dict : optional dictionary of {(char1, char2): score} alignment scores
      delimiter : a tuple of delimiters for (annotations, field/values, value lists).

    Returns:
      presto.Multiprocessing.SeqResult: result object.
    """
    # Define result object
    result = SeqResult(data.id, data.data)

    # Align primers
    align = scoreAlignment(data.data, primers, start=start, rev_primer=rev_primer,
                           score_dict=score_dict)
    if not align:
        # Update log if no alignment
        result.log['ALIGN'] = None
        return result

    # Create output sequence
    out_seq = maskSeq(align, mode=mode, barcode=barcode, barcode_field=barcode_field,
                      primer_field=primer_field, delimiter=delimiter)
    result.results = out_seq
    result.valid = bool(align.error <= max_error) if len(out_seq) > 0 else False

    # Update log with successful alignment results
    result.log['PRIMER'] = align.primer
    result.log['PRORIENT'] = 'RC' if align.rev_primer else 'F'
    result.log['PRSTART'] = align.start
    if 'barcode' in out_seq.annotations:
        result.log['BARCODE'] = out_seq.annotations['barcode']
    if not align.rev_primer:
        align_cut = len(align.align_seq) - align.gaps
        result.log['INSEQ'] = align.align_seq + \
                              str(align.seq.seq[align_cut:])
        result.log['ALIGN'] = align.align_primer
        result.log['OUTSEQ'] = str(out_seq.seq).rjust(len(result.data.seq) + align.gaps)
    else:
        align_cut = len(align.seq) - len(align.align_seq) + align.gaps
        result.log['INSEQ'] = str(align.seq.seq[:align_cut]) + align.align_seq
        result.log['ALIGN'] = align.align_primer.rjust(len(result.data.seq) + align.gaps)
        result.log['OUTSEQ'] = str(out_seq.seq)
    result.log['ERROR'] = align.error

    return result


def maskPrimers(seq_file, primer_file, align_func, align_args={},
                out_file=None, out_args=default_out_args,
                nproc=None, queue_size=None):
    """
    Masks or cuts primers from sample sequences using local alignment

    Arguments: 
      seq_file : name of file containing sample sequences.
      primer_file : name of the file containing primer sequences.
      align_func : the function to call for alignment.
      align_arcs : a dictionary of arguments to pass to align_func.
      out_file : output file name. Automatically generated from the input file if None.
      out_args : common output argument dictionary from parseCommonArgs.
      nproc : the number of processQueue processes;
              if None defaults to the number of CPUs.
      queue_size : maximum size of the argument queue;
                   if None defaults to 2*nproc.
                 
    Returns:
      list: a list of successful output file names.
    """
    # Define subcommand label dictionary
    cmd_dict = {alignPrimers: 'align', scorePrimers: 'score', extractPrimers: 'extract'}
    
    # Print parameter info
    log = OrderedDict()
    log['START'] = 'MaskPrimers'
    log['COMMAND'] = cmd_dict.get(align_func, align_func.__name__)
    log['SEQ_FILE'] = os.path.basename(seq_file)
    if primer_file is not None:
        log['PRIMER_FILE'] = os.path.basename(primer_file)
    if 'mode' in align_args: log['MODE'] = align_args['mode']
    if 'max_error' in align_args: log['MAX_ERROR'] = align_args['max_error']
    if 'start' in align_args: log['START_POS'] = align_args['start']
    if 'length' in align_args: log['LENGTH'] = align_args['length']
    if 'max_len' in align_args: log['MAX_LEN'] = align_args['max_len']
    if 'rev_primer' in align_args: log['REV_PRIMER'] = align_args['rev_primer']
    if 'skip_rc' in align_args: log['SKIP_RC'] = align_args['skip_rc']
    if 'gap_penalty' in align_args:
        log['GAP_PENALTY'] = ', '.join([str(x) for x in align_args['gap_penalty']])
    if 'barcode' in align_args:
        log['BARCODE'] = align_args['barcode']
    if 'barcode' in align_args and align_args['barcode']:
        log['BARCODE_FIELD'] = align_args['barcode_field']
    log['PRIMER_FIELD'] = align_args['primer_field']
    log['NPROC'] = nproc
    printLog(log)

    # Define alignment arguments and compile primers for align mode
    if primer_file is not None:
        primers = readPrimerFile(primer_file)
        if 'rev_primer' in align_args and align_args['rev_primer']:
            primers = {k: reverseComplement(v) for k, v in primers.items()}
        align_args['primers'] = primers
        align_args['score_dict'] = getDNAScoreDict(mask_score=(0, 1), gap_score=(0, 0))
    if align_func is alignPrimers:
        align_args['primers_regex'] = compilePrimers(primers)
    align_args['delimiter'] = out_args['delimiter']

    # Define feeder function and arguments
    feed_func = feedSeqQueue
    feed_args = {'seq_file': seq_file}
    # Define worker function and arguments
    work_func = processSeqQueue
    work_args = {'process_func': align_func,
                 'process_args': align_args}
    # Define collector function and arguments
    collect_func = collectSeqQueue
    collect_args = {'seq_file': seq_file,
                    'label': 'primers',
                    'out_file': out_file,
                    'out_args': out_args}
    
    # Call process manager
    result = manageProcesses(feed_func, work_func, collect_func, 
                             feed_args, work_args, collect_args, 
                             nproc, queue_size)

    # Print log
    result['log']['END'] = 'MaskPrimers'
    printLog(result['log'])
        
    return result['out_files']


def getArgParser():
    """
    Defines the ArgumentParser

    Returns:
      argparse.ArgumentParser: argument parser object.
    """
    # Define output file names and header fields
    fields = dedent(
             '''
             output files:
                 mask-pass
                     processed reads with successful primer matches.
                 mask-fail
                     raw reads failing primer identification.

             output annotation fields:
                 SEQORIENT
                     the orientation of the output sequence. Either F (input) or RC
                     (reverse complement of input).
                 PRIMER
                     name of the best primer match.
                 BARCODE
                     the sequence preceding the primer match. Only output when the
                     --barcode flag is specified.
             ''')

    # Define ArgumentParser
    parser = ArgumentParser(description=__doc__, epilog=fields,
                            formatter_class=CommonHelpFormatter, add_help=False)
    group_help = parser.add_argument_group('help')
    group_help.add_argument('--version', action='version',
                            version='%(prog)s:' + ' %s %s' %(__version__, __date__))
    group_help.add_argument('-h', '--help', action='help', help='show this help message and exit')
    subparsers = parser.add_subparsers(title='subcommands', metavar='',
                                       help='Alignment method')
    # TODO:  This is a temporary fix for Python issue 9253
    subparsers.required = True
    
    # Parent parser
    parent_parser = getCommonArgParser(multiproc=True)

    # Align mode argument parser
    parser_align = subparsers.add_parser('align', parents=[parent_parser],
                                         formatter_class=CommonHelpFormatter, add_help=False,
                                         help='Find primer matches using pairwise local alignment.',
                                         description='Find primer matches using pairwise local alignment.')
    group_align = parser_align.add_argument_group('primer alignment arguments')
    group_align.add_argument('-p', action='store', dest='primer_file', required=True,
                              help='A FASTA file containing primer sequences.')
    group_align.add_argument('--maxerror', action='store', dest='max_error', type=float,
                             default=default_primer_max_error, help='Maximum allowable error rate.')
    group_align.add_argument('--maxlen', action='store', dest='max_len', type=int,
                             default=default_primer_max_len,
                             help='''Length of the sequence window to scan for primers.''')
    group_align.add_argument('--gap', nargs=2, action='store', dest='gap_penalty',
                             type=float, default=default_primer_gap_penalty,
                             help='''A list of two positive values defining the gap open
                                   and gap extension penalties for aligning the primers.
                                   Note: the error rate is calculated as the percentage
                                   of mismatches from the primer sequence with gap
                                   penalties reducing the match count accordingly; this may
                                   lead to error rates that differ from strict mismatch
                                   percentage when gaps are present in the alignment.''')
    group_align.add_argument('--revpr', action='store_true', dest='rev_primer',
                              help='''Specify to match the tail-end of the sequence against the
                                   reverse complement of the primers. This also reverses the
                                   behavior of the --maxlen argument, such that the search
                                   window begins at the tail-end of the sequence.''')
    group_align.add_argument('--skiprc', action='store_true', dest='skip_rc',
                              help='Specify to prevent checking of sample reverse complement sequences.')
    group_align.add_argument('--mode', action='store', dest='mode',
                              choices=('cut', 'mask', 'trim', 'tag'), default='mask',
                              help='''Specifies the action to take with the primer sequence.
                                   The "cut" mode will remove both the primer region and
                                   the preceding sequence. The "mask" mode will replace the
                                   primer region with Ns and remove the preceding sequence.
                                   The "trim" mode will remove the region preceding the primer,
                                   but leave the primer region intact. The "tag" mode will
                                   leave the input sequence unmodified.''')
    group_align.add_argument('--barcode', action='store_true', dest='barcode',
                              help='''Specify to annotate reads sequences with barcode sequences
                                   (unique molecular identifiers) found preceding the primer.''')
    group_align.add_argument('--bf', action='store', dest='barcode_field', default=default_barcode_field,
                             help='''Name of the barcode annotation field.''')
    group_align.add_argument('--pf', action='store', dest='primer_field', default=default_primer_field,
                             help='''Name of the annotation field containing the primer name.''')
    parser_align.set_defaults(align_func=alignPrimers)

    # Score mode argument parser
    parser_score = subparsers.add_parser('score', parents=[parent_parser],
                                         formatter_class=CommonHelpFormatter, add_help=False,
                                         help='Find primer matches by scoring primers at a fixed position.',
                                         description='Find primer matches by scoring primers at a fixed position.')
    group_score = parser_score.add_argument_group('primer scoring arguments')
    group_score.add_argument('-p', action='store', dest='primer_file', required=True,
                              help='A FASTA file containing primer sequences.')
    group_score.add_argument('--start', action='store', dest='start', type=int, default=default_primer_start,
                             help='The starting position of the primer.')
    group_score.add_argument('--maxerror', action='store', dest='max_error', type=float,
                             default=default_primer_max_error, help='Maximum allowable error rate.')
    group_score.add_argument('--revpr', action='store_true', dest='rev_primer',
                              help='''Specify to match the tail-end of the sequence against the
                                   reverse complement of the primers. This also reverses the
                                   behavior of the --start argument, such that start position is 
                                   relative to the tail-end of the sequence.''')
    group_score.add_argument('--mode', action='store', dest='mode',
                              choices=('cut', 'mask', 'trim', 'tag'), default='mask',
                              help='''Specifies the action to take with the primer sequence.
                                   The "cut" mode will remove both the primer region and
                                   the preceding sequence. The "mask" mode will replace the
                                   primer region with Ns and remove the preceding sequence.
                                   The "trim" mode will remove the region preceding the primer,
                                   but leave the primer region intact. The "tag" mode will
                                   leave the input sequence unmodified.''')
    group_score.add_argument('--barcode', action='store_true', dest='barcode',
                              help='''Specify to annotate reads sequences with barcode sequences
                                   (unique molecular identifiers) found preceding the primer.''')
    group_score.add_argument('--bf', action='store', dest='barcode_field', default=default_barcode_field,
                             help='''Name of the barcode annotation field.''')
    group_score.add_argument('--pf', action='store', dest='primer_field', default=default_primer_field,
                             help='''Name of the annotation field containing the primer name.''')
    parser_score.set_defaults(align_func=scorePrimers)

    # Extract mode argument parser
    parser_extract = subparsers.add_parser('extract', parents=[parent_parser],
                                           formatter_class=CommonHelpFormatter, add_help=False,
                                           help='Remove and annotate a fixed sequence region.',
                                           description='Remove and annotate a fixed sequence region.')
    group_extract = parser_extract.add_argument_group('region extraction arguments')
    group_extract.add_argument('--start', action='store', dest='start', type=int, default=default_primer_start,
                               help='The starting position of the sequence region to extract.')
    group_extract.add_argument('--len', action='store', dest='length', type=int, required=True,
                               help='The length of the sequence to extract.')
    group_extract.add_argument('--revpr', action='store_true', dest='rev_primer',
                               help='''Specify to extract from the tail end of the sequence with the start
                                    position relative to the end of the sequence.''')
    group_extract.add_argument('--mode', action='store', dest='mode',
                               choices=('cut', 'mask', 'trim', 'tag'), default='mask',
                               help='''Specifies the action to take with the sequence region.
                                    The "cut" mode will remove the region. 
                                    The "mask" mode will replace the specified region with Ns.
                                    The "trim" mode will remove the sequence preceding the specified region,
                                    but leave the region intact. 
                                    The "tag" mode will leave the input sequence unmodified.''')
    group_extract.add_argument('--barcode', action='store_true', dest='barcode',
                               help='''Specify to remove the sequence preceding the extracted region and
                                    annotate the read with that sequence.''')
    group_extract.add_argument('--bf', action='store', dest='barcode_field', default=default_barcode_field,
                               help='''Name of the barcode annotation field.''')
    group_extract.add_argument('--pf', action='store', dest='primer_field', default=default_primer_field,
                               help='''Name of the annotation field containing the extracted sequence region.''')
    parser_extract.set_defaults(align_func=extractPrimers)

    return parser



if __name__ == '__main__':
    """
    Parses command line arguments and calls main function
    """
    # Parse arguments
    parser = getArgParser()
    checkArgs(parser)
    args = parser.parse_args()
    args_dict = parseCommonArgs(args)
    
    # Define align_args dictionary to pass to maskPrimers
    if args_dict['align_func'] is alignPrimers:
        args_dict['align_args'] = {'max_error': args_dict['max_error'],
                                   'max_len':args_dict['max_len'],
                                   'rev_primer':args_dict['rev_primer'],
                                   'skip_rc':args_dict['skip_rc'],
                                   'gap_penalty':args_dict['gap_penalty'],
                                   'mode': args_dict['mode'],
                                   'barcode': args_dict['barcode'],
                                   'barcode_field': args_dict['barcode_field'],
                                   'primer_field': args_dict['primer_field']}

        del args_dict['max_error']
        del args_dict['max_len']
        del args_dict['rev_primer']
        del args_dict['skip_rc']
        del args_dict['gap_penalty']
        del args_dict['mode']
        del args_dict['barcode']
        del args_dict['barcode_field']
        del args_dict['primer_field']
    elif args_dict['align_func'] is scorePrimers:
        args_dict['align_args'] = {'max_error': args_dict['max_error'],
                                   'start':args_dict['start'],
                                   'rev_primer':args_dict['rev_primer'],
                                   'mode': args_dict['mode'],
                                   'barcode': args_dict['barcode'],
                                   'barcode_field': args_dict['barcode_field'],
                                   'primer_field': args_dict['primer_field']}
        del args_dict['max_error']
        del args_dict['start']
        del args_dict['rev_primer']
        del args_dict['mode']
        del args_dict['barcode']
        del args_dict['barcode_field']
        del args_dict['primer_field']
    elif args_dict['align_func'] is extractPrimers:
        args_dict['primer_file'] = None
        args_dict['align_args'] = {'start':args_dict['start'],
                                   'length':args_dict['length'],
                                   'rev_primer': args_dict['rev_primer'],
                                   'mode':args_dict['mode'],
                                   'barcode': args_dict['barcode'],
                                   'barcode_field': args_dict['barcode_field'],
                                   'primer_field': args_dict['primer_field']}
        del args_dict['start']
        del args_dict['length']
        del args_dict['rev_primer']
        del args_dict['mode']
        del args_dict['barcode']
        del args_dict['barcode_field']
        del args_dict['primer_field']

    # Call maskPrimers for each sample file
    del args_dict['seq_files']
    if 'out_files' in args_dict:  del args_dict['out_files']
    for i, f in enumerate(args.__dict__['seq_files']):
        args_dict['seq_file'] = f
        args_dict['out_file'] = args.__dict__['out_files'][i] \
            if args.__dict__['out_files'] else None
        maskPrimers(**args_dict)
    