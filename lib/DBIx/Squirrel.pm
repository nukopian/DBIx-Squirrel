package DBIx::Squirrel;
use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'reftype';
use Sub::Name;

BEGIN {
    our $VERSION               = '1.0.0_210925';
    our @ISA                   = 'DBI';
    our $STRICT_PARAM_CHECK    = 0;
    our $AUTO_FINISH_ON_ACTIVE = 1;
}

use DBI                ();
use DBIx::Squirrel::dr ();
use DBIx::Squirrel::db ();
use DBIx::Squirrel::st ();
use DBIx::Squirrel::it ();
use DBIx::Squirrel::rs ();
use DBIx::Squirrel::rc ();

BEGIN {
    our $NORMALISE_SQL = 1;

    *err             = *DBI::err;
    *errstr          = *DBI::errstr;
    *rows            = *DBI::rows;
    *lasth           = *DBI::lasth;
    *state           = *DBI::state;
    *connect_cached  = *DBIx::Squirrel::dr::connect_cached;
    *connect         = *DBIx::Squirrel::dr::connect;
    *SQL_ABSTRACT    = *DBIx::Squirrel::db::SQL_ABSTRACT;
    *DEFAULT_SLICE   = *DBIx::Squirrel::it::DEFAULT_SLICE;
    *DEFAULT_MAXROWS = *DBIx::Squirrel::it::DEFAULT_MAXROWS;
    *BUF_MULT        = *DBIx::Squirrel::it::BUF_MULT;
    *BUF_MAXROWS     = *DBIx::Squirrel::it::BUF_MAXROWS;
    *NORMALIZE_SQL   = *NORMALISE_SQL;
}

sub import {
    no strict 'refs';

    my $class  = shift;
    my $caller = caller;

    for my $name (@_) {
        my $symbol = $class . '::' . $name;
        unless ( defined &{$symbol} ) {
            *{$symbol} = subname(
                $symbol => sub {
                    if (@_) {
                        if ( UNIVERSAL::isa( $_[0], $class . '::db' ) ) {
                            ${$symbol} = shift;
                        } else {
                            if ( UNIVERSAL::isa( $_[0], $class . '::st' ) ) {
                                ${$symbol} = shift;
                            } elsif ( UNIVERSAL::isa( $_[0], $class . '::it' ) ) {
                                ${$symbol} = shift;
                            } elsif ( UNIVERSAL::isa( $_[0], $class . '::rs' ) ) {
                                ${$symbol} = shift;
                            } else {

                                # The underlying statement maye take no
                                # parameters, in which case there are none
                                # to pass. To coerce this function into
                                # executing the statement (rather than
                                # just returning its handle), allow any
                                # parameters to be passed inside an
                                # anonymous array, which may be empty
                                # to signal that statement execution
                                # is required.
                                #
                                if (@_) {
                                    if ( @_ == 1 && ref $_[0] && reftype( $_[0] ) eq 'ARRAY' ) {
                                        ${$symbol}->execute( @{ +shift } );
                                    } else {
                                        ${$symbol}->execute(@_);
                                    }
                                }
                            }
                        }
                    }

                    return ${$symbol};
                }
            );
        }

        unless ( defined &{ $caller . '::' . $name } ) {
            *{ $caller . '::' . $name } = *{$symbol};
        }
    }
    return $class;
}

1;
