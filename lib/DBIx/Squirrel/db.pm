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
        return wantarray ? ( RootClass => $r ) : $r;
    }
}

BEGIN {
    our $SQL_ABSTRACT = eval {
        require SQL::Abstract;
        SQL::Abstract->import;
        SQL::Abstract->new;
    };

    sub abstract {
        throw E_BAD_SQL_ABSTRACT
          unless UNIVERSAL::isa( $SQL_ABSTRACT, 'SQL::Abstract' );
        my $self   = shift;
        my $method_name = shift;
        my $method = $SQL_ABSTRACT->can($method_name);
        throw E_BAD_SQL_ABSTRACT_METHOD unless $method;
        $self->do( $method->( $SQL_ABSTRACT, @_ ) );
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

sub prepare {
    my ( $self, $st, @args ) = @_;
    my ( $p, $n, $t, $h ) = study_statement($st);
    throw E_EXP_STATEMENT unless defined $n;
    return                unless my $sth = $self->SUPER::prepare( $n, @args );
    return bless( $sth, 'DBIx::Squirrel::st' )->_att(
        {   'Placeholders'        => $p,
            'NormalisedStatement' => $n,
            'OriginalStatement'   => $t,
            'Hash'                => $h,
        }
    );
}

sub prepare_cached {
    my ( $self, $st, @args ) = @_;
    my ( $p, $n, $t, $h ) = study_statement($st);
    throw E_EXP_STATEMENT unless defined $n;
    return                unless my $sth = $self->SUPER::prepare_cached( $n, @args );
    return bless( $sth, 'DBIx::Squirrel::st' )->_att(
        {   'Placeholders'        => $p,
            'NormalisedStatement' => $n,
            'OriginalStatement'   => $t,
            'Hash'                => $h,
            'CacheKey'            => join( '#', ( caller 0 )[ 1, 2 ] ),
        }
    );
}

sub do {
    my ( $self, $st, @t ) = @_;
    my ( $res, $sth ) = do {
        if (@t) {
            if ( ref $t[0] ) {
                if ( UNIVERSAL::isa( $t[0], 'HASH' ) ) {
                    my ( $sattr, @values ) = @t;
                    if ( my $sth = $self->prepare( $st, $sattr ) ) {
                        ( $sth->execute(@values), $sth );
                    } else {
                        ();
                    }
                } elsif ( UNIVERSAL::isa( $t[0], 'ARRAY' ) ) {
                    if ( my $sth = $self->prepare($st) ) {
                        ( $sth->execute(@t), $sth );
                    } else {
                        ();
                    }
                } else {
                    throw E_EXP_REF;
                }
            } else {
                if ( defined $t[0] ) {
                    if ( my $sth = $self->prepare($st) ) {
                        ( $sth->execute(@t), $sth );
                    } else {
                        ();
                    }
                } else {
                    my ( undef, @values ) = @t;
                    if ( my $sth = $self->prepare( $st, undef ) ) {
                        ( $sth->execute(@values), $sth );
                    } else {
                        ();
                    }
                }
            }
        } else {
            if ( my $sth = $self->prepare($st) ) {
                ( $sth->execute, $sth );
            } else {
                ();
            }
        }
    };
    return wantarray ? ( $res, $sth ) : $res;
}

sub execute {
    my ( $res, $sth ) = $_[0]->do( $_[1], @_[ 2 .. $#_ ] );
    return wantarray ? ( $sth, $res ) : $sth;
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
