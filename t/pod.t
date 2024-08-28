#!perl
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

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
