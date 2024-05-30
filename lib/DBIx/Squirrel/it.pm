package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::it;
use strict;
use warnings;
use constant E_BAD_SLICE   => 'Slice must be a reference to an ARRAY or HASH';
use constant E_BAD_MAXROWS => 'Maximum row count must be an integer greater than zero';
use constant W_MORE_ROWS   => 'Query returned more than one row';

BEGIN {
    require DBIx::Squirrel
      unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
}

use namespace::autoclean;
use Data::Dumper::Concise;
use DBIx::Squirrel::util 'cbargs', 'throw', 'transform', 'whine';

{
    ( my $r = __PACKAGE__ ) =~ s/::\w+$//;

    sub ROOT_CLASS {
        return $r unless wantarray;
        return RootClass => $r;
    }
}

our $DEFAULT_SLICE = [];

sub DEFAULT_SLICE () { $DEFAULT_SLICE; }

our $DEFAULT_MAXROWS = 1;                                                                                                          # Initial buffer size and autoscaling increment

sub DEFAULT_MAXROWS () { $DEFAULT_MAXROWS; }

our $BUF_MULT = 2;                                                                                                                 # Autoscaling factor, 0 to disable autoscaling together

sub BUF_MULT () { $BUF_MULT; }

our $BUF_MAXROWS = 8;                                                                                                              # Absolute maximum buffersize

sub BUF_MAXROWS () { $BUF_MAXROWS; }

BEGIN {
    my %attr_by_id;

    sub _attr {
        my $self = shift;
        return unless ref $self;
        my $id   = 0+ $self;
        my $attr = do {
            if ( defined $attr_by_id{$id} ) {
                $attr_by_id{$id};
            } else {
                $attr_by_id{$id} = {};
            }
        };
        unless (@_) {
            return $attr unless wantarray;
            return $attr, $self;
        }
        unless ( defined $_[0] ) {
            delete $attr_by_id{$id};
            shift;
        }
        if (@_) {
            unless ( exists $attr_by_id{$id} ) {
                $attr_by_id{$id} = {};
            }
            if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                $attr_by_id{$id} = { %{$attr}, %{ $_[0] } };
            } elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                $attr_by_id{$id} = { %{$attr}, @{ $_[0] } };
            } else {
                $attr_by_id{$id} = { %{$attr}, @_ };
            }
        }
        return $self;
    }
}

sub _no_more_rows {
    my ( $attr, $self ) = shift->_attr;
    $self->execute unless $attr->{'executed'};
    return 1 if $attr->{'finished'};
    return 0;
}

sub _is_empty {
    my $attr = shift->_attr;
    return 0 if @{ $attr->{'buffer'} };
    return 1;
}

sub _auto_manage_maxrows {
    my ( $attr, $self ) = shift->_attr;
    return unless my $limit = $attr->{'buf_lim'};
    my $dirty;
    my $maxrows = $attr->{'maxrows'};
    my $new_mr  = do {
        if ( my $mul = $attr->{'buf_mul'} ) {
            if ( $mul > 1 ) {
                $dirty = 1;
                $maxrows * $mul;
            } else {
                if ( my $inc = $attr->{'buf_inc'} ) {
                    $dirty = 1;
                    $maxrows + $inc;
                }
            }
        } else {
            if ( my $inc = $attr->{'buf_inc'} ) {
                $dirty = 1;
                $maxrows + $inc;
            }
        }
    };
    if ( $dirty && $new_mr <= $limit ) {
        $attr->{'maxrows'} = $new_mr;
    }
    return !!$dirty;
}

sub _fetch {
    my ( $attr, $self ) = shift->_attr;
    my ( $sth, $slice, $maxrows, $buf_lim ) = @{$attr}{qw/st slice maxrows buf_lim/};
    unless ( $sth && $sth->{'Active'} ) {
        $attr->{'finished'} = 1;
        return;
    }
    my $r = $sth->fetchall_arrayref( $slice, $maxrows || 1 );
    my $c = $r ? @{$r} : 0;
    unless ( $r && $c ) {
        $attr->{'finished'} = 1;
        return 0;
    }
    if ( $attr->{'buffer'} ) {
        $attr->{'buffer'} = [ @{ $attr->{'buffer'} }, @{$r} ];
    } else {
        $attr->{'buffer'} = $r;
    }
    if ( $c == $maxrows && $maxrows < $buf_lim ) {
        ( $maxrows, $buf_lim ) = @{$attr}{qw/maxrows buf_lim/} if $self->_auto_manage_maxrows;
    }
    return $attr->{'rows_fetched'} += $c;
}

sub _transform {
    my $self = shift;
    return transform( $self->_attr->{'callbacks'}, @_ );
}

sub _fetch_row {
    my ( $attr, $self ) = shift->_attr;
    return if $self->_no_more_rows;
    return if $self->_is_empty && !$self->_fetch;
    my ( $head, @tail ) = @{ $attr->{'buffer'} };
    $attr->{'buffer'} = \@tail;
    $attr->{'row_count'} += 1;
    return $self->_transform($head) if @{ $attr->{'callbacks'} };
    return $head;
}

sub new {
    my ( $callbacks, $class_or_self, $sth, @bindvals ) = cbargs(@_);
    return unless UNIVERSAL::isa( $sth, 'DBI::st' );
    my $self = bless {}, ref $class_or_self || $class_or_self;
    return $_ = $self->finish->_attr(
        {   'id'        => 0+ $self,
            'st'        => $sth->_attr( { 'Iterator' => $self } ),
            'bindvals'  => [@bindvals],
            'callbacks' => $callbacks,
            'slice'     => $self->slice->{'Slice'},
            'maxrows'   => $self->maxrows->{'MaxRows'},
        }
    );
}

sub DESTROY {
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local ( $., $@, $!, $^E, $?, $_ );
    shift->finish->_attr(undef);
    return;
}

sub execute {
    my ( $attr, $self ) = shift->_attr;
    my $sth = $attr->{'st'};
    return unless $sth;
    if ( $attr->{'executed'} || $attr->{'finished'} ) {
        $self->reset;
    }
    $attr->{'executed'} = 1;
    if ( $sth->execute( @_ ? @_ : @{ $attr->{'bindvals'} } ) ) {
        $attr->{'executed'}  = 1;
        $attr->{'row_count'} = 0;
        if ( $sth->{'NUM_OF_FIELDS'} ) {
            my $count = $self->_fetch;
            $attr->{'finished'} = $count ? 0 : 1;
            return $_ = $count || '0E0';
        }
        $attr->{'finished'} = 1;
        return $_ = '0E0';
    }
    $attr->{'finished'} = 1;
    return $_ = undef;
}

sub count {
    return $_ = scalar @{ shift->all(@_) };
}

sub slice {
    my $self = shift;
    unless (@_) {
        unless ( defined $self->{'Slice'} ) {
            $self->{'Slice'} = $DEFAULT_SLICE;
        }
        return $self->_attr( { 'slice' => $self->{'Slice'} } );
    }
    if ( defined $_[0] ) {
        if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
            $self->{'Slice'} = [];
        } elsif ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
            $self->{'Slice'} = {};
        } else {
            throw E_BAD_SLICE;
        }
    } else {
        $self->{'Slice'} = $DEFAULT_SLICE;
    }
    return $self->_attr( { 'slice' => $self->{'Slice'} } );
}

sub maxrows {
    my $self = shift;
    throw E_BAD_MAXROWS if ref $_[0];
    $self->{'MaxRows'} = int( shift // $DEFAULT_MAXROWS );
    return $self->_attr( { 'maxrows' => $self->{'MaxRows'} } );
}

sub slice_maxrows {
    my $self = shift;
    return $self unless @_;
    return $self->slice(shift)->maxrows(shift) if ref $_[0];
    return $self->maxrows(shift)->slice(shift);
}

BEGIN { *maxrows_slice = *slice_maxrows }

sub next {
    my $self = shift;
    $self->slice_maxrows(@_) if @_;
    return $_ = $self->_fetch_row;
}

sub finish {
    my ( $attr, $self ) = shift->_attr;
    if ( $attr->{'st'} && $attr->{'st'}{'Active'} ) {
        $attr->{'st'}->finish;
    }
    $attr->{'finished'}     = undef;
    $attr->{'executed'}     = undef;
    $attr->{'buffer'}       = undef;
    $attr->{'rows_fetched'} = 0;
    $attr->{'buf_inc'}      = $DEFAULT_MAXROWS;
    $attr->{'buf_mul'}      = $BUF_MULT && $BUF_MULT < 11 ? $BUF_MULT : 0;
    $attr->{'buf_lim'}      = $BUF_MAXROWS || $attr->{'buf_inc'};
    return $self;
}

sub reset {
    my $self = shift;
    $self->slice_maxrows(@_) if @_;
    return $self->finish;
}

sub find {
    my ( $attr, $self ) = shift->_attr;
    my $row;
    if ( $self->execute(@_) ) {
        if ( $row = $self->_fetch_row ) {
            $attr->{'row_count'} = 1;
            $self->reset;
        } else {
            $attr->{'row_count'} = 0;
        }
    }
    return $_ = $row;
}

sub first {
    my ( $attr, $self ) = shift->_attr;
    if ( @_ || $attr->{'executed'} || $attr->{'st'}{'Active'} ) {
        $self->reset(@_);
    }
    my $row = $self->_fetch_row;
    $attr->{'row_count'} = 1 if $row;
    return $_ = $row;
}

sub single {
    my ( $attr, $self ) = shift->_attr;
    my $count = $self->execute(@_);
    my $row;
    if ($count) {
        whine W_MORE_ROWS if $count > 1;
        if ( $row = $self->_fetch_row ) {
            $attr->{'row_count'} = 1;
            $self->reset;
        }
    }
    return $_ = $row;
}

sub remaining {
    my ( $attr, $self ) = shift->_attr;
    my @rows;
    unless ( $self->_no_more_rows ) {
        until ( $attr->{'finished'} ) {
            push @rows, $self->_fetch_row;
        }
        $attr->{'row_count'} += scalar @rows;
        $self->reset if $attr->{'row_count'};
    }
    return \@rows unless wantarray;
    return @rows;
}

sub all {
    my $self = shift;
    my @rows;
    if ( $self->execute(@_) ) {
        push @rows, $self->remaining;
    }
    return \@rows unless wantarray;
    return @rows;
}

BEGIN {
    *resultset        = *rs           = sub { shift->sth->rs(@_) };
    *statement_handle = *sth          = sub { shift->_attr->{'st'} };
    *done             = *finished     = sub { !!shift->_attr->{'finished'} };
    *not_done         = *not_finished = sub { !shift->_attr->{'finished'} };
    *not_pending      = *executed     = sub { !!shift->_attr->{'executed'} };
    *pending          = *not_executed = sub { !shift->_attr->{'executed'} };
}

1;
