use 5.010_001;
use strict;
no strict qw(subs);    ## no critic
use warnings;
use Test::Exception;
use Test::Warnings qw/warning/;
use FindBin        qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
#
# We use Test::More::UTF8 to enable UTF-8 on Test::Builder
# handles (failure_output, todo_output, and output) created
# by Test::More. Requires Test::Simple 1.302210+, and seems
# to eliminate the following error on some CPANTs builds:
#
# > Can't locate object method "e" via package "warnings"
#
use Test::More::UTF8;

BEGIN {
    use_ok( 'DBIx::Squirrel', database_entity => 'db' )
        or print "Bail out!\n";
    use_ok( 'T::Squirrel', qw/:var diagdump/ )
        or print "Bail out!\n";
    use_ok( 'DBIx::Squirrel::Iterator', qw/result result_transform/ )
        or print "Bail out!\n";
}

diag join(
    ', ',
    "Testing DBIx::Squirrel $DBIx::Squirrel::VERSION",
    "Perl $]", "$^X",
);


{
    note('DBIx::Squirrel::Iterator::result_transform');

    my @tests = (
        { line => __LINE__, got => sub { result_transform() },            exp => [] },
        { line => __LINE__, got => sub { result_transform(4) },           exp => [4] },
        { line => __LINE__, got => sub { scalar( result_transform(4) ) }, exp => [1] },
        {
            line => __LINE__, got => sub { scalar( result_transform(4) ); $_ }, exp => [4],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 2 * $_[0] } ], 2 );
            },
            exp => [4],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 2 * $_[0] } => sub { 2 * $_[0] } ], 2 );
            },
            exp => [8],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 4 * $_ } ], 4 );
            },
            exp => [16],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 4 * $_ } => sub { 4 * $_ } ], 4 );
            },
            exp => [64],
        },
    );

    for my $t (@tests) {
        my $got = [ $t->{got}->() ];
        is_deeply( $got, $t->{exp}, sprintf( 'line %2d', $t->{line} ) );
    }
}

##############

{
    note('DBIx::Squirrel::Iterator::ResultClass');

    my @tests = (
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 3 * result } ], 4 );
            },
            exp => [12],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 3 * result } => sub { 3 * result } ], 4 );
            },
            exp => [36],
        },
    );

    for my $t (@tests) {
        my $got = [ $t->{got}->() ];
        is_deeply( $got, $t->{exp}, sprintf( 'line %2d', $t->{line} ) );
    }
}

done_testing();
