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

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
