#!perl
use Modern::Perl;
use Carp qw/croak/;
use Data::Dumper::Concise;
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel', database_entity => 'db', database_entities => [qw/st itor results/]) || print "Bail out!\n";
    use_ok('Test::DBIx::Squirrel')                                                                || print "Bail out!\n";
}

# Helpers are accessible to the entire module and we will take full
# advantage of that in this test module.

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

subtest 'associate "db" helper with database connection' => sub {
    my $dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS)
      or croak "Cannot create handle: $DBIx::Squirrel::errstr";
    db($dbh);
    isa_ok(db, 'DBIx::Squirrel::db');
    is(db, $dbh);
    db->{mock_add_resultset} = [['ArtistId', 'Name'], [1, 'The Foo Fighters'], [2, 'The Foo-Tan Clan'], [3, 'The Foogies']];
};

subtest 'resolve "db" helper; associate "st" helper with statement' => sub {
    my $sth = db->prepare('SELECT * FROM artists');
    st($sth);
    isa_ok(st, 'DBIx::Squirrel::st');
    is(st,                   $sth);
    is(st->{mock_statement}, 'SELECT * FROM artists');
};

subtest 'resolve "st" helper; run basic statement checks' => sub {
    my $rv = st->execute();
    is($rv, '0E0');
    is_deeply(st->{mock_params},       []);
    is_deeply(st->fetchall_arrayref(), [[1, 'The Foo Fighters'], [2, 'The Foo-Tan Clan'], [3, 'The Foogies']]);
};

subtest 'address "st" helper; run basic statement checks' => sub {
    st([]);    # Statement takes no parameters; must coerce re-execution by passing []!
    is_deeply(
        st->fetchall_arrayref({}),
        [   {ArtistId => 1, Name => 'The Foo Fighters'},
            {ArtistId => 2, Name => 'The Foo-Tan Clan'},
            {ArtistId => 3, Name => 'The Foogies'},
        ],
    );
};

subtest 'resolve "st" helper; associate "itor" helper with basic iterator' => sub {
    db->{mock_add_resultset} = [['ArtistId', 'Name'], [1, 'The Foo Fighters'], [2, 'The Foo-Tan Clan'], [3, 'The Foogies']];
    my $itor = db->prepare('SELECT * FROM artists')->iterate();
    itor($itor);
    isa_ok($itor, 'DBIx::Squirrel::it');
    is(itor, $itor);
    is(itor->count(), 3);
    is_deeply(itor->first(), [1, 'The Foo Fighters']);
    is_deeply(itor->next(),  [2, 'The Foo-Tan Clan']);
    is_deeply(itor->next(),  [3, 'The Foogies']);
    is(itor->count(), 3);
};

subtest 'resolve "st" helper; associate "results" helper with result-set iterator' => sub {
    db->{mock_add_resultset} = [['ArtistId', 'Name'], [1, 'The Foo Fighters'], [2, 'The Foo-Tan Clan'], [3, 'The Foogies']];
    my $itor = db->prepare('SELECT * FROM artists')->results();
    results($itor);
    isa_ok($itor, 'DBIx::Squirrel::rs');
    is(results, $itor);
    is(results->count(), 3);
    is_deeply(results->first(), [1, 'The Foo Fighters']);
    is_deeply(results->next(),  [2, 'The Foo-Tan Clan']);
    is_deeply(results->next(),  [3, 'The Foogies']);
    is(results->count(), 3);
};

done_testing();
