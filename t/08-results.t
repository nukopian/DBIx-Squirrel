use 5.010_001;
use strict;
use warnings;
use Carp qw/croak/;
use Test::Warn;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

# The following lifted from PPIx::Regexp as a possible fix
# for strange error on some Strawbery Perl builds:
#
#   Can't locate object method "e" via package "warnings" 
#
# Thanks to TWATA for the steer!
use constant SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS => $] ge '5.008003';

BEGIN {
    # NOTE that this MUST be done before Test::More is loaded.
    if ( SUFFICIENT_UTF8_SUPPORT_FOR_WEIRD_DELIMITERS ) {
	    require 'open.pm';
	    'open'->import( qw/:std :encoding(utf-8)/ );
    }
}

use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel', database_entities => [qw/db artist artists/]) || print "Bail out!\n";
    use_ok('T::Squirrel',    qw/:var diagdump/)                            || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

# Filter out artists whose ArtistId is outside the 128...131 range.
sub filter {($_->ArtistId < 128 or $_->ArtistId > 131) ? () : $_}

# Inject some additional (pending) results for the artist whose ArtistId is 128,
# else just return the artist's Name-field.
sub artist_name {($_->ArtistId == 128) ? ($_->Name, 'Envy of None', 'Alex Lifeson') : $_->[1]}

db(DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS));
artist(db->results('SELECT * FROM artists WHERE ArtistId=? LIMIT 1'));
my $artist = artist->_private_state;

artists(db->results('SELECT * FROM artists ORDER BY ArtistId' => \&filter => \&artist_name));
my $artists = artists->_private_state;

# This test will exercise buffer control, transformations, pending results injection and
# results filtering.
my $results  = artists->all;
my $expected = ['Rush', 'Envy of None', 'Alex Lifeson', 'Simply Red', 'Skank', 'Smashing Pumpkins'];
is_deeply($results, $expected, 'iteration, filtering, injection ok');
is($artists->{cache_size_fixed}, !!0,                                          'artists->{cache_size_fixed}');
is($artists->{cache_size},       &DBIx::Squirrel::Iterator::CACHE_SIZE_LIMIT, 'artists->{cache_size}');

artists->cache_size(8)->execute;
$results = artists->all;
is_deeply($results, $expected, 'iteration, filtering, injection ok');
is($artists->{cache_size_fixed}, !!1, 'artists->{cache_size_fixed}');
is($artists->{cache_size},       8,   'artists->{cache_size}');

done_testing();
