use 5.010;
use strict;
use warnings;
use FindBin;

use File::chdir;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run_forked);
use Test::More 0.98;

my ($tmpdir) = tempdir(CLEANUP => 1);
$CWD = $tmpdir;

sub lines { join("", map {"$_\n"} @_) }

subtest "no options" => sub {
    test_nauniq(
        args   => [qw//],
        input  => lines(1, 2, 3),
        output => lines(1, 2, 3),
    );
    test_nauniq(
        args   => [qw//],
        input  => lines(1, 2, 3, 3, 2, 4),
        output => lines(1, 2, 3, 4),
    );
};

# XXX test --repeated -d
# XXX test --ignore-case -i
# XXX test --num-entries
# XXX test --skip-chars -s
# XXX test --unique -u
# XXX test --check-chars -w
# XXX test --forget-pattern
# XXX test --append
# XXX test -a
# XXX test --md5
# XXX test --read-output

DONE_TESTING:
done_testing;
if (Test::More->builder->is_passing) {
    diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}

sub test_nauniq {
    my %args = @_;

    my @progargs = @{ $args{args} // [] };
    my $name = $args{name} // join(" ", @progargs);
    subtest $name => sub {
        my $expected_exit = $args{exitcode} // 0;
        my %runopts;
        $runopts{child_stdin} = $args{input} if defined $args{input};
        my $res = run_forked(
            join(" ", $^X, "$FindBin::Bin/../bin/nauniq", "--", @progargs),
            \%runopts);

        is($res->{exit_code}, $expected_exit,
           "exit code = $expected_exit") or do {
               if ($expected_exit == 0) {
                   diag explain $res;
               }
           };

        if (defined $args{output}) {
            is($res->{stdout}, $args{output}, "output");
        }
    };
}
