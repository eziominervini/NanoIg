
###############################################################################
 #
 #  This file is part of canu, a software program that assembles whole-genome
 #  sequencing reads into contigs.
 #
 #  This software is based on:
 #    'Celera Assembler' (http://wgs-assembler.sourceforge.net)
 #    the 'kmer package' (http://kmer.sourceforge.net)
 #  both originally distributed by Applera Corporation under the GNU General
 #  Public License, version 2.
 #
 #  Canu branched from Celera Assembler at its revision 4587.
 #  Canu branched from the kmer project at its revision 1994.
 #
 #  This file is derived from:
 #
 #    src/pipelines/ca3g/Output.pm
 #
 #  Modifications by:
 #
 #    Brian P. Walenz from 2015-MAR-16 to 2015-AUG-25
 #      are Copyright 2015 Battelle National Biodefense Institute, and
 #      are subject to the BSD 3-Clause License
 #
 #    Brian P. Walenz beginning on 2015-NOV-02
 #      are a 'United States Government Work', and
 #      are released in the public domain
 #
 #    Sergey Koren beginning on 2015-DEC-02
 #      are a 'United States Government Work', and
 #      are released in the public domain
 #
 #  File 'README.licenses' in the root directory of this distribution contains
 #  full conditions and disclaimers for each license.
 ##

package canu::Output;

require Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw(generateOutputs);

use strict;
use warnings "all";
no  warnings "uninitialized";

use File::Copy;

use canu::Defaults;
use canu::Execution;

use canu::Report;

use canu::Grid_Cloud;



sub generateOutputs ($) {
    my $asm     = shift @_;
    my $bin     = getBinDirectory();
    my $cmd;

    my $type    = "fasta";  #  Should probably be an option.

    #  Layouts

    if (! fileExists("$asm.contigs.layout")) {
        fetchFile("unitigging/$asm.ctgStore/seqDB.v002.dat");
        fetchFile("unitigging/$asm.ctgStore/seqDB.v002.tig");

        if (-e "unitigging/$asm.ctgStore/seqDB.v002.tig") {
            $cmd  = "$bin/tgStoreDump \\\n";
            $cmd .= "  -S ./$asm.seqStore \\\n";
            $cmd .= "  -T ./unitigging/$asm.ctgStore 2 \\\n";
            $cmd .= "  -o ./$asm.contigs \\\n";
            $cmd .= "  -layout \\\n";
            $cmd .= "> ./$asm.contigs.layout.err 2>&1";

            if (runCommand(".", $cmd)) {
                caExit("failed to output contig layouts", "$asm.contigs.layout.err");
            }

            unlink "$asm.contigs.layout.err";
        } else {
            touch("$asm.contigs.layout");
        }

        stashFile("$asm.contigs.layout");
    }

    if (! fileExists("$asm.unitigs.layout")) {
        fetchFile("unitigging/$asm.utgStore/seqDB.v001.dat");   #  Why is this needed?
        fetchFile("unitigging/$asm.utgStore/seqDB.v001.tig");

        fetchFile("unitigging/$asm.utgStore/seqDB.v002.dat");
        fetchFile("unitigging/$asm.utgStore/seqDB.v002.tig");

        if (-e "unitigging/$asm.utgStore/seqDB.v002.tig") {
            $cmd  = "$bin/tgStoreDump \\\n";
            $cmd .= "  -S ./$asm.seqStore \\\n";
            $cmd .= "  -T ./unitigging/$asm.utgStore 2 \\\n";
            $cmd .= "  -o ./$asm.unitigs \\\n";
            $cmd .= "  -layout \\\n";
            $cmd .= "> ./$asm.unitigs.layout.err 2>&1";

            if (runCommand(".", $cmd)) {
                caExit("failed to output unitig layouts", "$asm.unitigs.layout.err");
            }

            unlink "$asm.unitigs.layout.err";
        } else {
            touch("$asm.unitigs.layout");
        }

        stashFile("$asm.unitigs.layout");
    }

    #  Sequences

    foreach my $tt ("unassembled", "contigs") {
        if (! fileExists("$asm.$tt.$type")) {
            fetchFile("unitigging/$asm.ctgStore/seqDB.v002.dat");
            fetchFile("unitigging/$asm.ctgStore/seqDB.v002.tig");

            if (-e "unitigging/$asm.ctgStore/seqDB.v002.tig") {
                $cmd  = "$bin/tgStoreDump \\\n";
                $cmd .= "  -S ./$asm.seqStore \\\n";
                $cmd .= "  -T ./unitigging/$asm.ctgStore 2 \\\n";
                $cmd .= "  -consensus -$type \\\n";
                $cmd .= "  -$tt \\\n";
                $cmd .= "> ./$asm.$tt.$type\n";
                $cmd .= "2> ./$asm.$tt.err";

                if (runCommand(".", $cmd)) {
                    caExit("failed to output $tt consensus sequences", "$asm.$tt.err");
                }

                unlink "$asm.$tt.err";
            } else {
                touch("$asm.$tt.$type");
            }

            stashFile("$asm.$tt.$type");
        }
    }

    if (! fileExists("$asm.unitigs.$type")) {
        fetchFile("unitigging/$asm.utgStore/seqDB.v002.dat");
        fetchFile("unitigging/$asm.utgStore/seqDB.v002.tig");

        if (-e "unitigging/$asm.utgStore/seqDB.v002.tig") {
            $cmd  = "$bin/tgStoreDump \\\n";
            $cmd .= "  -S ./$asm.seqStore \\\n";
            $cmd .= "  -T ./unitigging/$asm.utgStore 2 \\\n";
            $cmd .= "  -consensus -$type \\\n";
            $cmd .= "  -contigs \\\n";
            $cmd .= "> ./$asm.unitigs.$type\n";
            $cmd .= "2> ./$asm.unitigs.err";

            if (runCommand(".", $cmd)) {
                caExit("failed to output unitig consensus sequences", "$asm.unitigs.err");
            }

            unlink "$asm.unitigs.err";
        } else {
            touch("$asm.unitigs.$type");
        }

        stashFile("$asm.unitigs.$type");
    }

    #  Graphs

    if (!fileExists("$asm.contigs.gfa")) {
        fetchFile("unitigging/4-unitigger/$asm.contigs.aligned.gfa");

        if (-e "unitigging/4-unitigger/$asm.contigs.aligned.gfa") {
            copy("unitigging/4-unitigger/$asm.contigs.aligned.gfa", "$asm.contigs.gfa");
        } else {
            touch("$asm.contigs.gfa");
        }

        stashFile("$asm.contigs.gfa");
    }

    if (!fileExists("$asm.unitigs.gfa")) {
        fetchFile("unitigging/4-unitigger/$asm.unitigs.aligned.gfa");

        if (-e "unitigging/4-unitigger/$asm.unitigs.aligned.gfa") {
            copy("unitigging/4-unitigger/$asm.unitigs.aligned.gfa", "$asm.unitigs.gfa");
        } else {
            touch("$asm.unitigs.gfa");
        }

        stashFile("$asm.unitigs.gfa");
    }

    if (!fileExists("$asm.unitigs.bed")) {
        fetchFile("unitigging/4-unitigger/$asm.unitigs.aligned.bed");

        if (-e "unitigging/4-unitigger/$asm.unitigs.aligned.bed") {
            copy("unitigging/4-unitigger/$asm.unitigs.aligned.bed", "$asm.unitigs.bed");
        } else {
        }

        stashFile("$asm.unitigs.bed");
    }

    #  User-supplied termination command.

    if (defined(getGlobal("onSuccess"))) {
        print STDERR "-- Running user-supplied termination command.\n";
        runCommand(getGlobal("onExitDir"), getGlobal("onSuccess") . " $asm");
    }


  finishStage:
    generateReport($asm);
    resetIteration("generateOutputs");

  allDone:
    print STDERR "--\n";
    print STDERR "-- Assembly '", getGlobal("onExitNam"), "' finished in '", getGlobal("onExitDir"), "'.\n";
    print STDERR "--\n";
    print STDERR "-- Summary saved in '$asm.report'.\n";
    print STDERR "--\n";
    print STDERR "-- Sequences saved:\n";
    print STDERR "--   Contigs       -> '$asm.contigs.$type'\n";
    print STDERR "--   Unassembled   -> '$asm.unassembled.$type'\n";
    print STDERR "--   Unitigs       -> '$asm.unitigs.$type'\n";
    print STDERR "--\n";
    print STDERR "-- Read layouts saved:\n";
    print STDERR "--   Contigs       -> '$asm.contigs.layout'.\n";
    print STDERR "--   Unitigs       -> '$asm.unitigs.layout'.\n";
    print STDERR "--\n";
    print STDERR "-- Graphs saved:\n";
    print STDERR "--   Contigs       -> '$asm.contigs.gfa'.\n";
    print STDERR "--   Unitigs       -> '$asm.unitigs.gfa'.\n";
}
