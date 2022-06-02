package App::nauniq;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

sub run {
    my %opts = @_;

    my $ifh; # input handle
    if (@ARGV) {
        my $fname = shift @ARGV;
        if ($fname eq '-') {
            $ifh = *STDIN;
        } else {
            open $ifh, "<", $fname or die "Can't open input file $fname: $!\n";
        }
    } else {
        $ifh = *STDIN;
    }

    my $phase = 2;
    my $ofh; # output handle
    if (@ARGV) {
        my $fname = shift @ARGV;
        if ($fname eq '-') {
            $ofh = *STDOUT;
        } else {
            open $ofh,
                ($opts{read_output} ? "+" : "") . ($opts{append} ? ">>" : ">"),
                    $fname
                or die "Can't open output file $fname: $!\n";
            if ($opts{read_output}) {
                seek $ofh, 0, 0;
                $phase = 1;
            }
        }
    } else {
        $ofh = *STDOUT;
    }

    my ($line, $memkey);
    my %mem;
    my $sub_reset_mem = sub {
        if ($opts{num_entries} > 0) {
            require Tie::Cache;
            tie %mem, 'Tie::Cache', $opts{num_entries};
        } else {
            %mem = ();
        }
    };
    $sub_reset_mem->();
    require Digest::MD5 if $opts{md5};
    no warnings; # we want to shut up 'substr outside of string'
    while (1) {
        if ($phase == 1) {
            # phase 1 is just reading the output file
            $line = <$ofh>;
            if (!$line) {
                $phase = 2;
                next;
            }
        } else {
            $line = <$ifh>;
            if (!$line) {
                last;
            }
        }
        if ($opts{forget_pattern} && $line =~ $opts{forget_pattern}) {
            $sub_reset_mem->();
        }

        $memkey = $opts{check_chars} > 0 ?
            substr($line, $opts{skip_chars}, $opts{check_chars}) :
                substr($line, $opts{skip_chars});
        $memkey = lc($memkey) if $opts{ignore_case};
        $memkey = Digest::MD5::md5($memkey) if $opts{md5};

        if ($phase == 2) {
            if ($mem{$memkey}) {
                print $ofh $line if $opts{show_repeated};
            } else {
                print $ofh $line if $opts{show_unique};
            }
        }

        $mem{$memkey} = 1;
    }
}


1;
# ABSTRACT: Non-adjacent uniq

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

See the command-line script L<nauniq>.

=cut
