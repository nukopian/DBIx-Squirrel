use diagnostics;
use strict;
use warnings;

package T::Squirrel;

BEGIN {
    require Exporter;
    @T::Squirrel::ISA         = qw/Exporter/;
    %T::Squirrel::EXPORT_TAGS = (
        var => [
            qw/
              $TEST_LIB_DIR
              $TEST_DATA_DIR
              $MOCK_DB_DSN
              $MOCK_DB_USERNAME
              $MOCK_DB_PASSWORD
              @MOCK_DB_CREDENTIALS
              @MOCK_DB_CONNECT_ARGS
              $TEST_DB_DSN
              $TEST_DB_USERNAME
              $TEST_DB_PASSWORD
              $TEST_DB_ATTR
              $TEST_DB_NAME
              @TEST_DB_CREDENTIALS
              @TEST_DB_CONNECT_ARGS
              /
        ],
        func => [
            qw/
              diagdump
              /,
        ],
    );
    $T::Squirrel::EXPORT_TAGS{all} = [@{$T::Squirrel::EXPORT_TAGS{var}}, @{$T::Squirrel::EXPORT_TAGS{func}}];
    @T::Squirrel::EXPORT_OK        = (@{$T::Squirrel::EXPORT_TAGS{all}});
    @T::Squirrel::EXPORT           = (@{$T::Squirrel::EXPORT_TAGS{var}});
}

use Cwd qw/realpath/;
use DBD::Mock;
use Test::More;

# Strawberry Perl 5.010001 on CPANTs Matrix struggles with this:
#
#   Failed test 'use T::Squirrel;'
#   at t/03-connections.t line 11.
#     Tried to use 'T::Squirrel'.
#     Error:  Can't continue after import errors at C:\home\tennis\perl5\lib\perl5/MSWin32-x86-multi-thread/DBD/SQLite/Constants.pm line 41.
# BEGIN failed--compilation aborted at C:/home/tennis/.cpanm/work/1724511125.4876/DBIx-Squirrel-1.3.1/t/lib/T/Squirrel.pm line 41.
# Compilation failed in require at t/03-connections.t line 11.
# BEGIN failed--compilation aborted at t/03-connections.t line 11.
# Bailout called.  Further testing stopped: 
#
# So we'll conditionally import the ':file_open' group
#
BEGIN {
    require DBD::SQLite::Constants;
    @T::Squirrel::sqlite_open_flags = do {
        if (exists($DBD::SQLite::Constants::EXPORT_TAGS{file_open})) {
            DBD::SQLite::Constants->import(':file_open');
            (sqlite_open_flags => &SQLITE_OPEN_READONLY);
        }
        else {
            ();
        }
    };
}

our $TEST_LIB_DIR = do {
    my $module = __PACKAGE__;
    $module =~ s/\::/\//g;
    my $path = __FILE__;
    $path =~ s/\/$module\.pm$//i;
    realpath("$path");
};
our $TEST_DATA_DIR = realpath("$TEST_LIB_DIR/../data");

our($MOCK_DB_DSN, $MOCK_DB_USERNAME, $MOCK_DB_PASSWORD) = ("dbi:Mock:", "", "");
our @MOCK_DB_CREDENTIALS  = ($MOCK_DB_USERNAME, $MOCK_DB_PASSWORD);
our @MOCK_DB_CONNECT_ARGS = ($MOCK_DB_DSN,      @MOCK_DB_CREDENTIALS);

our $TEST_DB_NAME = "$TEST_DATA_DIR/chinook.db";
our($TEST_DB_DSN, $TEST_DB_USERNAME, $TEST_DB_PASSWORD, $TEST_DB_ATTR) = (
    "dbi:SQLite:dbname=$TEST_DB_NAME",
    "",
    "",
    {   AutoCommit                 => !!0,
        PrintError                 => !!0,
        RaiseError                 => !!1,
        sqlite_unicode             => !!1,
        sqlite_see_if_its_a_number => !!1,
        @T::Squirrel::sqlite_open_flags,
    },
);
our @TEST_DB_CREDENTIALS  = ($TEST_DB_USERNAME, $TEST_DB_PASSWORD);
our @TEST_DB_CONNECT_ARGS = ($TEST_DB_DSN, @TEST_DB_CREDENTIALS, $TEST_DB_ATTR);

sub diagdump {diag(explain(@_))}

1;
