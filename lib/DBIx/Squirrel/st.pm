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
    local($_);
    my $self         = shift;
    my $placeholders = $self->_private_state->{Placeholders};
    my @placeholders = values(%{$placeholders});
    my $total_count  = @placeholders;
    my $count        = grep {m/^[\:\$\?]\d+$/} @placeholders;
    return $placeholders if $count == $total_count;
    return;
}

sub _placeholders_map_to_values {
    local($_);
    my $self       = shift;
    my $positional = $self->_placeholders_confirm_positional;
    my @mappings   = do {
        if ($positional) {
            map {($positional->{$_} => $_[$_ - 1])} keys(%{$positional});
        }
        else {
            if (UNIVERSAL::isa($_[0], 'HASH')) {
                %{$_[0]};
            }
            else {
                if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                    whine W_ODD_NUMBER_OF_ARGS unless @{$_[0]} && @{$_[0]} % 2 == 0;
                    @{$_[0]};
                }
                else {
                    whine W_ODD_NUMBER_OF_ARGS unless @_ && @_ % 2 == 0;
                    @_;
                }
            }
        }
    };
    return @mappings if wantarray;
    return \@mappings;
}

sub bind {
    local($_);
    my $self = shift;
    if (@_) {
        if ($self->_placeholders_confirm_positional) {
            if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                $self->bind_param($_, $_[0][$_ - 1]) for 1 .. scalar(@{$_[0]});
            }
            else {
                $self->bind_param($_, $_[$_ - 1]) for 1 .. scalar(@_);
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
    local($_);
    my $self = shift;
    my @args = do {
        my($param, $value, @attr) = @_;
        my $placeholders = $self->_private_state->{Placeholders};
        if ($placeholders) {
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
