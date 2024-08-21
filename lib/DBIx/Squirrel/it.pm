use Modern::Perl;

package    # hide from PAUSE
  DBIx::Squirrel::it;

BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::it::VERSION         = $DBIx::Squirrel::VERSION;
    $DBIx::Squirrel::it::DEFAULT_SLICE   = [];                         # Faster!
    $DBIx::Squirrel::it::DEFAULT_MAXROWS = 2;                          # Initial buffer size and autoscaling increment
    $DBIx::Squirrel::it::BUF_MULT        = 2;                          # Autoscaling factor, 0 to disable autoscaling together
    $DBIx::Squirrel::it::BUF_MAXROWS     = 16;                         # Absolute maximum buffersize
}

use namespace::autoclean;
use Data::Dumper::Concise;
use Scalar::Util         qw/weaken/;
use DBIx::Squirrel::util qw/cbargs throw transform whine/;

use constant E_BAD_SLICE   => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_MAXROWS => 'Maximum row count must be an integer greater than zero';
use constant W_MORE_ROWS   => 'Query returned more than one row';

sub DEFAULT_SLICE () {$DBIx::Squirrel::it::DEFAULT_SLICE}

sub DEFAULT_MAXROWS () {$DBIx::Squirrel::it::DEFAULT_MAXROWS}

sub BUF_MULT () {$DBIx::Squirrel::it::BUF_MULT}

sub BUF_MAXROWS () {$DBIx::Squirrel::it::BUF_MAXROWS}

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

sub new {
    my($callbacks, $class, $sth, @bindvals) = cbargs(@_);
    return unless UNIVERSAL::isa($sth, 'DBI::st');
    my $self = {};
    bless $self, ref($class) || $class;
    for my $k (keys(%{$sth})) {
        if (ref($sth->{$k})) {
            weaken($self->{$k} = $sth->{$k});
        }
        else {
            $self->{$k} = $sth->{$k};
        }
    }
    $self->_private({
        id        => 0+ $self,
        st        => $sth->_private({Iterator => $self}),
        bindvals  => [@bindvals],
        callbacks => $callbacks,
        slice     => $self->_slice->{Slice},
        maxrows   => $self->_maxrows->{MaxRows},
    });
    $self->finish;
    return do {$_ = $self};
}

sub all {
    my $self = shift;
    $self->reset();
    my @rows = $self->first();
    push @rows, $self->remaining();
    return @rows if wantarray;
    return \@rows;
}

sub count {
    my $self = shift;
    $self->reset();
    my $count = 0;
    $count += 1 while $self->next();
    return do {$_ = $count};
}

sub execute {
    my($attr, $self) = shift->_private;
    my $sth = $attr->{st};
    return unless $sth;
    $self->reset if $attr->{executed} || $attr->{finished};
    if (defined($sth->execute(@_ ? @_ : @{$attr->{bindvals}}))) {
        $attr->{executed}  = !!1;
        $attr->{row_count} = 0;
        if ($sth->{NUM_OF_FIELDS}) {
            my $count = $self->_fetch;
            $attr->{finished} = !$count;
            return do {$_ = $count || '0E0'};
        }
        $attr->{finished} = !!1;
        return do {$_ = '0E0'};
    }
    $attr->{executed} = !!0;
    $attr->{finished} = !!0;
    return do {$_ = undef};
}

sub executed {
    return shift->_private->{executed};
}

sub find {
    my($attr, $self) = shift->_private;
    $self->reset();
    my $row;
    if ($self->execute(@_)) {
        if ($row = $self->_fetch_row()) {
            $attr->{row_count} = 1;
        }
        else {
            $attr->{row_count} = 0;
        }
        $self->reset();
    }
    return do {$_ = $row};
}

sub finish {
    my($attr, $self) = shift->_private;
    if ($attr->{st}) {
        $attr->{st}->finish if $attr->{st}{Active};
    }
    $attr->{finished}     = !!0;
    $attr->{executed}     = !!0;
    $attr->{rows_fetched} = 0;
    $attr->{buffer}       = undef;
    $attr->{buf_incr_by}  = DEFAULT_MAXROWS;
    $attr->{buf_mult_by}  = BUF_MULT && BUF_MULT < 11 ? BUF_MULT : 0;
    $attr->{buf_limit}    = BUF_MAXROWS || $attr->{buf_incr_by};
    return do {$_ = $self};
}

sub finished {
    return shift->_private->{finished};
}

BEGIN {
    *done = \&finished;
}

sub first {
    my($attr, $self) = shift->_private;
    if (@_ || $attr->{executed} || $attr->{st}{Active}) {
        $self->reset(@_);
    }
    my $row = $self->_fetch_row;
    $attr->{row_count} = 1 if $row;
    return do {$_ = $row};
}

sub iterate {
    my $self = shift;
    return unless defined($self->execute(@_));
    return do {$_ = $self};
}

sub _transform {
    my $self = shift;
    return transform($self->_private->{callbacks}, @_);
}

sub _auto_level_maxrows {
    my($attr, $self) = shift->_private;
    return !!0 unless $attr->{buf_limit};
    my $new_maxrows = do {
        if ($attr->{buf_mult_by} && $attr->{buf_mult_by} > 1) {
            $attr->{maxrows} * $attr->{buf_mult_by};
        }
        elsif ($attr->{buf_incr_by} > 0) {
            $attr->{maxrows} + $attr->{buf_incr_by};
        }
        else {
            $attr->{maxrows};
        }
    };
    if ($attr->{maxrows} < $new_maxrows && $new_maxrows < $attr->{buf_limit}) {
        $attr->{maxrows} = $new_maxrows;
        return !!1;
    }
    return !!0;
}

sub _fetch {
    my($attr, $self) = shift->_private;
    my($sth, $slice, $maxrows, $buf_limit) = @{$attr}{qw/st slice maxrows buf_limit/};
    unless ($sth && $sth->{Active}) {
        $attr->{finished} = !!1;
        return;
    }
    my $r = $sth->fetchall_arrayref($slice, $maxrows || 1);
    my $c = $r ? @{$r} : 0;
    unless ($c) {
        $attr->{finished} = !!1;
        return 0;
    }
    if ($attr->{buffer}) {
        $attr->{buffer} = [@{$attr->{buffer}}, @{$r}];
    }
    else {
        $attr->{buffer} = $r;
    }
    if ($c == $maxrows && $maxrows < $buf_limit && $self->_auto_level_maxrows()) {
        ($maxrows, $buf_limit) = @{$attr}{qw/maxrows buf_limit/};
    }
    return do {$attr->{rows_fetched} += $c};
}

sub _is_empty {
    my $attr = shift->_private;
    return !@{$attr->{buffer}};
}

sub _no_more_rows {
    my($attr, $self) = shift->_private;
    $self->execute unless $attr->{executed};
    return $attr->{finished};
}

sub _fetch_row {
    my($attr, $self) = shift->_private;
    return if $self->_no_more_rows;
    return if $self->_is_empty && !$self->_fetch;
    my($head, @tail) = @{$attr->{buffer}};
    $attr->{buffer}     = \@tail;
    $attr->{row_count} += 1;
    return $self->_transform($head) if @{$attr->{callbacks}};
    return $head;
}

sub next {
    my $self = shift;
    $self->_slice_maxrows(@_) if @_;
    return do {$_ = $self->_fetch_row};
}

sub remaining {
    my($attr, $self) = shift->_private;
    my @rows;
    unless ($self->_no_more_rows()) {
        until ($attr->{finished}) {
            push @rows, $self->_fetch_row();
        }
        $attr->{row_count} += scalar(@rows);
        $self->reset;
    }
    return @rows if wantarray;
    return \@rows;
}

sub _maxrows {
    my $self = shift;
    throw E_BAD_MAXROWS if ref($_[0]);
    $self->{MaxRows} = int(shift || DEFAULT_MAXROWS);
    return $self->_private({maxrows => $self->{MaxRows}});
}

sub _slice {
    my $self = shift;
    unless (@_) {
        $self->{Slice} = DEFAULT_SLICE unless defined($self->{Slice});
        return $self->_private({slice => $self->{Slice}});
    }
    if (defined($_[0])) {
        if (UNIVERSAL::isa($_[0], 'ARRAY')) {
            $self->{Slice} = [];
        }
        elsif (UNIVERSAL::isa($_[0], 'HASH')) {
            $self->{Slice} = {};
        }
        else {
            throw E_BAD_SLICE;
        }
    }
    else {
        $self->{Slice} = DEFAULT_SLICE;
    }
    return $self->_private({slice => $self->{Slice}});
}

sub _slice_maxrows {
    my $self = shift;
    return $self unless @_;
    return $self->_slice(shift)->_maxrows(shift) if ref($_[0]);
    return $self->_maxrows(shift)->_slice(shift);
}

BEGIN {
    *_maxrows_slice = *_slice_maxrows;    # Don't make me think!
}

sub reset {
    my $self = shift;
    $self->_slice_maxrows(@_) if @_;
    return do {$_ = $self->finish};
}

sub rows {
    return shift->_private->{st}->rows;
}

sub single {
    my($attr, $self) = shift->_private;
    $self->reset();
    my $row;
    if (my $count = $self->execute(@_)) {
        whine W_MORE_ROWS if $count > 1;
        if ($row = $self->_fetch_row()) {
            $attr->{row_count} = 1;
        }
        else {
            $attr->{row_count} = 0;
        }
        $self->reset();
    }
    return do {$_ = $row};
}

BEGIN {
    *one = *single;
}

sub statement_handle {
    return shift->_private->{st};
}

BEGIN {
    *sth = \&statement_handle;
}

sub DESTROY {
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local($., $@, $!, $^E, $?, $_);
    my $self = shift;
    $self->finish;
    $self->_private(undef);
    return;
}

1;
