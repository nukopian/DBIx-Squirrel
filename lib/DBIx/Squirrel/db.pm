package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::db;
use strict;
use warnings;
use constant E_BAD_SQL_ABSTRACT_METHOD => 'Unimplemented SQL::Abstract method';

BEGIN {
    require DBIx::Squirrel unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBI::db';
}

use namespace::autoclean;
use Data::Dumper::Concise;
use DBIx::Squirrel::util ':constants', ':sql', 'throw';
use SQL::Abstract;

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

our $SQL_ABSTRACT = SQL::Abstract->new;

sub abstract {
    my $self        = shift;
    my $method_name = shift;
    my $method      = $SQL_ABSTRACT->can($method_name);

    throw E_BAD_SQL_ABSTRACT_METHOD unless $method;

    return $self->do( $method->( $SQL_ABSTRACT, @_ ) );
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

sub execute {
    my $self      = shift;
    my $statement = shift;
    my ( $res, $sth ) = $self->do( $statement, @_ );

    return $sth unless wantarray;

    return $sth, $res;
}

sub do {
    my $self      = shift;
    my $statement = shift;
    my $sth       = do {
        if (@_) {
            if ( ref $_[0] ) {
                if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                    my $statement_attrs = shift;
                    $self->prepare( $statement, $statement_attrs );
                } elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                    $self->prepare($statement);
                } else {
                    throw E_EXP_REF;
                }
            } else {
                if ( defined $_[0] ) {
                    $self->prepare($statement);
                } else {
                    shift;
                    $self->prepare( $statement, undef );
                }
            }
        } else {
            $self->prepare($statement);
        }
    };

    return $sth->execute(@_) unless wantarray;

    return $sth->execute(@_), $sth;
}

BEGIN {
    *iterate = *it = sub {
        my $self      = shift;
        my $statement = shift;
        my $sth       = do {
            if (@_) {
                if ( ref $_[0] ) {
                    if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                        my $statement_attrs = shift;
                        $self->prepare( $statement, $statement_attrs );
                    } elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                        $self->prepare($statement);
                    } elsif ( UNIVERSAL::isa( $_[0], 'CODE' ) ) {
                        $self->prepare($statement);
                    } else {
                        throw E_EXP_REF;
                    }
                } else {
                    if ( defined $_[0] ) {
                        $self->prepare($statement);
                    } else {
                        shift;
                        $self->prepare( $statement, undef );
                    }
                }
            } else {
                $self->prepare($statement);
            }
        };

        return $sth->it(@_);
    };

    *resultset = *rs = sub {
        my $self      = shift;
        my $statement = shift;
        my $sth       = do {
            if (@_) {
                if ( ref $_[0] ) {
                    if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                        my $statement_attrs = shift;
                        $self->prepare( $statement, $statement_attrs );
                    } elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                        $self->prepare($statement);
                    } elsif ( UNIVERSAL::isa( $_[0], 'CODE' ) ) {
                        $self->prepare($statement);
                    } else {
                        throw E_EXP_REF;
                    }
                } else {
                    if ( defined $_[0] ) {
                        $self->prepare($statement);
                    } else {
                        shift;
                        $self->prepare( $statement, undef );
                    }
                }
            } else {
                $self->prepare($statement);
            }
        };

        return $sth->rs(@_);
    };
}

1;
