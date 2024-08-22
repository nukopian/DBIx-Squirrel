use Modern::Perl;
use open ':std', ':encoding(utf8)';
use Carp qw/croak/;
use Test::More;
use Test::Warn;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    use_ok('DBIx::Squirrel', database_entities => [qw/db artist artists/]) || print "Bail out!\n";
    use_ok('T::Squirrel')                                                  || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

sub foo {$_[0]}

subtest 'basic checks' => sub {
    db(DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS));
    artist(db->iterate('SELECT * FROM artists WHERE ArtistId=? LIMIT 1'));
    artists(db->iterate('SELECT * FROM artists ORDER BY ArtistId LIMIT 5'));
    my $artist  = artist->_private;
    my $artists = artists->_private;

    is_deeply($artist->{init_bind_values}, [], 'init_bind_values ok');
    ok(!exists($artist->{bind_values}), 'bind_values ok');
    is_deeply($artist->{init_transforms}, [], 'init_transforms ok');
    ok(!exists($artist->{transforms}), 'transforms ok');

    artist->iterate(128);
    is_deeply($artist->{init_bind_values}, [],                         'init_bind_values ok');
    is_deeply($artist->{bind_values},      [128],                      'bind_values ok');
    is_deeply($artist->{init_transforms},  [],                         'init_transforms ok');
    is_deeply($artist->{transforms},       $artist->{init_transforms}, 'transforms ok');

    artist->iterate(128, \&foo)->next;
    is_deeply($artist->{init_bind_values}, [],      'init_bind_values ok');
    is_deeply($artist->{bind_values},      [128],   'bind_values ok');
    is_deeply($artist->{init_transforms},  [],      'init_transforms ok');
    is_deeply($artist->{transforms},       [\&foo], 'transforms ok');

    artists->slice([])->iterate(\&foo)->all;
};

done_testing();
