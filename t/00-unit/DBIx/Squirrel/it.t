BEGIN {
    delete $INC{'FindBin.pm'};
    require FindBin;
}

use autobox::Core;
use Test::Most;
use Capture::Tiny 'capture_stdout', 'capture_stderr', 'capture';
use Cwd 'realpath';
use DBIx::Squirrel::util ':all';
use DBIx::Squirrel;

use lib realpath("$FindBin::Bin/../lib");
use T::Database ':all';

our (
    $sql,     $res,        $got,    @got,    $exp,      @exp,
    $row,     $it,         $stdout, $stderr, @hashrefs, @arrayrefs,
    $dbi_dbh, $cached_dbh, $dbh,    $sth,    @a,        $aref,
    %h,       $href
);

ok 1, __FILE__ . ' complete';
done_testing;
