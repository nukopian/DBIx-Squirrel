package    # hide from PAUSE
  DBIx::Squirrel::db;
use strict;
use warnings;
use constant E_BAD_SQL_ABSTRACT_METHOD => 'Unimplemented SQL::Abstract method';
use constant E_BAD_SQL_ABSTRACT        => 'Bad or undefined SQL::Abstract global';

BEGIN {
    require DBIx::Squirrel
      unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBI::db';
}

use namespace::autoclean;
use DBIx::Squirrel::util (
    ':constants',
    ':hashing',
    'throw',
);

BEGIN {
    ( my $r = __PACKAGE__ ) =~ s/::\w+$//;

    sub ROOT_CLASS
    {
        return wantarray ? ( RootClass => $r ) : $r;
    }
}

BEGIN {
    our $SQL_ABSTRACT = eval {
        require SQL::Abstract;
        SQL::Abstract->import;
        SQL::Abstract->new;
    };

    sub abstract
    {
        throw E_BAD_SQL_ABSTRACT
          unless UNIVERSAL::isa( $SQL_ABSTRACT, 'SQL::Abstract' );
        throw E_BAD_SQL_ABSTRACT_METHOD
          unless my $method = $SQL_ABSTRACT->can( $_[1] );
        $_[0]->do( $method->( $SQL_ABSTRACT, @_[ 2 .. $#_ ] ) );
    }
}

our $NORMALISE_SQL = 1;

sub _sqlnorm
{
    my ( $s, $h ) = &_sqltrim;
    return wantarray ? ( $s, $s, $h ) : $s unless $NORMALISE_SQL;
    ( my $n = $s ) =~ s{[\:\$\?]\w+\b}{?}g;
    return wantarray ? ( $n, $s, $h ) : $n;
}

sub _sqltrim
{
    (
        my $s = do {
            if ( ref $_[0] ) {
                if ( UNIVERSAL::isa( $_[0], 'DBIx::Squirrel::st' ) ) {
                    $_[0]->_att->{'OriginalStatement'};
                } else {
                    throw E_EXP_STH
                      unless UNIVERSAL::isa( $_[0], 'DBI::st' );
                    $_[0]->{Statement};
                }
            } else {
                defined $_[0] ? $_[0] : '';
            }
        }
    ) =~ s{\A[\s\t\n\r]+|[\s\t\n\r]+\z}{}gs;
    return wantarray ? ( $s, $HASH ? hash($s) : $s ) : $s;
}

our %_CACHE;

sub _study
{
    my ( $n, $s, $h ) = &_sqlnorm;
    return ( undef, undef, undef, undef ) unless defined $s;
    my $r = defined $_CACHE{$h} ? $_CACHE{$h} : (
        $_CACHE{$h} = do {
            if ( my @p = $s =~ m{[\:\$\?]\w+\b}g ) {
                [ { map { 1 + $_ => $p[$_] } 0 .. @p - 1 }, $n, $s, $h ];
            } else {
                [ undef, $n, $s, $h ];
            }
        }
    );
    return @{$r};
}

sub _att
{
    return unless ref $_[0];
    my ( $att, $id, $self, @t ) = (
        do {
            if ( defined $_[0]->{'private_dbix_squirrel'} ) {
                $_[0]->{'private_dbix_squirrel'};
            } else {
                $_[0]->{'private_dbix_squirrel'} = {};
            }
        },
        0+ $_[0],
        @_
    );
    return wantarray ? ( $att, $self ) : $att unless @t;
    if ( @t == 1 && !defined $t[0] ) {
        delete $self->{'private_dbix_squirrel'};
        return;
    }
    $self->{'private_dbix_squirrel'} = {
        %{$att},
        do {
            if ( UNIVERSAL::isa( $t[0], 'HASH' ) ) {
                %{ $t[0] };
            } elsif ( UNIVERSAL::isa( $t[0], 'ARRAY' ) ) {
                @{ $t[0] };
            } else {
                @t;
            }
        },
    };
    return $self;
}

sub prepare
{
    my ( $self, $st, @args ) = @_;
    my ( $p, $n, $t, $h ) = _study($st);
    throw E_EXP_STATEMENT unless defined $n;
    return unless my $sth = $self->SUPER::prepare( $n, @args );
    return bless( $sth, 'DBIx::Squirrel::st' )->_att(
        {
            'Placeholders'        => $p,
            'NormalisedStatement' => $n,
            'OriginalStatement'   => $t,
            'Hash'                => $h,
        }
    );
}

sub prepare_cached
{
    my ( $self, $st, @args ) = @_;
    my ( $p, $n, $t, $h ) = _study($st);
    throw E_EXP_STATEMENT unless defined $n;
    return unless my $sth = $self->SUPER::prepare_cached( $n, @args );
    return bless( $sth, 'DBIx::Squirrel::st' )->_att(
        {
            'Placeholders'        => $p,
            'NormalisedStatement' => $n,
            'OriginalStatement'   => $t,
            'Hash'                => $h,
            'CacheKey'            => join( '#', ( caller 0 )[ 1, 2 ] ),
        }
    );
}

sub do
{
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

sub execute
{
    my ( $res, $sth ) = $_[0]->do( $_[1], @_[ 2 .. $#_ ] );
    return wantarray ? ( $sth, $res ) : $sth;
}

BEGIN {
    sub it
    {
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
    sub rs
    {
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

sub delete
{
    return scalar $_[0]->abstract( 'delete', @_[ 1 .. $#_ ] );
}

sub insert
{
    return scalar $_[0]->abstract( 'insert', @_[ 1 .. $#_ ] );
}

sub update
{
    return scalar $_[0]->abstract( 'update', @_[ 1 .. $#_ ] );
}

sub select
{
    return ( $_[0]->abstract( 'select', @_[ 1 .. $#_ ] ) )[1];
}

1;
