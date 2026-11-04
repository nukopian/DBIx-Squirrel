use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;
use DBIx::Squirrel::Errors qw(at_caller failed in_method);

# A database handle, with RaiseError on unless told otherwise, and a table
# with a row, for a second to break its key.
sub dbh (%attrs) {
    my $class = delete $attrs{class} // 'DBIx::Squirrel';
    my $dbh   = $class->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0, %attrs},
    );
    $dbh->do('CREATE TABLE u (id INTEGER PRIMARY KEY)') if $attrs{RaiseError} // 1;
    $dbh->do('INSERT INTO u VALUES (1)')                if $attrs{RaiseError} // 1;
    return $dbh;
}

# Matches an error reported at a line of this file.
sub at_line ($line) {
    return qr( \ at\ \Q${\ __FILE__ }\E\ line\ $line \. \n \z )x;
}

subtest 'the DBI raises errors at the caller' => sub {
    my $dbh = dbh();
    my $line;

    $line = __LINE__ + 1;
    my $err = dies { $dbh->prepare('SELEC 1') };
    like $err, qr( \A DBD::SQLite::db\ prepare\ failed: )x,
        "prepare, with the DBI's message";
    like $err, at_line($line), 'at the caller';

    $line = __LINE__ + 1;
    like dies { $dbh->prepare_cached('SELEC 2') }, at_line($line),
        'prepare_cached';

    my $sth = $dbh->prepare('INSERT INTO u VALUES (?)');
    $line = __LINE__ + 1;
    like dies { $sth->execute(1) }, at_line($line), 'execute';

    $sth  = $dbh->prepare('INSERT INTO u VALUES (:id)');
    $line = __LINE__ + 1;
    like dies { $sth->execute(id => 1) }, at_line($line),
        'execute, binding by name';

    $line = __LINE__ + 1;
    like dies { $dbh->do('INSERT INTO u VALUES ($1)', undef, 1) },
        at_line($line),
        'do';

    $line = __LINE__ + 1;
    like dies { $dbh->selectrow_array('SELECT * FROM nope') }, at_line($line),
        'selectrow_array';

    my $sql = 'SELECT * FROM nope WHERE id = :id';
    $line = __LINE__ + 1;
    $err  = dies { $dbh->selectall_arrayref($sql, undef, id => 1) };
    like $err, at_line($line), 'selectall_arrayref, binding by name';
};

subtest 'so does DBIx::Squirrel, without RaiseError' => sub {
    my $dbh  = dbh(RaiseError => 0);
    my $line = __LINE__ + 1;
    like dies { $dbh->prepare_cached('SELEC 2') }, at_line($line),
        "prepare_cached, which the DBI's prepare_cached calls prepare for";
};

# The message an error is raised with, without its location.
sub message ($error) {
    return $error =~ s( \ at \ \S+ \ line \ \d+ \. \n \z )()xr;
}

subtest "the DBI's messages, as plain DBI raises them" => sub {
    my $dbi = dbh(class => 'DBI');
    my $sq  = dbh();
    for my $call (
        [prepare            => 'SELEC 1'],
        [prepare_cached     => 'SELEC 1'],
        [do                 => 'SELEC 1'],
        [do                 => 'INSERT INTO u VALUES (?)', undef, 1],
        [selectrow_array    => 'SELEC 1'],
        [selectrow_arrayref => 'SELEC 1'],
        [selectrow_hashref  => 'SELEC 1'],
        [selectall_arrayref => 'SELEC 1'],
        [selectall_hashref  => 'SELEC 1', 'id'],
        [selectcol_arrayref => 'SELEC 1'],
        [selectall_arrayref => 'SELECT * FROM u WHERE id = ?', undef, 1, 2],
    ) {
        my($method, @args) = @$call;
        my $want = message(dies { $dbi->$method(@args) });
        is message(dies { $sq->$method(@args) }), $want, "$method: $want";
    }

    my $sth = $sq->prepare('INSERT INTO u VALUES (:id)');
    my $want
        = message(dies { $dbi->prepare('INSERT INTO u VALUES (?)')->execute(1) });
    is message(dies { $sth->execute(id => 1) }), $want,
        "execute, binding by name: $want";
};

subtest 'and when DBIx::Squirrel raises them, without RaiseError' => sub {
    my $raise = dbh();
    my $quiet = dbh(RaiseError => 0);
    for my $method (qw(prepare prepare_cached)) {
        my $want = message(dies { $raise->$method('SELEC 1') });
        is message(dies { $quiet->$method('SELEC 1') }), $want, $method;
    }

    # The message connect fails with, to a database it can't open.
    my sub connect_error ($raise) {
        my $source = 'dbi:SQLite:dbname=/nonexistent/x.db';
        my $attrs  = {RaiseError => $raise, PrintError => 0};
        return message(dies { DBIx::Squirrel->connect($source, 'me', '', $attrs) });
    }
    my $want   = connect_error(1);
    my $prefix = q(DBIx::Squirrel connect('dbname=/nonexistent/x.db','me',...));
    like $want, qr( \A \Q$prefix\E \ failed: )x,
        'connect, whose message the DBI raises';
    is connect_error(0), $want, 'is raised by DBIx::Squirrel the same';
};

subtest 'failed' => sub {
    my $dbh = dbh(RaiseError => 0);
    $dbh->prepare('SELECT 1')->execute;
    $dbh->set_err(1, 'oops');
    is failed($dbh, 'frob'), 'DBD::SQLite::db frob failed: oops',
        "gives the DBI's message";
};

subtest 'in_method' => sub {
    my $dbh = dbh();
    is [in_method $dbh, 'do', sub { (1, 2, 3) }], [1, 2, 3],
        'returns what the code returns';

    # What in_method raises, given code dying with the error.
    my sub raised ($error) {
        my $code = sub { die $error };    ## no critic (ErrorHandling::RequireCarping)
        return dies { in_method $dbh, 'do', $code };
    }
    is raised("DBD::SQLite::st execute failed: x\n"),
        "DBD::SQLite::db do failed: x\n", "renames the DBI's method";
    is raised("Something failed: x\n"), "Something failed: x\n",
        'and leaves other errors alone';
    my $object = bless {}, 'My::Error';
    ref_is raised($object), $object, 'objects too';
};

subtest 'other errors are raised as they were' => sub {
    my $handled = dbh(HandleError => sub { die "handled\n" });    ## no critic (ErrorHandling::RequireCarping)
    is dies { $handled->prepare('SELEC 1') }, "handled\n",
        'a string from HandleError';

    my $object = bless {}, 'My::Error';
    my $thrown = dbh(HandleError => sub { die $object });         ## no critic (ErrorHandling::RequireCarping)
    ref_is dies { $thrown->prepare('SELEC 1') }, $object, 'an object';
};

subtest 'at_caller' => sub {
    is [at_caller { (1, 2, 3) }],       [1, 2, 3], 'returns a list in list context';
    is scalar(at_caller { (1, 2, 3) }), 3,         'and a scalar in scalar context';

    my $err = dies {
        at_caller { die "elsewhere\n" }    ## no critic (ErrorHandling::RequireCarping)
    };
    is $err, "elsewhere\n", 'leaves an error not located in the file';
};

done_testing;
