#!/usr/bin/env perl
use v5.22;
use warnings;
use strict;
use Data::Dumper;
use Cwd;
my $wd=cwd();

if (!@ARGV) {
    die "$0 path-to-stash-file (probably ../src/stash.pl) optional-output-path (default is ./PostGen\n";
}

my $stash_path = $ARGV[0];
my $output_path = './PostGen';
if (scalar @ARGV == 2) {
	$output_path = $ARGV[1];
}
my $VV=1;

replace_stash($stash_path,$output_path);

sub replace_stash { (my $stash_src, my $output_path)=@_;


    if (not -e $stash_src) {
        die "Could not fine $stash_src\n";    
    }
    if (not -d $output_path) {
    	mkdir $output_path;
    }

    my $stash_ref = do( $stash_src );

    for my $src (keys %{$stash_ref}) {
        my @out_lines=();
        my $src_file= $src;
        if (not -e $src_file) {
        	my $ren_src_file = $src_file;
        	$ren_src_file=~s/\.f95/_host.f95/;
        	print "Could not find source file $src_file, trying with $ren_src_file ... ";
        	if (not -e $ren_src_file) {
        		die "Could not find renamed source file $ren_src_file either, giving up.\n";
        		} else {
        			print "OK!\n";
        		}
            $src_file=$ren_src_file;
        }
#        say $src_file;
        open my $IN, '<', $src_file or die $!;

        while (my $line = <$IN>) {
            chomp $line;
            #           say $line;
            if ($line=~/^\!?\s+(\d+)\s+continue/) {
                my $tag=$1;
                if (exists $stash_ref->{$src}{$tag} ) {
                    for my $stashed_line (@{  $stash_ref->{$src}{$tag} }) {
                        push @out_lines, $stashed_line;
                    }
                } else {
                    push @out_lines, $line;
                }
            } else {
                push @out_lines, $line;
            }
        }
        close $IN;
        open my $OUT, '>', 'PostGen/'.$src_file or die $!;
        map {say $OUT $_} @out_lines;
        close $OUT;
    }
}


#map {say $_ } @{  $ref->{'main.f95'}{7188} };


