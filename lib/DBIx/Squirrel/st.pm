package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::st;
use strict;
use warnings;
use constant E_INVALID_PLACEHOLDER => 'Cannot bind invalid placeholder (%s)';
use constant E_UNKNOWN_PLACEHOLDER => 'Cannot bind unknown placeholder (%s)';
use constant W_CHECK_BIND_VALS     => 'Check bind values match placeholder scheme';

BEGIN {
    require DBIx::Squirrel
      unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBI::st';
}

use namespace::autoclean;
use DBIx::Squirrel::util (
    'throw',
    'whinge',
);

{
    my $r;

    sub ROOT_CLASS {
        ( $r = __PACKAGE__ ) =~ s/::\w+$// unless defined $r;
        return wantarray ? ( RootClass => $r ) : $r;
    }
}

sub _att {
    return unless ref $_[ 0 ];
    my ( $att, $id, $self, @t ) = (
        do {
            if ( defined $_[ 0 ]->{ private_dbix_squirrel } ) {
                $_[ 0 ]->{ private_dbix_squirrel };
            }
            else {
                $_[ 0 ]->{ private_dbix_squirrel } = {};
            }
        },
        0+ $_[ 0 ],
        @_,
    );
    return wantarray ? ( $att, $self ) : $att unless @t;
    if ( @t == 1 && !defined $t[ 0 ] ) {
        delete $self->{ private_dbix_squirrel };
        return;
    }
    $self->{ private_dbix_squirrel } = {
        %{ $att },
        do {
            if ( UNIVERSAL::isa( $t[ 0 ], 'HASH' ) ) {
                %{ $t[ 0 ] };
            }
            elsif ( UNIVERSAL::isa( $t[ 0 ], 'ARRAY' ) ) {
                @{ $t[ 0 ] };
            }
            else {
                @t;
            }
        },
    };
    return $self;
}

sub _id {
    return !ref $_[ 0 ] ? undef : wantarray ? ( 0+ $_[ 0 ], @_ ) : 0+ $_[ 0 ];
}

sub prepare {
    return $_[ 0 ]->{ 'Database' }->prepare(
        $_[ 0 ]->{ 'Statement' },
        @_[ 1 .. $#_ ]
    );
}

sub execute {
    my ( $self, @t ) = @_;
    $_[ 0 ]->finish
      if $_[ 0 ]->{ 'Active' }
      && $DBIx::Squirrel::AUTO_FINISH_ON_ACTIVE;
    $_[ 0 ]->bind( @_[ 1 .. $#_ ] ) if @_ > 1;
    return $_[ 0 ]->SUPER::execute;
}

sub bind {
    return $_[ 0 ] unless @_ > 1;
    if ( UNIVERSAL::isa( $_[ 1 ], 'ARRAY' ) ) {
        $_[ 0 ]->bind_param( $_, $_[ 1 ][ $_ ] ) for 1 .. scalar @{ $_[ 1 ] };
        return $_[ 0 ];
    }
    else {
        my $p = $_[ 0 ]->_att->{ Placeholders };
        if ( UNIVERSAL::isa( $_[ 1 ], 'HASH' ) || $p ) {
            if ( my %kv = @{ _map_places_to_values( $p, @_[ 1 .. $#_ ] ) } ) {
                while ( my ( $k, $v ) = each %kv ) {
                    if ( $k =~ m/^[\:\$\?]?(\d+)$/ ) {
                        throw E_INVALID_PLACEHOLDER, $k unless $1 > 0;
                        $_[ 0 ]->bind_param( $1, $v );
                    }
                    else {
                        $_[ 0 ]->bind_param( $k, $v );
                    }
                } ## end while ( my ( $k, $v ) = each...)
            } ## end if ( my %kv = @{ _map_places_to_values...})
        } ## end if ( UNIVERSAL::isa( $_...))
        else {
            $_[ 0 ]->bind_param( $_, $_[ $_ ] ) for 1 .. scalar @_;
        }
    } ## end else [ if ( UNIVERSAL::isa( $_...))]
    return $_[ 0 ];
}

sub _map_places_to_values {
    my $places = do {
        if ( _only_positional_placeholders( $_[ 0 ] ) ) {
            [ map { $_[ 0 ]{ $_ } => $_[ $_ ] } keys %{ $_[ 0 ] } ];
        }
        else {
            my @p
              = UNIVERSAL::isa( $_[ 1 ], 'HASH' )  ? %{ $_[ 1 ] }
              : UNIVERSAL::isa( $_[ 1 ], 'ARRAY' ) ? @{ $_[ 1 ] }
              :                                      @_[ 1 .. $#_ ];
            whinge W_CHECK_BIND_VALS if @p % 2;
            \@p;
        }
    };
    return wantarray ? @{ $places } : $places;
}

sub _only_positional_placeholders {
    return unless UNIVERSAL::isa( $_[ 0 ], 'HASH' );
    my $total = values %{ $_[ 0 ] };
    my $count = grep { m/^[\:\$\?]\d+$/ } values %{ $_[ 0 ] };
    return $count == $total ? $_[ 0 ] : undef;
}

sub bind_param {
    my %bindable = do {
        if ( my $p = $_[ 0 ]->_att->{ Placeholders } ) {
            $_[ 1 ] =~ m/^[\:\$\?]?(\d+)$/ ? ( $1 => $_[ 2 ] ) : do {
                my $a = substr( $_[ 1 ], 0, 1 ) eq ':' ? $_[ 1 ] : ':' . $_[ 1 ];
                map { $_ => $_[ 2 ] } grep { $p->{ $_ } eq $a } keys %{ $p };
            };
        }
        else {
            ( $_[ 1 ] => $_[ 2 ] );
        }
    };
    unless ( %bindable ) {
        throw E_UNKNOWN_PLACEHOLDER, $_[ 1 ]
          unless $DBIx::Squirrel::RELAXED_PARAM_CHECKS;
        return;
    }
    $_[ 0 ]->SUPER::bind_param( %bindable );
    return wantarray ? %bindable : \%bindable;
}

BEGIN {

    sub it {
        return DBIx::Squirrel::it->new( @_ );
    }

    *iterate = *it;
}

BEGIN {

    sub rs {
        return DBIx::Squirrel::rs->new( @_ );
    }

    *resultset = *results = *rs;
}

BEGIN {

    sub itor {
        return $_[ 0 ]->_att->{ 'Iterator' };
    }

    *iterator = *itor;
}

1;
