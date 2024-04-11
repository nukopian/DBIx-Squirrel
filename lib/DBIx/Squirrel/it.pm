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

sub DEFAULT_SLICE {
    return $DEFAULT_SLICE;
}

our $DEFAULT_MAXROWS = 1;                                                                                                          # Initial buffer size and autoscaling increment

sub DEFAULT_MAXROWS {
    return $DEFAULT_MAXROWS;
}

our $BUF_MULT = 2;                                                                                                                 # Autoscaling factor, 0 to disable autoscaling together

sub BUF_MULT {
    return $BUF_MULT;
}

our $BUF_MAXROWS = 8;                                                                                                              # Absolute maximum buffersize

sub BUF_MAXROWS {
    return $BUF_MAXROWS;
}

BEGIN {
    my %attrs_by_id;

    sub _attr {
        my $self = shift;
        return unless ref $self;
        my $id    = 0+ $self;
        my $attrs = do {
            if ( defined $attrs_by_id{$id} ) {
                $attrs_by_id{$id};
            } else {
                $attrs_by_id{$id} = {};
            }
        };
        unless (@_) {
            return $attrs unless wantarray;
            return $attrs, $self;
        }
        unless ( defined $_[0] ) {
            delete $attrs_by_id{$id};
            shift;
        }
        if (@_) {
            unless ( exists $attrs_by_id{$id} ) {
                $attrs_by_id{$id} = {};
            }
            if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                $attrs_by_id{$id} = { %{$attrs}, %{ $_[0] } };
            } elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                $attrs_by_id{$id} = { %{$attrs}, @{ $_[0] } };
            } else {
                $attrs_by_id{$id} = { %{$attrs}, @_ };
            }
        }
        return $self;
    }
}

sub _fetch_row {
    return if $_[0]->_no_more_rows;
    my ( $att, $self ) = $_[0]->_attr;
    return if $self->_is_empty && !$self->_fetch;
    my ( $row, @t ) = @{ $att->{'bu'} };
    $att->{'bu'} = \@t;
    $att->{'rc'} += 1;
    return @{ $att->{'cb'} } ? $self->_transform($row) : $row;
}

sub _no_more_rows {
    my ( $att, $self ) = $_[0]->_attr;
    $self->execute unless $att->{'ex'};
    return !!$att->{'fi'};
}

sub _is_empty {
    return $_[0]->_attr->{'bu'} ? !@{ $_[0]->_attr->{'bu'} } : 1;
}

sub _fetch {
    my ( $att, $self ) = $_[0]->_attr;
    my ( $sth, $sl, $mr, $bl ) = @{$att}{qw/st sl mr bl/};
    unless ( $sth && $sth->{'Active'} ) {
        $att->{'fi'} = 1;
        return undef;
    }
    my $r = $sth->fetchall_arrayref( $sl, $mr || 1 );
    my $c = $r ? @{$r} : 0;
    unless ( $r && $c ) {
        $att->{'fi'} = 1;
        return 0;
    }
    $att->{'bu'} = ( $_ = $att->{'bu'} ) ? [ @{$_}, @{$r} ] : $r;
    if ( $c == $mr && $mr < $bl ) {
        ( $mr, $bl ) = @{$att}{qw/mr bl/} if $self->_auto_manage_maxrows;
    }
    return $att->{'rf'} += $c;
}

sub _auto_manage_maxrows {
    my $att = $_[0]->_attr;
    return undef unless my $limit = $att->{'bl'};
    my $dirty;
    my $mr     = $att->{'mr'};
    my $new_mr = do {
        if ( my $mul = $att->{'bm'} ) {
            if ( $mul > 1 ) {
                $dirty = 1;
                $mr * $mul;
            } else {
                if ( my $inc = $att->{'bi'} ) {
                    $dirty = 1;
                    $mr + $inc;
                }
            }
        } else {
            if ( my $inc = $att->{'bi'} ) {
                $dirty = 1;
                $mr + $inc;
            }
        }
    };
    $att->{'mr'} = $new_mr if $dirty && $new_mr <= $limit;
    return !!$dirty;
}

sub _transform {
    return transform( $_[0]->_attr->{'cb'}, @_[ 1 .. $#_ ] );
}

sub DESTROY {
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local ( $., $@, $!, $^E, $?, $_ );
    $_[0]->finish->_attr(undef);
    return;
}

sub new {
    my ( $callbacks, $class, $sth, @bindvals ) = cbargs(@_);
    return unless UNIVERSAL::isa( $sth, 'DBI::st' );
    my $self = bless {}, ref $class || $class;
    return $_ = $self->finish->_attr(
        {   'id' => 0+ $self,
            'bv' => \@bindvals,
            'cb' => $callbacks,
            'sl' => $self->set_slice->{'Slice'},
            'mr' => $self->set_maxrows->{'MaxRows'},
            'st' => $sth->_attr( { 'Iterator' => $self } ),
        }
    );
}

sub execute {
    my $att = $_[0]->_attr;
    return unless my $sth = $att->{'st'};
    $_[0]->reset if $att->{'ex'} || $att->{'fi'};
    return $_ = do {
        if ( $sth->execute( @_ > 1 ? @_[ 1 .. $#_ ] : @{ $att->{'bv'} } ) ) {
            $att->{'ex'} = 1;
            $att->{'rc'} = 0;
            if ( $sth->{NUM_OF_FIELDS} ) {
                my $count = $_[0]->_fetch;
                $att->{'fi'} = $count ? 0 : 1;
                $count || '0E0';
            } else {
                $att->{'fi'} = 1;
                '0E0';
            }
        } else {
            $att->{'ex'} = 1;
            $att->{'fi'} = 1;
            undef;
        }
    };
}

sub find {
    $_[0]->reset if my $row = do {
        $_[0]->execute( @_[ 1 .. $#_ ] ) ? $_[0]->_fetch_row : undef;
    };
    return $_ = $row;
}

sub single {
    $_[0]->reset if my $row = do {
        if ( my $count = $_[0]->execute( @_[ 1 .. $#_ ] ) ) {
            whine W_MORE_ROWS if $count > 1;
            $_[0]->_fetch_row;
        } else {
            undef;
        }
    };
    return $_ = $row;
}

sub all {
    my $self = shift;
    my $rows = $self->execute(@_) ? $self->tail : [];
    return $rows unless wantarray;
    return @{$rows};
}

sub tail {
    my $self = shift;
    return if $self->_no_more_rows;
    my $attr = $self->_attr;
    my @rows;
    push @rows, $self->_fetch_row until $attr->{'fi'};
    $attr->{'rc'} = @rows;
    if (@rows) {
        $self->reset;
    }
    return \@rows unless wantarray;
    return @rows;
}

sub next {
    my $self = shift;
    if (@_) {
        $self->set_slice_maxrows(@_);
    }
    return $_ = $self->_fetch_row;
}

sub count { $_ = scalar @{ shift->all(@_) } }

sub reset {
    my $self = shift;
    if (@_) {
        $self->set_slice_maxrows(@_);
    }
    return $self->finish;
}

sub finish {
    my ( $attr, $self ) = shift->_attr;
    if ( $attr->{'st'} && $attr->{'st'}{'Active'} ) {
        $attr->{'st'}->finish;
    }
    $attr->{'fi'} = undef;
    $attr->{'ex'} = undef;
    $attr->{'bu'} = undef;
    $attr->{'rf'} = 0;
    $attr->{'bi'} = $DEFAULT_MAXROWS;
    $attr->{'bm'} = $BUF_MULT && $BUF_MULT < 11 ? $BUF_MULT : 0;
    $attr->{'bl'} = $BUF_MAXROWS || $attr->{'bi'};
    return $self;
}

sub set_slice {
    my $self  = shift;
    my $slice = shift;
    if ( defined $slice ) {
        throw E_BAD_SLICE
          unless UNIVERSAL::isa( $slice, 'ARRAY' ) || UNIVERSAL::isa( $slice, 'HASH' );
    }
    $self->{'Slice'} = ( $slice // $DEFAULT_SLICE );
    return $self->_attr( { 'sl' => $self->{'Slice'} } );
}

sub set_maxrows {
    my $self  = shift;
    my $count = shift;
    if ( defined $count ) {
        throw E_BAD_MAXROWS unless !ref $count && int $count;
    }
    $self->{'MaxRows'} = int( $count // $DEFAULT_MAXROWS );
    return $self->_attr( { 'mr' => $self->{'MaxRows'} } );
}

BEGIN {
    *first = *head = sub {
        my $self = shift;
        my $attr = $self->_attr;
        if ( @_ || $attr->{'ex'} || $attr->{'st'}{'Active'} ) {
            $self->reset(@_);
        }
        return $_ = $self->_fetch_row;
    };

    *set_maxrows_slice = *set_slice_maxrows = sub {
        my $self = shift;
        return $self unless @_;
        if ( ref $_[0] ) {
            return $self->set_slice(shift)->set_maxrows(shift);
        } else {
            return $self->set_maxrows(shift)->set_slice(shift);
        }
    };

    *resultset        = *rs           = sub { shift->sth->rs(@_) };
    *statement_handle = *sth          = sub { shift->_attr->{'st'} };
    *done             = *finished     = sub { !!shift->_attr->{'fi'} };
    *not_done         = *not_finished = sub { !shift->_attr->{'fi'} };
    *not_pending      = *executed     = sub { !!shift->_attr->{'ex'} };
    *pending          = *not_executed = sub { !shift->_attr->{'ex'} };
}

1;
