use 5.010_001;
use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::it;

BEGIN {
    require DBIx::Squirrel unless %DBIx::Squirrel::;
    $DBIx::Squirrel::it::VERSION             = $DBIx::Squirrel::VERSION;
    $DBIx::Squirrel::it::DEFAULT_SLICE       = [];                         # Faster!
    $DBIx::Squirrel::it::DEFAULT_BUFFER_SIZE = 2;                          # Initial buffer size and autoscaling increment
    $DBIx::Squirrel::it::BUFFER_SIZE_LIMIT   = 64;                         # Absolute maximum buffersize
}

use namespace::autoclean;
use Data::Alias  qw/alias/;
use Scalar::Util qw/weaken looks_like_number/;
use Sub::Name;
use DBIx::Squirrel::util qw/part_args throw transform whine/;

use constant E_BAD_STH         => 'Expected a statement handle object';
use constant E_BAD_SLICE       => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_BUFFER_SIZE => 'Maximum row count must be an integer greater than zero';
use constant E_EXP_BIND_VALUES => 'Expected bind values but none have been presented';
use constant W_MORE_ROWS       => 'Query would yield more than one result';
use constant E_EXP_ARRAY_REF   => 'Expected an ARRAY-REF';

sub DEFAULT_SLICE () {$DBIx::Squirrel::it::DEFAULT_SLICE}

sub DEFAULT_BUFFER_SIZE () {$DBIx::Squirrel::it::DEFAULT_BUFFER_SIZE}

sub BUFFER_SIZE_LIMIT () {$DBIx::Squirrel::it::BUFFER_SIZE_LIMIT}

sub NOTHING {
    $_ = undef;
    return;
}

sub DESTROY {
    return if DBIx::Squirrel::util::global_destruct_phase();
    local($., $@, $!, $^E, $?, $_);
    my $self = shift();
    $self->_private_state_clear;
    $self->_private_state(undef);
    return;
}

sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my($transforms, $sth, @bind_values) = part_args(@_);
    throw E_BAD_STH unless UNIVERSAL::isa($sth, 'DBIx::Squirrel::st');
    my $self = bless({}, $class);
    alias $self->{$_} = $sth->{$_} foreach qw/
      Active
      Executed
      NUM_OF_FIELDS
      NUM_OF_PARAMS
      NAME
      NAME_lc
      NAME_uc
      NAME_hash
      NAME_lc_hash
      NAME_uc_hash
      TYPE
      PRECISION
      SCALE
      NULLABLE
      CursorName
      Database
      Statement
      ParamValues
      ParamTypes
      ParamArrays
      RowsInCache
      /;
    $self->_private_state({
        sth                 => $sth,
        bind_values_initial => [@bind_values],
        transforms_initial  => $transforms,
    });
    return do {$_ = $self};
}

sub _buffer_charge {
    my($attr, $self) = $_[0]->_private_state;
    unless ($self->{Executed}) {
        return unless defined($self->execute);
    }
    return unless $self->{Active};
    my($sth, $slice, $buffer_size) = @{$attr}{qw/sth slice buffer_size/};
    my $rows = $sth->fetchall_arrayref($slice, $buffer_size);
    return 0 unless $rows;
    unless ($attr->{buffer_size_fixed}) {
        if ($attr->{buffer_size} < BUFFER_SIZE_LIMIT) {
            $self->_buffer_size_auto_adjust if @{$rows} >= $attr->{buffer_size};
        }
    }
    $attr->{buffer} = [defined($attr->{buffer}) ? (@{$attr->{buffer}}, @{$rows}) : @{$rows}];
    return scalar(@{$attr->{buffer}});
}

sub _buffer_empty {
    my($attr, $self) = $_[0]->_private_state;
    return $attr->{buffer} && @{$attr->{buffer}} < 1;
}

# Where rows are buffered until fetched.
sub _buffer_init {
    my($attr, $self) = $_[0]->_private_state;
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{buffer} = [];
    }
    return $self;
}

sub _buffer_size_auto_adjust {
    my($attr, $self) = $_[0]->_private_state;
    $attr->{buffer_size} *= 2;
    $attr->{buffer_size}  = BUFFER_SIZE_LIMIT if $attr->{buffer_size} > BUFFER_SIZE_LIMIT;
    return $self;
}

# How many rows to buffer at a time.
sub _buffer_size_init {
    my($attr, $self) = $_[0]->_private_state;
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{buffer_size}       ||= DEFAULT_BUFFER_SIZE;
        $attr->{buffer_size_fixed} ||= !!0;
    }
    return $self;
}

# The total number of rows fetched since execute was called.
sub _results_count_init {
    my($attr, $self) = $_[0]->_private_state;
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{results_count} = 0;
    }
    return $self;
}

sub _results_fetch {
    my($attr, $self) = $_[0]->_private_state;
    return $self->_results_pending_fetch if $self->_results_pending;
    return unless $self->{Active};
    if ($self->_buffer_empty) {
        return unless $self->_buffer_charge;
    }
    my $result = shift(@{$attr->{buffer}});
    my($results, $transformed) = $self->_results_transform($result);
    goto &_results_fetch if $transformed && !@{$results};
    $result = shift(@{$results});
    $self->_results_pending_push($results) if @{$results};
    $attr->{results_first} = $result unless $attr->{results_count}++;
    $attr->{results_last}  = $result;
    return do {$_ = $result};
}

sub _results_pending {
    my($attr, $self) = $_[0]->_private_state;
    return unless defined($attr->{results_pending});
    return !!@{$attr->{results_pending}};
}

sub _results_pending_fetch {
    my($attr, $self) = $_[0]->_private_state;
    return unless defined($attr->{results_pending});
    my $result = shift(@{$attr->{results_pending}});
    $attr->{results_first} = $result unless $attr->{results_count}++;
    $attr->{results_last}  = $result;
    return do {$_ = $result};
}

sub _results_pending_push {
    my($attr, $self) = shift->_private_state;
    return unless @_;
    my $results = shift();
    return                        unless UNIVERSAL::isa($results, 'ARRAY');
    $attr->{results_pending} = [] unless defined($attr->{results_pending});
    push @{$attr->{results_pending}}, @{$results};
    return $self;
}

# Seemingly pointless, here, but intended to be overridden in subclasses.
sub _results_prep_for_transform {$_[1]}

sub _results_transform {
    my($attr, $self) = shift->_private_state;
    my $result    = $self->_results_prep_for_transform(shift);
    my $transform = !!@{$attr->{transforms}};
    my @results   = do {
        if ($transform) {
            map {transform($attr->{transforms}, $self->_results_prep_for_transform($_))} $result;
        }
        else {
            $result;
        }
    };
    return \@results, $transform if wantarray;
    return \@results;
}

{
    my %attr_by_id;

    sub _private_state {
        my $self = shift();
        return unless ref($self);
        my $id   = 0+ $self;
        my $attr = do {
            $attr_by_id{$id} = {} unless defined($attr_by_id{$id});
            $attr_by_id{$id};
        };
        unless (@_) {
            return $attr, $self if wantarray;
            return $attr;
        }
        unless (defined($_[0])) {
            delete $attr_by_id{$id};
            shift;
        }
        if (@_) {
            $attr_by_id{$id} = {} unless defined($attr_by_id{$id});
            if (UNIVERSAL::isa($_[0], 'HASH')) {
                $attr_by_id{$id} = {%{$attr}, %{$_[0]}};
            }
            elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
                $attr_by_id{$id} = {%{$attr}, @{$_[0]}};
            }
            else {
                $attr_by_id{$id} = {%{$attr}, @_};
            }
        }
        return $self;
    }
}

sub _private_state_clear {
    my($attr, $self) = $_[0]->_private_state;
    delete $attr->{$_} foreach grep {exists($attr->{$_})} qw/
      buffer
      execute_returned
      results_pending
      results_count
      results_first
      results_last
      /;
    return $self;
}

sub _private_state_init {
    $_[0]->_buffer_init;
    $_[0]->_buffer_size_init;
    $_[0]->_results_count_init;
}

sub _private_state_reset {
    $_[0]->_private_state_clear;
    goto &_private_state_init;
}

sub all {
    return NOTHING unless defined($_[0]->execute(@_));
    return $_[0]->remaining;
}

sub buffer_size {
    my($attr, $self) = shift->_private_state;
    if (@_) {
        throw E_BAD_BUFFER_SIZE unless looks_like_number($_[0]);
        throw E_BAD_BUFFER_SIZE if $_[0] < DEFAULT_BUFFER_SIZE || $_[0] > BUFFER_SIZE_LIMIT;
        $attr->{buffer_size}       = shift();
        $attr->{buffer_size_fixed} = !!1;
        return $self;
    }
    else {
        $attr->{buffer_size} = DEFAULT_BUFFER_SIZE unless defined($attr->{buffer_size});
        return $attr->{buffer_size};
    }
}

sub buffer_size_slice {
    my $self = shift();
    return $self->buffer_size, $self->slice unless @_;
    return $self->slice(shift)->buffer_size(shift) if ref($_[0]);
    return $self->buffer_size(shift)->slice(shift);
}

sub count {
    my($attr, $self) = $_[0]->_private_state;
    unless ($self->{Executed}) {
        return NOTHING unless defined($self->execute);
    }
    while (defined($self->_results_fetch)) {;}
    return do {$_ = $attr->{results_count}};
}

sub count_fetched {
    my($attr, $self) = $_[0]->_private_state;
    unless ($self->{Executed}) {
        return NOTHING unless defined($self->execute);
    }
    return do {$_ = $attr->{results_count}};
}

sub execute {
    my($attr, $self) = shift->_private_state;
    my $sth = $attr->{sth};
    my($transforms, @bind_values) = part_args(@_);
    if (@{$transforms}) {
        $attr->{transforms} = [@{$attr->{transforms_initial}}, @{$transforms}];
    }
    else {
        $attr->{transforms} ||= [@{$attr->{transforms_initial}}];
    }
    if (@bind_values) {
        $attr->{bind_values} = [@bind_values];
    }
    else {
        $attr->{bind_values} ||= [@{$attr->{bind_values_initial}}];
    }
    throw E_EXP_BIND_VALUES if $self->{NUM_OF_PARAMS} && @{$attr->{bind_values}} < 1;
    $self->_private_state_reset;
    return do {$_ = $attr->{execute_returned} = $sth->execute(@{$attr->{bind_values}})};
}

sub first {
    my($attr, $self) = $_[0]->_private_state;
    unless ($self->{Executed}) {
        return NOTHING unless defined($self->execute);
    }
    return do {$_ = exists($attr->{results_first}) ? $attr->{results_first} : $self->_results_fetch};
}

sub iterate {
    my $self = shift();
    return NOTHING unless defined($self->execute(@_));
    return do {$_ = $self};
}

sub reset {
    my $self = $_[0];
    $self->execute;
    return $self;
}

sub last {
    my($attr, $self) = $_[0]->_private_state;
    unless ($self->{Executed}) {
        return NOTHING unless defined($self->execute);
        while (defined($self->_results_fetch)) {;}
    }
    return do {$_ = $attr->{results_last}};
}

sub last_fetched {
    my($attr, $self) = $_[0]->_private_state;
    unless ($self->{Executed}) {
        $self->execute;
        return NOTHING;
    }
    return do {$_ = $attr->{results_last}};
}

sub next {
    my $self = $_[0];
    unless ($self->{Executed}) {
        return NOTHING unless defined($self->execute);
    }
    return do {$_ = $self->_results_fetch};
}

sub remaining {
    my $self = $_[0];
    unless ($self->{Executed}) {
        return NOTHING unless defined($self->execute);
    }
    my @rows;
    push @rows, $_ while defined($self->_results_fetch);
    return @rows if wantarray;
    return \@rows;
}

sub rows {$_[0]->sth->rows}

sub single {
    my($attr, $self) = $_[0]->_private_state;
    return NOTHING unless defined($self->execute);
    return NOTHING unless defined($self->_results_fetch);
    whine W_MORE_ROWS if @{$attr->{buffer}};
    return do {$_ = exists($attr->{results_first}) ? $attr->{results_first} : ()};
}

BEGIN {
    *one = subname(one => \&single);
}

sub slice {
    my($attr, $self) = shift->_private_state;
    if (@_) {
        if (ref($_[0])) {
            if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                $attr->{slice} = shift();
                return $self;
            }
            if (UNIVERSAL::isa($_[0], 'HASH')) {
                $attr->{slice} = shift();
                return $self;
            }
        }
        throw E_BAD_SLICE;
    }
    else {
        $attr->{slice} = DEFAULT_SLICE unless $attr->{slice};
        return $attr->{slice};
    }
}

sub slice_buffer_size {
    my $self = shift();
    return $self->slice, $self->buffer_size unless @_;
    return $self->slice(shift)->buffer_size(shift) if ref($_[0]);
    return $self->buffer_size(shift)->slice(shift);
}

sub sth {$_[0]->_private_state->{sth}}

1;
