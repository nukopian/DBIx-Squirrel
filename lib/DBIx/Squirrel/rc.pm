
package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::rc;
use strict;
use warnings;
use constant E_BAD_OBJECT     => 'A reference to either an array or hash was expected';
use constant E_STH_EXPIRED    => 'Result is no longer associated with a statement';
use constant E_UNKNOWN_COLUMN => 'Unrecognised column (%s)';

BEGIN {
    require DBIx::Squirrel
      unless defined $DBIx::Squirrel::VERSION;
}

use namespace::autoclean;
use Sub::Name 'subname';
use DBIx::Squirrel::util 'throw';

our $AUTOLOAD;

BEGIN {
    *row_base_class = *result_class = sub { shift->rs->result_class; }
}

sub row_class {
    return shift->rs->row_class;
}

sub get_column {
    return undef unless defined $_[1];

    if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
        if ( my $sth = $_[0]->rs->sth ) {
            my $idx = $sth->{NAME_lc_hash}{ lc $_[1] };
            throw E_UNKNOWN_COLUMN, $_[1] unless defined $idx;
            return $_[0]->[$idx];
        }

        throw E_STH_EXPIRED;
    } else {
        throw E_BAD_OBJECT
          unless UNIVERSAL::isa( $_[0], 'HASH' );

        return $_[0]{ $_[1] } if exists $_[0]{ $_[1] };

        my ($idx) = do {
            local ($_);

            grep { $_[1] eq lc $_ } keys %{ $_[0] };
        };

        throw E_UNKNOWN_COLUMN, $_[1] unless defined $idx;

        return $_[0]->{$idx};
    }
}

sub new {
    return bless( $_[1], ref $_[0] || $_[0] );
}

# AUTOLOAD is called whenever a row object attempts invoke an unknown
# method. This implementation will try to create an accessor which is then
# asscoiated with a specific column. There is some initial overhead involved
# in the accessor's validation and creation. Thereafter, the accessor will
# respond just like as a normal method. During accessor's creation, AUTOLOAD
# will decide the best strategy for geting the column's data depending on
# the underlying row implementation (arrayref or hashref), resulting in
# an accessor that is always appropriate.

{
    no strict 'refs';

    sub AUTOLOAD {
        return if substr( $AUTOLOAD, -7 ) eq 'DESTROY';

        ( my $name = $AUTOLOAD ) =~ s/.*:://;
        my $symbol = $_[0]->row_class . '::' . $name;
        my $fn     = do {
            push @{ $_[0]->row_class . '::AUTOLOAD_ACCESSORS' }, $symbol;
 
            if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                if ( my $sth = $_[0]->rs->sth ) {
                    my $idx = $sth->{NAME_lc_hash}{ lc $name };
 
                    throw E_UNKNOWN_COLUMN, $name unless defined $idx;
 
                    sub { $_[0]->[$idx] };
                } else {
                    throw E_STH_EXPIRED;
                }
            } elsif ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                if ( exists $_[0]->{$name} ) {
                    sub { $_[0]->{$name} };
                } else {
                    my ($idx) = do {
                        local ($_);
                        grep { $name eq lc $_ } keys %{ $_[0] };
                    };
 
                    throw E_UNKNOWN_COLUMN, $name unless defined $idx;
 
                    sub { $_[0]->{$idx} };
                }
            } else {
                throw E_BAD_OBJECT;
            }
        };

        *{$symbol} = subname( $symbol, $fn );

        goto &{$symbol};
    }
}

1;
