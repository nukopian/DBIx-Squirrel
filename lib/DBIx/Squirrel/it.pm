use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::it;

use namespace::autoclean;
use Data::Alias  qw/alias/;
use Scalar::Util qw/weaken/;

BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::it::VERSION             = $DBIx::Squirrel::VERSION;
    $DBIx::Squirrel::it::DEFAULT_SLICE       = [];                         # Faster!
    $DBIx::Squirrel::it::DEFAULT_BUFFER_SIZE = 2;                          # Initial buffer size and autoscaling increment
    $DBIx::Squirrel::it::BUFFER_SIZE_LIMIT   = 64;                         # Absolute maximum buffersize
}

use DBIx::Squirrel::util qw/throw whine/;

use constant E_BAD_STH         => 'Expected a statement handle object';
use constant E_BAD_SLICE       => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_BUFFER_SIZE => 'Maximum row count must be an integer greater than zero';
use constant E_EXP_BIND_VALUES => 'Expected bind values but none have been presented';
use constant W_MORE_ROWS       => 'Query would yield more than one row';

sub DEFAULT_SLICE () {$DBIx::Squirrel::it::DEFAULT_SLICE}

sub DEFAULT_BUFFER_SIZE () {$DBIx::Squirrel::it::DEFAULT_BUFFER_SIZE}

sub BUFFER_SIZE_LIMIT () {$DBIx::Squirrel::it::BUFFER_SIZE_LIMIT}

{
    my %attr_by_id;

    sub _private {
        my $self = shift;
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

sub DESTROY {
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local($., $@, $!, $^E, $?, $_);
    my $self = shift;
    $self->finish;
    $self->_private(undef);
    return;
}

sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my($transforms, $sth, @bind_values) = DBIx::Squirrel::util::cbargs(@_);
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
    $self->_private({
        id               => 0+ $self,
        sth              => $sth,
        init_bind_values => [@bind_values],
        init_transforms  => $transforms,
    });
    return do {$_ = $self};
}

sub _adjust_buffer_size {
    my($attr, $self) = shift->_private;
    $attr->{buffer_size} *= 2;
    $attr->{buffer_size}  = BUFFER_SIZE_LIMIT if $attr->{buffer_size} > BUFFER_SIZE_LIMIT;
    return $self;
}

sub _buffer_is_empty {
    my($attr, $self) = shift->_private;
    return $attr->{buffer} && @{$attr->{buffer}} < 1;
}

sub _clear_state {
    my($attr, $self) = shift->_private;
    foreach (
        qw/
        buffer
        buffer_size
        count_fetched
        excess
        first_fetch
        last_execute
        last_fetch
        /
    ) {
        delete $attr->{$_} if exists($attr->{$_});
    }
    return $self;
}

sub _fetch {
    my($attr, $self) = $_[0]->_private;
    if (@{$attr->{excess}} > 0) {
        my $head = shift(@{$attr->{excess}});
        $attr->{first_fetch} = $head unless $attr->{count_fetched}++;
        $attr->{last_fetch}  = $head;
        return do {$_ = $head};
    }
    return unless $self->{Active};
    if ($self->_buffer_is_empty) {
        undef $_;
        return unless $self->_fill_buffer;
        undef $_;
        return if $self->_buffer_is_empty;
    }
    my $transform = !!@{$attr->{transforms}};
    my @results   = map {$transform ? $self->_transform($_) : $_} shift(@{$attr->{buffer}});
    # Branch rather than recurse if our transformations yielded nothing.
    goto &_fetch if $transform && @results < 1;
    my($head, @tail) = @results;
    push @{$attr->{excess}}, @tail if @tail > 0;
    $attr->{first_fetch} = $head unless $attr->{count_fetched}++;
    $attr->{last_fetch}  = $head;
    return do {$_ = $head};
}

sub _fill_buffer {
    my($attr, $self) = shift->_private;
    $self->execute unless $self->{Executed};
    return         unless $self->{Active};
    my($sth, $slice, $buffer_size) = @{$attr}{qw/sth slice buffer_size/};
    my $rows = $sth->fetchall_arrayref($slice, $buffer_size);
    return 0 unless $rows;
    if ($attr->{buffer_size} < BUFFER_SIZE_LIMIT) {
        $self->_adjust_buffer_size if @{$rows} >= $attr->{buffer_size};
    }
    $attr->{buffer} = [defined($attr->{buffer}) ? (@{$attr->{buffer}}, @{$rows}) : @{$rows}];
    return scalar(@{$attr->{buffer}});
}

sub _init_state {
    my($attr, $self) = shift->_private;
    $self->_init_buffer;
    $self->_init_buffer_size;
    $self->_init_excess;
    $self->_init_count_fetched;
    return $self;
}

# Where rows are buffered until fetched.
sub _init_buffer {
    my($attr, $self) = shift->_private;
    my $key = 'buffer';
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{$key} = @_ ? shift : [];
    }
    return $self;
}

# Where excess results produced by transforms wait for collection.
sub _init_excess {
    my($attr, $self) = shift->_private;
    my $key = 'excess';
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{$key} = @_ ? shift : [];
    }
    return $self;
}

# How many rows to buffer at a time.
sub _init_buffer_size {
    my($attr, $self) = shift->_private;
    my $key = 'buffer_size';
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{$key} = @_ ? shift : DEFAULT_BUFFER_SIZE;
    }
    return $self;
}

# The total number of rows fetched (not buffered) since the last time the
# execute method was called.
sub _init_count_fetched {
    my($attr, $self) = shift->_private;
    my $key = 'count_fetched';
    if ($self->{NUM_OF_FIELDS}) {
        $attr->{$key} = @_ ? shift : 0;
    }
    return $self;
}

sub _transform {
    my($attr, $self) = shift->_private;
    return DBIx::Squirrel::util::transform($attr->{transforms}, @_);
}

sub all {
    my($attr, $self) = shift->_private;
    unless (defined($self->execute(@_))) {
        undef $_;
        return;
    }
    my @rows = $self->_fetch;
    push @rows, $_ while $self->_fetch;
    return @rows if wantarray;
    return \@rows;
}

sub buffer_size {
    my($attr, $self) = shift->_private;
    if (@_) {
        my $new_buffer_size = int(shift || DEFAULT_BUFFER_SIZE);
        throw E_BAD_BUFFER_SIZE
          if $new_buffer_size < DEFAULT_BUFFER_SIZE || $new_buffer_size > BUFFER_SIZE_LIMIT;
        $attr->{buffer_size} = $new_buffer_size;
        return $self;
    }
    else {
        $attr->{buffer_size} = DEFAULT_BUFFER_SIZE unless $attr->{buffer_size};
        return $attr->{buffer_size};
    }
}

sub buffer_size_slice {
    my $self = shift;
    return ($self->buffer_size, $self->slice) unless @_;
    return $self->slice(shift)->buffer_size(shift) if ref($_[0]);
    return $self->buffer_size(shift)->slice(shift);
}

sub count {
    my($attr, $self) = shift->_private;
    unless ($self->{Active} || $attr->{count_fetched}) {
        unless (defined($self->execute(@_))) {
            undef $_;
            return;
        }
    }
    while ($self->next) {;}
    return do {$_ = $attr->{count_fetched}};
}

sub execute {
    my($attr, $self) = shift->_private;
    my $sth = $attr->{sth};
    my($transforms, @bind_values) = DBIx::Squirrel::util::cbargs(@_);
    if (@{$transforms}) {
        $attr->{transforms} = $transforms;
    }
    else {
        $attr->{transforms} ||= [@{$attr->{init_transforms}}];
    }
    if (@bind_values) {
        $attr->{bind_values} = [@bind_values];
    }
    else {
        $attr->{bind_values} ||= [@{$attr->{init_bind_values}}];
    }
    throw E_EXP_BIND_VALUES if $self->{NUM_OF_PARAMS} && @{$attr->{bind_values}} < 1;
    $self->_clear_state;
    my $rv = $sth->execute(@{$attr->{bind_values}});
    return unless defined($rv);
    $self->_init_state;
    return do {$attr->{last_execute} = $rv};
}

sub first {
    my($attr, $self) = shift->_private;
    return do {
        if (exists($attr->{first_fetch})) {
            $_ = $attr->{first_fetch};
        }
        else {
            $_ = $self->_fetch;
        }
    };
}

sub iterate {
    my($attr, $self) = shift->_private;
    unless (defined($self->execute(@_))) {
        undef $_;
        return;
    }
    return do {$_ = $self}
}

sub last {
    my($attr, $self) = shift->_private;
    $self->count;
    return do {
        if (exists($attr->{last_fetch})) {
            $_ = $attr->{last_fetch};
        }
        else {
            undef $_;
            ();
        }
    };
}

sub next {
    return do {$_ = shift->_fetch};
}

sub previous {
    my($attr, $self) = shift->_private;
    return do {
        if (exists($attr->{last_fetch})) {
            $_ = $attr->{last_fetch};
        }
        else {
            undef $_;
            ();
        }
    };
}

BEGIN {
    *prev = \&previous;
}

sub remaining {
    my($attr, $self) = shift->_private;
    my @rows = $self->_fetch;
    push @rows, $_ while $self->_fetch;
    return @rows if wantarray;
    return \@rows;
}

sub reset {
    my $self = shift;
    $self->slice_buffer_size(@_) if @_;
    return unless defined($self->execute);
    return $self;
}

sub rows {
    my($attr, $self) = shift->_private;
    return $attr->{sth}->rows;
}

sub single {
    my($attr, $self) = shift->_private;
    unless (defined($self->execute(@_))) {
        undef $_;
        return;
    }
    $self->_fetch;
    whine W_MORE_ROWS if @{$attr->{buffer}} > 0;
    return do {
        if (exists($attr->{first_fetch})) {
            $_ = $attr->{first_fetch};
        }
        else {
            undef $_;
            ();
        }
    };
}

BEGIN {
    *one = *single;
}

sub slice {
    my($attr, $self) = shift->_private;
    if (@_) {
        my $new_slice = shift;
        if (ref($new_slice)) {
            if (UNIVERSAL::isa($new_slice, 'ARRAY')) {
                $attr->{slice} = $new_slice;
                return $self;
            }
            if (UNIVERSAL::isa($new_slice, 'HASH')) {
                $attr->{slice} = $new_slice;
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
    my $self = shift;
    return ($self->slice, $self->buffer_size) unless @_;
    return $self->slice(shift)->buffer_size(shift) if ref($_[0]);
    return $self->buffer_size(shift)->slice(shift);
}

sub sth {
    my($attr, $self) = shift->_private;
    return $attr->{sth};
}

1;
