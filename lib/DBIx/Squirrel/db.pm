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
use DBIx::Squirrel::util ':constants', ':hashing', 'throw';
use Data::Dumper::Concise;
use Memoize;

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
        throw E_BAD_SQL_ABSTRACT_METHOD
          unless my $method = $SQL_ABSTRACT->can( $_[1] );
        $_[0]->do( $method->( $SQL_ABSTRACT, @_[ 2 .. $#_ ] ) );
    }
}

sub _att {
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
    my ( $p, $n, $t, $h ) = _study_statement($st);
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
    my ( $p, $n, $t, $h ) = _study_statement($st);
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

our %_CACHE;

sub _study_statement {
    my ( $normalised_sql_string, $sql_string, $sql_digest ) = &_normalise_statement;
    return unless defined $sql_string;
    unless ( defined $_CACHE{$sql_digest} ) {
        $_CACHE{$sql_digest} = do {
            if ( my @placeholders = $sql_string =~ m{[\:\$\?]\w+\b}g ) {
                [   +{ map { ( 1 + $_ => $placeholders[$_] ) } ( 0 .. @placeholders - 1 ) },
                    $normalised_sql_string,
                    $sql_string,
                    $sql_digest,
                ];
            } else {
                [   undef,
                    $normalised_sql_string,
                    $sql_string,
                    $sql_digest,
                ];
            }
        };
    }
    return @{ $_CACHE{$sql_digest} };
}

our $NORMALISE_SQL = 1;

sub _normalise_statement {
    my ( $sql_string, $sql_digest ) = &_get_trimmed_sql_string_and_digest;
    unless ($NORMALISE_SQL) {
        return $sql_string unless wantarray;
        return $sql_string, $sql_string, $sql_digest;
    }
    ( my $normalised_sql_string = $sql_string ) =~ s{[\:\$\?]\w+\b}{?}g;
    return $normalised_sql_string unless wantarray;
    return $normalised_sql_string, $sql_string, $sql_digest;
}

sub _get_trimmed_sql_string_and_digest {
    my $sth_or_sql_string = shift;
    my $sql_string        = do {
        if ( ref $sth_or_sql_string ) {
            if ( UNIVERSAL::isa( $sth_or_sql_string, 'DBIx::Squirrel::st' ) ) {
                _trim_sql_string( $sth_or_sql_string->_att->{'OriginalStatement'} );
            } elsif ( UNIVERSAL::isa( $sth_or_sql_string, 'DBI::st' ) ) {
                _trim_sql_string( $sth_or_sql_string->{Statement} );
            } else {
                throw E_EXP_STH;
            }
        } else {
            _trim_sql_string($sth_or_sql_string);
        }
    };
    return $sql_string unless wantarray;
    my $sql_digest = _hash_sql_string($sql_string);
    return $sql_string, $sql_digest;
}

sub _hash_sql_string {
    my $sql_string = shift;
    return unless defined $sql_string && length $sql_string && $sql_string =~ m/\S/;
    return hash($sql_string);
}

BEGIN { memoize('_hash_sql_string'); }

sub _trim_sql_string {
    my $sql_string = shift;
    return '' unless defined $sql_string && length $sql_string && $sql_string =~ m/\S/;
    (   s{\s+-{2}\s+.*$}{}gm,
        s{^[[:blank:]\r\n]+}{}gm,
        s{[[:blank:]\r\n]+$}{}gm,
    ) for $sql_string;
    return $sql_string;
}

BEGIN { memoize('_trim_sql_string'); }

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

    sub it {
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
    }

    *iterate = *it;
}

BEGIN {

    sub rs {
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
    }

    *resultset = *results = *rs;
}

sub delete {
    return scalar $_[0]->abstract( 'delete', @_[ 1 .. $#_ ] );
}

sub insert {
    return scalar $_[0]->abstract( 'insert', @_[ 1 .. $#_ ] );
}

sub update {
    return scalar $_[0]->abstract( 'update', @_[ 1 .. $#_ ] );
}

sub select {
    return ( $_[0]->abstract( 'select', @_[ 1 .. $#_ ] ) )[1];
}

1;
