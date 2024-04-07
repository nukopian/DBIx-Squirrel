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
use DBIx::Squirrel::util 'throw', 'whine';

{
    my $r;

    sub ROOT_CLASS {
        ( $r = __PACKAGE__ ) =~ s/::\w+$// unless defined $r;
        return wantarray ? ( RootClass => $r ) : $r;
    }
}

sub _id {
    return          unless ref $_[0];
    return 0+ $_[0] unless wantarray;
    return ( 0+ $_[0], @_ );
}

sub _att {
    return unless ref $_[0];
    my ( $att, $id, $self, @t ) = (
        do {
            if ( defined $_[0]->{private_dbix_squirrel} ) {
                $_[0]->{private_dbix_squirrel};
            } else {
                $_[0]->{private_dbix_squirrel} = {};
            }
        },
        0+ $_[0],
        @_,
    );
    return wantarray ? ( $att, $self ) : $att unless @t;
    if ( @t == 1 && !defined $t[0] ) {
        delete $self->{private_dbix_squirrel};
        return;
    }
    $self->{private_dbix_squirrel} = {
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

sub prepare {
    my $self = shift;
    return $self->{'Database'}->prepare( $self->{'Statement'}, @_ );
}

sub execute {
    my $self = shift;
    if ( $DBIx::Squirrel::AUTO_FINISH_ON_ACTIVE && $self->{'Active'} ) {
        $self->finish;
    }
    if (@_) {
        $self->bind(@_);
    }
    return $self->SUPER::execute;
}

sub bind {
    my $self = shift;
    return $self unless @_;
    if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
        $self->bind_param( $_, $_[0][$_] ) for 1 .. scalar @{ $_[0] };
        return $self;
    } else {
        my $placeholders = $self->_att->{Placeholders};
        if ( UNIVERSAL::isa( $_[0], 'HASH' ) || $placeholders ) {
            if ( my %kv = @{ _map_places_to_values( $placeholders, @_ ) } ) {
                while ( my ( $key, $val ) = each %kv ) {
                    if ( $key =~ m/^[\:\$\?]?(?<bind_pos>\d+)$/ ) {
                        unless ( $+{'bind_pos'} > 0 ) {
                            throw E_INVALID_PLACEHOLDER, $key;
                        }
                        $self->bind_param( $+{'bind_pos'}, $val );
                    } else {
                        $self->bind_param( $key, $val );
                    }
                }
            }
        } else {
            $self->bind_param( $_, $_[ $_ - 1 ] ) for 1 .. scalar @_;
        }
    }
    return $self;
}

sub bind_param {
    my $self     = shift;
    my %bindable = do {
        if ( my $placeholders = $self->_att->{Placeholders} ) {
            if ( $_[0] =~ m/^[\:\$\?]?(?<bind_pos>\d+)$/ ) {
                ( $+{'bind_pos'} => $_[1] )
            } else {
                my $prefixed = do {
                    if ( substr( $_[0], 0, 1 ) eq ':' ) {
                        $_[0];
                    } else {
                        ':' . $_[0];
                    }
                };
                map { ( $_ => $_[1] ) }
                  grep { $placeholders->{$_} eq $prefixed }
                  keys %{$placeholders};
            }
        } else {
            ( $_[0] => $_[1] );
        }
    };
    unless (%bindable) {
        return if $DBIx::Squirrel::RELAXED_PARAM_CHECKS;
        throw E_UNKNOWN_PLACEHOLDER, $_[0];
    }
    $self->SUPER::bind_param(%bindable);
    return wantarray ? %bindable : \%bindable;
}

sub _map_places_to_values {
    my $placeholders = shift;
    my $mappings     = do {
        if ( _has_positional_placeholders_only($placeholders) ) {
            [ map { ( $placeholders->{$_} => $_[ $_ - 1 ] ) } keys %{$placeholders} ];
        } else {
            my @mappings = do {
                my $head = $_[0];
                if ( UNIVERSAL::isa( $head, 'HASH' ) ) {
                    %{$head};
                } elsif ( UNIVERSAL::isa( $head, 'ARRAY' ) ) {
                    @{$head};
                } else {
                    @_;
                }
            };
            if ( @mappings % 2 ) {
                whine W_CHECK_BIND_VALS;
            }
            \@mappings;
        }
    };
    return wantarray ? @{$mappings} : $mappings;
}

sub _has_positional_placeholders_only {
    my $placeholders = shift;
    return unless UNIVERSAL::isa( $placeholders, 'HASH' );
    my @placeholders     = values %{$placeholders};
    my $total_count      = @placeholders;
    my $positional_count = grep {m/^[\:\$\?]\d+$/} @placeholders;
    return unless $positional_count == $total_count;
    return $placeholders;
}

BEGIN {
    *iterate = *it = sub {
        return DBIx::Squirrel::it->new(@_);
    };

    *resultset = *results = *rs = sub {
        return DBIx::Squirrel::rs->new(@_);
    };

    *iterator = *itor = sub {
        return $_[0]->_att->{'Iterator'};
    };
}

1;
