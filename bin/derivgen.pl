#!/bin/perl -W

###########################################
## derivgen.pl
##
## Written: David_Harris@hmc.edu 
## Created: 29 January 2024
## Modified: 
##
## Purpose: Read config/derivlist.txt and generate config/deriv/*/config.vh
##          derivative configurations from the base configurations
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
## except in compliance with the License, or, at your option, the Apache License version 2.0. You 
## may obtain a copy of the License at
##
## https:##solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the 
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
## either express or implied. See the License for the specific language governing permissions 
## and limitations under the License.
################################################################################################


use strict;
use warnings;
import os;
use Data::Dumper;

my $curderiv = "";
my @derivlist = ();
my %derivs;
my %basederiv;

if ($#ARGV != -1) {
    die("Usage: $0")
}
my $derivlist = "$ENV{WALLY}/config/derivlist.txt";
open(my $fh, $derivlist) or die "Could not open file '$derivlist' $!";
foreach my $line (<$fh>) {
    chomp $line;
    my @tokens = split('\s+', $line);
    if ($#tokens < 0 || $tokens[0] =~ /^#/) {   # skip blank lines and comments
        next;
    }
    if ($tokens[0] =~ /deriv/) {   # start of a new derivative
        &terminateDeriv();
        $curderiv = $tokens[1];
        $basederiv{$curderiv} = $tokens[2];
        @derivlist = ();
        if ($#tokens > 2) {
            my $inherits = $derivs{$tokens[3]};
            @derivlist = @{$inherits};
        }
    } else {   # add to the current derivative
        $line =~ /\s*(\S+)\s*(.*)/;
        my @entry = ($1, $2);
        push(@derivlist, \@entry);
    }
}
&terminateDeriv();
close($fh);
foreach my $key (keys %derivs) {
    my $dir = "$ENV{WALLY}/config/deriv/$key";
    system("rm -rf $dir");
    system("mkdir -p $dir");
    my $configunmod = "$dir/config_unmod.vh";
    my $config = "$dir/config.vh";
    my $base = "$ENV{WALLY}/config/$basederiv{$key}/config.vh";
    system("cp $base $configunmod");
    open(my $unmod, $configunmod) or die "Could not open file '$configunmod' $!";
    open(my $fh, '>>', $config) or die "Could not open file '$config' $!";

    my $datestring = localtime();
    my %hit = ();
    print $fh "// Config $key automatically derived from $basederiv{$key} on $datestring usubg derivgen.pl\n";
    foreach my $line (<$unmod>) {
        foreach my $entry (@{$derivs{$key}}) {    
            my @ent = @{$entry};
            my $param = $ent[0];
            my $value = $ent[1]; 
            if ($line =~ s/$param\s*=\s*.*;/$param = $value;/) {
                $hit{$param} = 1;
#               print("Hit: new line in $config for $param is $line");
            }
        }
        print $fh $line;
    }
    close($fh);
    close($unmod);
    foreach my $entry (@{$derivs{$key}}) {
        my @ent = @{$entry};
        my $param = $ent[0];
        if (!exists($hit{$param})) {
            print("Unable to find $param in $key\n");
        }
    }
    system("rm -f $dir/config_unmod.vh");
}

sub terminateDeriv {
    if ($curderiv ne "") { # close out the previous derivative
        my @dl = @derivlist;
        $derivs{$curderiv} = \@dl;
    }
};

sub printref {
    my $ref = shift;
    my @array = @{$ref};
    foreach my $entry (@array) {
        print join('_', @{$entry}), ', ';
    }
    print("\n");
}