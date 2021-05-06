
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
 #  Modifications by:
 #
 #    Brian P. Walenz beginning on 2015-NOV-27
 #      are a 'United States Government Work', and
 #      are released in the public domain
 #
 #    Sergey Koren beginning on 2016-JUN-20
 #      are a 'United States Government Work', and
 #      are released in the public domain
 #
 #  File 'README.licenses' in the root directory of this distribution contains
 #  full conditions and disclaimers for each license.
 ##

package canu::Grid;

require Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw(formatAllowedResources configureRemote);

use strict;
use warnings "all";
no  warnings "uninitialized";

use canu::Defaults;


#
#  Given a map of "cpu-mem" to number-of-nodes, write a log message, and return a string for use
#  later in the pipeline.
#
sub formatAllowedResources (\%$) {
    my $hosts_ref = shift @_;
    my $geName    = shift @_;
    my %hosts     = %$hosts_ref;
    my $hosts     = undef;

    print STDERR "-- \n";

    foreach my $c (keys %hosts) {
        my ($cpus, $mem) = split '-', $c;
        my  $nodes       = $hosts{$c};

        printf(STDERR "-- Found %3d host%s with %3d core%s and %4d GB memory under $geName control.\n",
               $nodes, ($nodes == 1) ? " " : "s",
               $cpus,  ($cpus  == 1) ? " " : "s",
               $mem);

        $hosts .= "\0"                  if (defined($hosts));
        $hosts .= "$cpus-$mem-$nodes";
    }

    return $hosts;
}


sub configureRemote () {

    if ((getGlobal("useGrid") eq "remote") &&
        (getGlobal("gridEngine") eq "")) {
        caExit("invalid 'useGrid=remote' specified; no gridEngine available", undef);
    }

    return   if (uc(getGlobal("gridEngine")) ne "");

    #  If here, gridEngine is not set, and we're running locally.
    #  Set to a variable we don't expect to see in the environment.
    setGlobalIfUndef("gridEngineTaskID", "CANU_LOCAL_JOB_ID");
}
