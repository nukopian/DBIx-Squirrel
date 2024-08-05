package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::st;
use strict;
use warnings;
use constant E_INVALID_PLACEHOLDER => 'Cannot bind invalid placeholder (%s)';
use constant E_UNKNOWN_PLACEHOLDER => 'Cannot bind unknown placeholder (%s)';
use constant W_CHECK_BIND_VALS     => 'Check bind values match placeholder scheme';

BEGIN {
    require DBIx::Squirrel unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBI::st';
}

use namespace::autoclean;
use DBIx::Squirrel::util 'throw', 'whine';

sub _attr {
    my $self = shift;
    return unless ref $self;
    unless ( defined $self->{'private_dbix_squirrel'} ) {
        $self->{'private_dbix_squirrel'} = {};
    }
    unless (@_) {
        return $self->{'private_dbix_squirrel'} unless wantarray;
        return $self->{'private_dbix_squirrel'}, $self;
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
    my $placeholders = $self->_attr->{'Placeholders'};
    if ( $placeholders && not _all_placeholders_are_positional($placeholders) ) {
        if ( my %kv = @{ _map_to_values( $placeholders, @_ ) } ) {
            while ( my ( $key, $value ) = each %kv ) {
                if ( $key =~ m/^[\:\$\?]?(?<bind_id>\d+)$/ ) {
                    unless ( $+{'bind_id'} > 0 ) {
                        throw E_INVALID_PLACEHOLDER, $key;
                    }
                    $self->bind_param( $+{'bind_id'}, $value );
                } else {
                    $self->bind_param( $key, $value );
                }
            }
        }
    } else {
        if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
            for my $bind_id ( 1 .. scalar @{ $_[0] } ) {
                $self->bind_param( $bind_id, $_[0][ $bind_id - 1 ] );
            }
        } else {
            for my $bind_id ( 1 .. scalar @_ ) {
                $self->bind_param( $bind_id, $_[ $bind_id - 1 ] );
            }
        }
    }
    return $self;
}

sub _all_placeholders_are_positional {
    my $placeholders = shift;
    return unless UNIVERSAL::isa( $placeholders, 'HASH' );
    my @placeholders     = values %{$placeholders};
    my $total_count      = @placeholders;
    my $positional_count = grep {m/^[\:\$\?]\d+$/} @placeholders;
    return unless $positional_count == $total_count;
    return $placeholders;
}

sub _map_to_values {
    my $placeholders = shift;
    my $mappings     = do {
        if ( _all_placeholders_are_positional($placeholders) ) {
            [ map { ( $placeholders->{$_} => $_[ $_ - 1 ] ) } keys %{$placeholders} ];
        } else {
            my @mappings = do {
                if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                    @{ $_[0] };
                } elsif ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                    %{ $_[0] };
                } else {
                    @_;
                }
            };
            unless ( @mappings % 2 == 0 ) {
                whine W_CHECK_BIND_VALS;
            }
            \@mappings;
        }
    };
    return $mappings unless wantarray;
    return @{$mappings};
}

sub bind_param {
    my $self     = shift;
    my %bindings = do {
        if ( my $placeholders = $self->_attr->{'Placeholders'} ) {
            if ( $_[0] =~ m/^[\:\$\?]?(?<bind_id>\d+)$/ ) {
                ( $+{'bind_id'} => $_[1] )
            } else {
                my $prefixed = $_[0] =~ m/^[\:\$\?]/ ? $_[0] : ":$_[0]";
                map { ( $_ => $_[1] ) } grep { $placeholders->{$_} eq $prefixed } keys %{$placeholders};
            }
        } else {
            ( $_[0] => $_[1] );
        }
    };
    unless (%bindings) {
        return unless $DBIx::Squirrel::STRICT_PARAM_CHECK;
        throw E_UNKNOWN_PLACEHOLDER, $_[0];
    }
    $self->SUPER::bind_param(%bindings);
    return \%bindings unless wantarray;
    return %bindings;
}

BEGIN {
    *iterate   = *it   = sub { DBIx::Squirrel::it->new(@_) };
    *resultset = *rs   = sub { DBIx::Squirrel::rs->new(@_) };
    *iterator  = *itor = sub { $_[0]->_attr->{'Iterator'} };
}

1;
