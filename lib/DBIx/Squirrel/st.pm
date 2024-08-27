use 5.010_001;
use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::st;

use Sub::Name;
use DBIx::Squirrel::util qw/throw whine/;
use namespace::clean;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    $DBIx::Squirrel::st::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::st::ISA     = qw/DBI::st/;
}

use constant E_INVALID_PLACEHOLDER => 'Cannot bind invalid placeholder (%s)';
use constant W_ODD_NUMBER_OF_ARGS  => 'Check bind values match placeholder scheme';

our $FINISH_ACTIVE_BEFORE_EXECUTE = !!1;

sub _private_state {
    my $self = shift;
    $self->{private_ekorn} = {} unless defined($self->{private_ekorn});
    unless (@_) {
        return $self->{private_ekorn}, $self if wantarray;
        return $self->{private_ekorn};
    }
    unless (defined($_[0])) {
        delete $self->{private_ekorn};
        shift;
    }
    if (@_) {
        if (UNIVERSAL::isa($_[0], 'HASH')) {
            $self->{private_ekorn} = {%{$self->{private_ekorn}}, %{$_[0]}};
        }
        elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
            $self->{private_ekorn} = {%{$self->{private_ekorn}}, @{$_[0]}};
        }
        else {
            $self->{private_ekorn} = {%{$self->{private_ekorn}}, @_};
        }
    }
    return $self;
}

sub _placeholders_confirm_positional {
    my($attr, $self) = shift->_private_state;
    my $placeholders = $attr->{Placeholders};
    my @placeholders = values(%{$placeholders});
    my $total_count  = scalar(@placeholders);
    my $count        = grep {m/^[\:\$\?]\d+$/} @placeholders;
    return $placeholders if $count == $total_count;
    return;
}

sub _placeholders_map_to_values {
    my($attr, $self) = shift->_private_state;
    my $placeholders = $attr->{Placeholders};
    my @mappings     = do {
        if ($self->_placeholders_confirm_positional) {
            map {($placeholders->{$_} => $_[$_ - 1])} keys(%{$placeholders});
        }
        else {
            if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                whine W_ODD_NUMBER_OF_ARGS unless @{$_[0]} % 2 == 0;
                @{$_[0]};
            }
            elsif (UNIVERSAL::isa($_[0], 'HASH')) {
                %{$_[0]};
            }
            else {
                whine W_ODD_NUMBER_OF_ARGS unless @_ % 2 == 0;
                @_;
            }
        }
    };
    return @mappings if wantarray;
    return \@mappings;
}

sub bind {
    my($attr, $self) = shift->_private_state;
    return unless my $placeholders = $attr->{Placeholders};
    if (@_) {
        if ($self->_placeholders_confirm_positional) {
            if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                for my $bind_id (1 .. scalar(@{$_[0]})) {
                    $self->bind_param($bind_id, $_[0][$bind_id - 1]);
                }
            }
            else {
                for my $bind_id (1 .. scalar(@_)) {
                    $self->bind_param($bind_id, $_[$bind_id - 1]);
                }
            }
        }
        else {
            if (my %kv = @{$self->_placeholders_map_to_values(@_)}) {
                while (my($k, $v) = each(%kv)) {
                    if ($k =~ m/^[\:\$\?]?(?<bind_id>\d+)$/) {
                        throw E_INVALID_PLACEHOLDER, $k unless $+{bind_id};
                        $self->bind_param($+{bind_id}, $v);
                    }
                    else {
                        $self->bind_param($k, $v);
                    }
                }
            }
        }
    }
    return $self;
}

sub bind_param {
    my($attr, $self) = shift->_private_state;
    my($param, $value, @attr) = @_;
    my @args = do {
        if (my $placeholders = $attr->{Placeholders}) {
            if ($param =~ m/^[\:\$\?]?(?<bind_id>\d+)$/) {
                $+{bind_id}, $value, @attr;
            }
            else {
                map {($_, $value, @attr)} do {
                    if ($param =~ m/^[\:\$\?]/) {
                        grep {$placeholders->{$_} eq $param} keys(%{$placeholders});
                    }
                    else {
                        grep {$placeholders->{$_} eq ":$param"} keys(%{$placeholders});
                    }
                };
            }
        }
        else {
            $param, $value, @attr;
        }
    };
    return unless $self->SUPER::bind_param(@args);
    return @args if wantarray;
    return \@args;
}

sub execute {
    my $self = shift;
    $self->finish   if $FINISH_ACTIVE_BEFORE_EXECUTE && $self->{Active};
    $self->bind(@_) if @_;
    return $self->SUPER::execute;
}

sub iterate {
    return DBIx::Squirrel::it->new(@_);
}

BEGIN {
    *iterator = subname(iterator => \&iterate);
    *itor     = subname(itor     => \&iterate);
    *it       = subname(it       => \&iterate);
}

sub results {
    return DBIx::Squirrel::rs->new(@_);
}

BEGIN {
    *resultset = subname(resultset => \&results);
    *rset      = subname(rset      => \&results);
    *rs        = subname(rs        => \&results);
}

1;
