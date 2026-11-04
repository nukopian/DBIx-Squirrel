use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;
use DBIx::Squirrel::Stop;
use DBIx::Squirrel::Context qw(iterator result_number result_original);
use Scalar::Util            qw(weaken);

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

# A handle of each kind, with ten artists.
my %h = (
    dbi      => DBI->connect(@source),
    squirrel => DBIx::Squirrel->connect(@source),
);
for my $h (values %h) {
    $h->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
    $h->do('INSERT INTO artist (name) VALUES (?)', undef, $_)
        for qw(Abba Blur Cream Dido Enya Faust Genesis Hole Inxs Japan);
}
my $dbh = $h{squirrel};
my $all = 'SELECT id, name FROM artist ORDER BY id';

# Every result an iterator hands out, read with next.
sub drain ($it) {
    my @results;
    while (my($result) = $it->next) { push @results, $result }
    return \@results;
}

subtest 'the rows are those the DBI fetches' => sub {
    is drain($dbh->iterate($all)), $h{dbi}->selectall_arrayref($all),
        'as arrays';
    is drain($dbh->iterate($all, {ekorn_slice => {}})),
        $h{dbi}->selectall_arrayref($all, {Slice => {}}), 'as hashes';
    is drain($dbh->iterate('SELECT id FROM artist WHERE 0')), [], 'none';
};

subtest 'bind values, in any placeholder style' => sub {
    my $sql  = 'SELECT name FROM artist WHERE id IN (%s) ORDER BY id';
    my @want = (['Abba'], ['Cream']);
    is drain($dbh->iterate(sprintf($sql, '?, ?'), 1, 3)), \@want, '?';
    is drain($dbh->iterate(sprintf($sql, '$1, $2'), [1, 3])), \@want,
        'numbered, in an array reference';
    is drain($dbh->iterate(sprintf($sql, ':a, :b'), a => 1, b => 3)), \@want,
        'named';
    is drain($dbh->iterate(sprintf($sql, ':a, :b'), undef, {a => 1, b => 3})),
        \@want, 'named, in a hash reference after the attributes';
    is drain($dbh->iterate(sprintf($sql, '?, ?'), {}, 1, 3)), \@want,
        'with attributes';
    my $sth = $dbh->prepare(sprintf($sql, ':a, :b'));
    is drain($sth->iterate(a => 1, b => 3)), \@want, 'on a statement handle';
};

subtest 'the stages' => sub {
    my $names = "$all LIMIT 4";
    is drain($dbh->iterate($names, sub ($row) { $row->[1] })),
        [qw(Abba Blur Cream Dido)], 'change a row';
    is drain($dbh->iterate(
        $names, sub ($row) { $row->[0] % 2 ? $row : () },
        sub { $_->[1] },
        )),
        [qw(Abba Cream)], 'drop one';
    is drain($dbh->iterate($names, sub ($row) { ($row->[1]) x $row->[0] })),
        [qw(Abba Blur Blur Cream Cream Cream Dido Dido Dido Dido)],
        'return several';
    is drain($dbh->iterate(
        $all,
        sub ($row) {
            $row->[0] == 3 ? Stop($row->[1]) : $row->[1];
        },
        )),
        [qw(Abba Blur Cream)], 'stop';
    is drain($dbh->iterate("$all LIMIT 2", sub { undef })), [undef, undef],
        'and undef is a result';
    is drain($dbh->iterate(
        'SELECT id FROM artist WHERE id = ?', 2, sub { 'x' },)),
        ['x'], 'after bind values';
};

subtest 'next' => sub {
    my $it = $dbh->iterate("$all LIMIT 1", sub { $_->[1] });
    is $it->next,   'Abba', 'returns the next result';
    is [$it->next], [],     'and nothing at the end';
    is [$it->next], [],     'and after';
    ok !$it->sth->{Active}, 'with the statement finished';
};

subtest 'all and count' => sub {
    my $it = $dbh->iterate($all, sub { $_->[1] });
    is $it->count, 0,      'count, before any';
    is $it->next,  'Abba', 'one';
    is $it->count, 1,      'count, after it';
    is [$it->all], [qw(Blur Cream Dido Enya Faust Genesis Hole Inxs Japan)],
        'all, the rest';
    is $it->count,  10, 'count, after them';
    is [$it->all],  [], 'all, with none left';
    is [$it->next], [], 'and next';

    $it = $dbh->iterate($all);
    is scalar($it->all), 10, 'all, in scalar context, counts them';
};

subtest 'single' => sub {
    my $sql = 'SELECT name FROM artist WHERE id = ?';
    my $it  = $dbh->iterate($sql, 3, sub { $_->[0] });
    is $it->single, 'Cream', 'the one result';
    is $it->single, 'Cream', 'again, executing the statement again';
    is [$dbh->iterate($sql, 99)->single], [], 'or nothing';
    my $expected = qr( \A Expected\ one\ result,\ not\ more )x;
    my $line     = __LINE__ + 1;
    like dies { $dbh->iterate($all)->single },
        qr( $expected \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'croaks at the caller on more than one';
};

subtest 'reset' => sub {
    my $it = $dbh->iterate(
        'SELECT name FROM artist WHERE id <= ?', 2,
        sub { $_->[0] },
    );
    is drain($it),           [qw(Abba Blur)],       'the bind values given';
    is drain($it->reset(3)), [qw(Abba Blur Cream)], 'others';
    is drain($it->reset),    [qw(Abba Blur Cream)], 'kept';
    is drain($it->reset(1, sub { lc })), ['abba'],  'and stages, added';
    is drain($it->reset(1)),             ['abba'],  'and kept';

    $it = $dbh->iterate($all, sub { $_->[1] });
    is $it->next, 'Abba', 'one fetched';
    ref_is $it->reset, $it, 'reset returns the iterator';
    is $it->next, 'Abba', 'starting again, finishing the statement';
};

subtest '$_ is left alone' => sub {
    my $it    = $dbh->iterate($all, sub { $_->[1] });
    my @names = qw(x y);
    for (@names) { $it->next }
    is \@names, [qw(x y)], "a for loop's aliases";
    my @mapped = grep { $it->next } qw(a b);
    is \@mapped, [qw(a b)], "and grep's";
    local $_ = 'kept';
    $it->reset;
    $it->all;
    is $_, 'kept', 'by reset and all';
    $dbh->iterate('SELECT 1', sub { $_ })->single;
    is $_, 'kept', 'and single';
};

subtest 'ekorn_slice' => sub {
    my $hashes = $h{dbi}->selectall_arrayref($all, {Slice => {}});
    my $sth    = $dbh->prepare($all, {ekorn_slice => {}});
    is drain($sth->iterate), $hashes, 'on prepare';
    my $other = DBIx::Squirrel->connect(
        @source[0 .. 2],
        {%{ $source[3] }, ekorn_slice => {}},
    );
    $other->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
    $other->do(q{INSERT INTO artist (name) VALUES ('Abba'), ('Blur')});
    is drain($other->iterate($all)),
        [{id => 1, name => 'Abba'}, {id => 2, name => 'Blur'}],
        'or on connect';
    is drain($other->iterate($all, {ekorn_slice => []})),
        [[1, 'Abba'], [2, 'Blur']],
        'which prepare overrides';
    is drain(
        $dbh->iterate('SELECT id FROM artist WHERE id <= 2', {ekorn_slice => [0]})),
        [[1], [2]], 'a slice of columns';
    my $expected = 'Expected ekorn_slice to be a reference to an ARRAY or HASH';
    like dies { $dbh->iterate($all, {ekorn_slice => 'x'}) },
        qr( \A \Q$expected\E )x, 'croaks on anything else';
};

subtest 'one iterator at a time on a statement handle' => sub {
    my $sth = $dbh->prepare($all);
    my $one = $sth->iterate;
    my $two = $sth->iterate;
    $one->next;
    my $expected
        = q(Expected the statement handle's other iterator to be finished);
    my $line = __LINE__ + 1;
    like dies { $two->next },
        qr( \A \Q$expected\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'croaks while another has results left';
    is scalar($one->all), 9, 'and that one is unharmed';
    ok lives { $two->next },        'once it ends';
    ok lives { $two->reset->next }, 'and the one going can reset itself';
    undef $two;
    ok lives { $sth->iterate->next }, 'or once the other goes';
    my $single = $sth->iterate(sub { $_->[1] });
    ok dies { $single->single },      'single, with more than one result';
    ok lives { $sth->iterate->next }, 'is finished, either way';
};

subtest 'what a stage can ask' => sub {
    my $it = $dbh->iterate(
        "$all LIMIT 4",
        sub ($row) { $row->[0] == 2 ? () : $row },
        sub ($row) {
            return {
                iterator => iterator,
                number   => result_number,
                original => result_original,
            };
        },
    );
    my $results = drain($it);
    is $results->[0]{iterator}, exact_ref($it), 'iterator';
    is [map { $_->{number} } @$results], [1, 2, 3],
        'result_number, counting results, not rows';
    is [map { $_->{original}[1] } @$results], [qw(Abba Cream Dido)],
        'result_original';
    is result_number, undef, 'and nothing outside a stage';
};

subtest 'errors are reported at the caller' => sub {
    my $it   = $dbh->iterate($all, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line = __LINE__ + 1;
    is dies { $it->next },
        "Pipeline stage #1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'from a stage';
    $it = $dbh->iterate('SELECT name FROM artist WHERE id = :id', x => 1);
    my $expected
        = qr( \A Expected\ a\ placeholder\ of\ the\ statement\ \(x\) )x;
    $line = __LINE__ + 1;
    like dies { $it->next },
        qr( $expected \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'from binding';
    like dies { DBIx::Squirrel::Iterator->new('x') },
        qr( \A Expected\ a\ statement\ handle )x, 'from new';
};

subtest 'a statement without rows' => sub {
    my $it = $dbh->iterate('UPDATE artist SET name = name WHERE id <= ?', 2);
    is drain($it),     [], 'has no results';
    is $it->sth->rows, 2,  'and the handle says how many rows it changed';
};

subtest 'an iterator is freed' => sub {
    my $it = $dbh->iterate($all);
    $it->next;
    weaken(my $weak = $it);
    undef $it;
    is $weak, undef, 'when it goes out of scope';
};

done_testing;
