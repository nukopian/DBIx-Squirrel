package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::db;
use strict;
use warnings;
use constant E_BAD_SQL_ABSTRACT_METHOD => 'Unimplemented SQL::Abstract method';
use constant E_BAD_SQL_ABSTRACT        => 'Bad or undefined SQL::Abstract global';

BEGIN {
    require DBIx::Squirrel unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBI::db';
}

use namespace::autoclean;
use Data::Dumper::Concise;
use DBIx::Squirrel::util ':constants', ':sql', 'throw';

BEGIN {
    ( my $r = __PACKAGE__ ) =~ s/::\w+$//;

    sub ROOT_CLASS {
        return $r unless wantarray;
        return RootClass => $r;
    }
}

BEGIN {
    our $SQL_ABSTRACT = eval {
        require SQL::Abstract;
        SQL::Abstract->import;
        SQL::Abstract->new;
    };

    if ($SQL_ABSTRACT) {
        *abstract = sub {
            throw E_BAD_SQL_ABSTRACT unless UNIVERSAL::isa( $SQL_ABSTRACT, 'SQL::Abstract' );
            my $self        = shift;
            my $method_name = shift;
            my $method      = $SQL_ABSTRACT->can($method_name);
            throw E_BAD_SQL_ABSTRACT_METHOD unless $method;
            $self->do( $method->( $SQL_ABSTRACT, @_ ) );
        };
    }
}

sub _attr {
    my $self = shift;
    return unless ref $self;
    unless ( defined $self->{'private_dbix_squirrel'} ) {
        $self->{'private_dbix_squirrel'} = {};
    }
    unless (@_) {
        return $self->{'private_dbix_squirrel'} unless wantarray;
        return ( $self->{'private_dbix_squirrel'}, $self );
    }
    unless ( defined $_[0] ) {
        delete $self->{'private_dbix_squirrel'};
        shift;
    }
    if (@_) {
        unless ( exists $self->{'private_dbix_squirrel'} ) {
            $self->{'private_dbix_squirrel'} = {};
        }
        if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
            $self->{'private_dbix_squirrel'} = { %{ $self->{'private_dbix_squirrel'} }, %{ $_[0] } };
        } elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
            $self->{'private_dbix_squirrel'} = { %{ $self->{'private_dbix_squirrel'} }, @{ $_[0] } };
        } else {
            $self->{'private_dbix_squirrel'} = { %{ $self->{'private_dbix_squirrel'} }, @_ };
        }
    }
    return $self;
}

sub delete {
    my $self = shift;
    return scalar $self->abstract( 'delete', @_ );
}

sub insert {
    my $self = shift;
    return scalar $self->abstract( 'insert', @_ );
}

sub update {
    my $self = shift;
    return scalar $self->abstract( 'update', @_ );
}

sub select {
    my $self = shift;
    my ( undef, $result, ) = $self->abstract( 'select', @_ );
    return $result;
}

sub prepare {
    my $self      = shift;
    my $statement = shift;
    my ( $placeholders, $normalised_statement, $original_statement, $digest ) = study_statement($statement);
    throw E_EXP_STATEMENT unless defined $normalised_statement;
    my $sth = $self->SUPER::prepare( $normalised_statement, @_ );
    return unless defined $sth;
    return bless( $sth, 'DBIx::Squirrel::st' )->_attr(
        {   'Placeholders'        => $placeholders,
            'NormalisedStatement' => $normalised_statement,
            'OriginalStatement'   => $original_statement,
            'Hash'                => $digest,
        }
    );
}

sub prepare_cached {
    my $self      = shift;
    my $statement = shift;
    my ( $placeholders, $normalised_statement, $original_statement, $digest ) = study_statement($statement);
    throw E_EXP_STATEMENT unless defined $normalised_statement;
    my $sth = $self->SUPER::prepare_cached( $normalised_statement, @_ );
    return unless defined $sth;
    return bless( $sth, 'DBIx::Squirrel::st' )->_attr(
        {   'Placeholders'        => $placeholders,
            'NormalisedStatement' => $normalised_statement,
            'OriginalStatement'   => $original_statement,
            'Hash'                => $digest,
            'CacheKey'            => join( '#', ( caller 0 )[ 1, 2 ] ),
        }
    );
}

sub do {
    my $self      = shift;
    my $statement = shift;
    my ( $res, $sth ) = do {
        if (@_) {
            if ( ref $_[0] ) {
                if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                    my $statement_attrs = shift;
                    if ( my $sth = $self->prepare( $statement, $statement_attrs ) ) {
                        ( $sth->execute(@_), $sth );
                    } else {
                        ();
                    }
                } elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                    if ( my $sth = $self->prepare($statement) ) {
                        ( $sth->execute(@_), $sth );
                    } else {
                        ();
                    }
                } else {
                    throw E_EXP_REF;
                }
            } else {
                if ( defined $_[0] ) {
                    if ( my $sth = $self->prepare($statement) ) {
                        ( $sth->execute(@_), $sth );
                    } else {
                        ();
                    }
                } else {
                    shift;
                    if ( my $sth = $self->prepare( $statement, undef ) ) {
                        ( $sth->execute(@_), $sth );
                    } else {
                        ();
                    }
                }
            }
        } else {
            if ( my $sth = $self->prepare($statement) ) {
                ( $sth->execute, $sth );
            } else {
                ();
            }
        }
    };
    return $res unless wantarray;
    return $res, $sth;
}

sub execute {
    my $self = shift;
    my $statement = shift;
    my ( $res, $sth ) = $self->do( $statement, @_ );
    return $sth unless wantarray;
    return $sth, $res;
}

BEGIN {
    *iterate = *it = sub {
        my ( $self, $st, @t ) = @_;
        if (@t) {
            if ( ref $t[0] ) {
                if ( UNIVERSAL::isa( $t[0], 'HASH' ) ) {
                    my ( $sattr, @values ) = @t;
                    if ( my $sth = $self->prepare( $st, $sattr ) ) {
                        return $sth->it(@values);
                    }
                } elsif ( UNIVERSAL::isa( $t[0], 'ARRAY' ) ) {
                    if ( my $sth = $self->prepare($st) ) {
                        return $sth->it(@t);
                    }
                } elsif ( UNIVERSAL::isa( $t[0], 'CODE' ) ) {
                    if ( my $sth = $self->prepare($st) ) {
                        return $sth->it(@t);
                    }
                } else {
                    throw E_EXP_REF;
                }
            } else {
                if ( defined $t[0] ) {
                    if ( my $sth = $self->prepare($st) ) {
                        return $sth->it(@t);
                    }
                } else {
                    my ( undef, @values ) = @t;
                    if ( my $sth = $self->prepare( $st, undef ) ) {
                        return $sth->it(@values);
                    }
                }
            }
        } else {
            if ( my $sth = $self->prepare($st) ) {
                return $sth->it;
            }
        }
        return;
    };

    *resultset = *results = *rs = sub {
        my ( $self, $st, @t ) = @_;
        if (@t) {
            if ( ref $t[0] ) {
                if ( UNIVERSAL::isa( $t[0], 'HASH' ) ) {
                    my ( $sattr, @values ) = @t;
                    if ( my $sth = $self->prepare( $st, $sattr ) ) {
                        return $sth->rs(@t);
                    }
                } elsif ( UNIVERSAL::isa( $t[0], 'ARRAY' ) ) {
                    if ( my $sth = $self->prepare($st) ) {
                        return $sth->rs(@t);
                    }
                } elsif ( UNIVERSAL::isa( $t[0], 'CODE' ) ) {
                    if ( my $sth = $self->prepare($st) ) {
                        return $sth->rs(@t);
                    }
                } else {
                    throw E_EXP_REF;
                }
            } else {
                if ( defined $t[0] ) {
                    if ( my $sth = $self->prepare($st) ) {
                        return $sth->rs(@t);
                    }
                } else {
                    my ( undef, @values ) = @t;
                    if ( my $sth = $self->prepare( $st, undef ) ) {
                        return $sth->rs(@values);
                    }
                }
            }
        } else {
            if ( my $sth = $self->prepare($st) ) {
                return $sth->rs;
            }
        }
        return;
    };
}

1;
