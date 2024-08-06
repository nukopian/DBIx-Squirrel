package DBIx::Squirrel;
use strict;
use warnings;
use constant E_BAD_ENT_BIND     => 'May only bind a database connetion handle, statement handle, or iterator';
use constant E_BAD_ENT_TYPE     => 'May only address a statement handle or iterator';
use constant E_EXP_HASH_ARR_REF => 'Expected a reference to a HASH or ARRAY';

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
use DBIx::Squirrel::util 'throw';

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

                        # By passing a database connection handle, statement
                        # handle, iterator, or result set reference, we may
                        # define an association between the function and an
                        # entity at runtime.

                        if (   UNIVERSAL::isa( $_[0], $class . '::db' )
                            or UNIVERSAL::isa( $_[0], $class . '::st' )
                            or UNIVERSAL::isa( $_[0], $class . '::it' ) )
                        {
                            ${$symbol} = shift;
                            return ${$symbol};
                        }

                        throw E_BAD_ENT_BIND;
                    }

                    return unless defined ${$symbol};

                    return ${$symbol} unless @_;

                    # If the function reaches this point, we are
                    # addressing the underlying entity, passing
                    # parameters that are meaningful in that
                    # context.

                    if (   UNIVERSAL::isa( ${$symbol}, $class . '::st' )
                        or UNIVERSAL::isa( ${$symbol}, $class . '::it' ) )
                    {
                        my @params = do {
                            if ( @_ == 1 && ref $_[0] ) {

                                # The underlying entity may take no
                                # parameters, in which case there is
                                # nothing meaningful that we can pass
                                # to it. When no parameters are passed,
                                # we expect this function to simply return
                                # a reference to to the entity itself. If,
                                # however, we wish to have the underlying
                                # entity perform a contextually relevant
                                # operation, we allow parameters to be
                                # passed inside an anonymous array, which
                                # may be empty as a signal to do just that.

                                if ( reftype( $_[0] ) eq 'ARRAY' ) {
                                    @{ +shift };
                                } elsif ( reftype( $_[0] ) eq 'HASH' ) {
                                    %{ +shift };
                                } else {
                                    throw E_EXP_HASH_ARR_REF;
                                }
                            } else {
                                @_;
                            }
                        };

                        return ${$symbol}->execute(@params);
                    }

                    throw E_BAD_ENT_TYPE;
                }
            );
        }

        # Export any relevant symbols to caller's namespace.

        unless ( defined &{ $caller . '::' . $name } ) {
            *{ $caller . '::' . $name } = *{$symbol};
        }
    }

    return $class;
}

1;
