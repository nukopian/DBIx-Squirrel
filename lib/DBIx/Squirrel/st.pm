use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::st;

BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::st::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::st::ISA     = 'DBI::st';
}

use namespace::autoclean;
use DBIx::Squirrel::util qw/throw whine/;

use constant E_INVALID_PLACEHOLDER => 'Cannot bind invalid placeholder (%s)';
use constant W_ODD_NUMBER_OF_ARGS  => 'Check bind values match placeholder scheme';

our $FINISH_ACTIVE_BEFORE_EXECUTE = !!1;

sub _private {
    my $self = shift;
    return
      unless ref($self);
    $self->{private_ekorn} = {}
      unless defined($self->{private_ekorn});
    unless (@_) {
        return $self->{private_ekorn}, $self
          if wantarray;
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

sub _placeholder_mappings {
    my $placeholders = shift;
    my @mappings     = do {
        if (_positional_placeholders($placeholders)) {
            map {($placeholders->{$_} => $_[$_ - 1])} keys(%{$placeholders});
        }
        else {
            if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                whine W_ODD_NUMBER_OF_ARGS
                  unless @{$_[0]} % 2 == 0;
                @{$_[0]};
            }
            elsif (UNIVERSAL::isa($_[0], 'HASH')) {
                %{$_[0]};
            }
            else {
                whine W_ODD_NUMBER_OF_ARGS
                  unless @_ % 2 == 0;
                @_;
            }
        }
    };
    return @mappings
      if wantarray;
    return \@mappings;
}

sub _positional_placeholders {
    my $placeholders = shift;
    return
      unless UNIVERSAL::isa($placeholders, 'HASH');
    my @placeholders                    = values(%{$placeholders});
    my $total_count                     = @placeholders;
    my $count                           = grep {m/^[\:\$\?]\d+$/} @placeholders;
    my $all_positional_placeholders = $count == $total_count;
    return $placeholders
      if $all_positional_placeholders;
    return;
}

sub bind_param {
    my($attr, $self) = shift->_private;
    my($bind_param, $bind_value, @bind_attr) = @_;
    my @bind_param_args = do {
        if (my $placeholders = $attr->{Placeholders}) {
            if ($bind_param =~ m/^[\:\$\?]?(?<bind_id>\d+)$/) {
                $+{bind_id}, $bind_value, @bind_attr;
            }
            else {
                if ($bind_param =~ m/^[\:\$\?]/) {
                    map  {($_, $bind_value, @bind_attr)}
                    grep {$placeholders->{$_} eq $bind_param}
                      keys(%{$placeholders});
                }
                else {
                    map  {($_, $bind_value, @bind_attr)}
                    grep {$placeholders->{$_} eq ":$bind_param"}
                      keys(%{$placeholders});
                }
            }
        }
        else {
            $bind_param, $bind_value, @bind_attr;
        }
    };
    return unless $self->SUPER::bind_param(@bind_param_args);
    return @bind_param_args
      if wantarray;
    return \@bind_param_args;
}

sub bind {
    my($attr, $self) = shift->_private;
    if (@_) {
        my $placeholders = $attr->{Placeholders};
        if ($placeholders && !_positional_placeholders($placeholders)) {
            if (my %kv = @{_placeholder_mappings($placeholders, @_)}) {
                while (my($k, $v) = each(%kv)) {
                    if ($k =~ m/^[\:\$\?]?(?<bind_id>\d+)$/) {
                        throw E_INVALID_PLACEHOLDER, $k
                          unless $+{bind_id};
                        $self->bind_param($+{bind_id}, $v);
                    }
                    else {
                        $self->bind_param($k, $v);
                    }
                }
            }
        }
        else {
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
    }
    return $self;
}

sub execute {
    my $self = shift;
    if ($FINISH_ACTIVE_BEFORE_EXECUTE) {
        $self->finish if $self->{Active};
    }
    $self->bind(@_) if @_;
    return $self->SUPER::execute;
}

sub iterate {
    return DBIx::Squirrel::it->new(@_);
}

BEGIN {
    *iterator = *it = \&iterate;
}

sub results {
    return DBIx::Squirrel::rs->new(@_);
}

BEGIN {
    *resultset = *rs = \&results;
}

1;
