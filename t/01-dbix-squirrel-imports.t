use 5.010_001;
use strict;
use warnings;

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
    use_ok('DBIx::Squirrel', database_entity => 'foo', database_entities => ['bar', 'baz']) || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

ok(defined(&foo),                  'import "database_entity"');
ok(defined(&bar) && defined(&baz), 'import "database_entities"');

done_testing();
