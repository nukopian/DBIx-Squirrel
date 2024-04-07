package    # hide from PAUSE
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
use DBIx::Squirrel::util (
    'cbargs',
    'throw',
    'transform',
    'whine',
);

{
    my $r;

    sub ROOT_CLASS
    {
        ( $r = __PACKAGE__ ) =~ s/::\w+$// unless defined $r;
        return wantarray ? ( RootClass => $r ) : $r;
    }
}

our $DEFAULT_SLICE = [];

sub DEFAULT_SLICE
{
    return $DEFAULT_SLICE;
}

our $DEFAULT_MAXROWS = 1;    # Initial buffer size and autoscaling increment

sub DEFAULT_MAXROWS
{
    return $DEFAULT_MAXROWS;
}

our $BUF_MULT = 2;           # Autoscaling factor, 0 to disable autoscaling together

sub BUF_MULT
{
    return $BUF_MULT;
}

our $BUF_MAXROWS = 8;        # Absolute maximum buffersize

sub BUF_MAXROWS
{
    return $BUF_MAXROWS;
}

BEGIN {
    my %att;

    sub _att
    {
        return unless ref $_[0];
        my ( $att, $id, $self, @t ) = (
            do {
                if ( defined $att{ 0+ $_[0] } ) {
                    $att{ 0+ $_[0] };
                } else {
                    $att{ 0+ $_[0] } = {};
                }
            },
            0+ $_[0],
            @_
        );
        return wantarray ? ( $att, $self ) : $att unless @t;
        if ( @t == 1 && !defined $t[0] ) {
            delete $att{$id};
            return;
        }
        $att{$id} = {
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

    sub _id
    {
        return unless ref $_[0];
        return wantarray ? ( 0+ $_[0], @_ ) : 0+ $_[0];
    }
}

sub _fetch_row
{
    return if $_[0]->_no_more_rows;
    my ( $att, $self ) = $_[0]->_att;
    return if $self->_is_empty && !$self->_fetch;
    my ( $row, @t ) = @{ $att->{'bu'} };
    $att->{'bu'} = \@t;
    $att->{'rc'} += 1;
    return @{ $att->{'cb'} } ? $self->_transform($row) : $row;
}

sub _no_more_rows
{
    my ( $att, $self ) = $_[0]->_att;
    $self->execute unless $att->{'ex'};
    return !!$att->{'fi'};
}

sub _is_empty
{
    return $_[0]->_att->{'bu'} ? !@{ $_[0]->_att->{'bu'} } : 1;
}

sub _fetch
{
    my ( $att, $self ) = $_[0]->_att;
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

sub _auto_manage_maxrows
{
    my $att = $_[0]->_att;
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

sub _transform
{
    return transform( $_[0]->_att->{'cb'}, @_[ 1 .. $#_ ] );
}

sub DESTROY
{
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    local ( $., $@, $!, $^E, $?, $_ );
    $_[0]->finish->_att(undef);
    return;
}

sub new
{
    my ( $callbacks, $class, $sth, @bindvals ) = cbargs(@_);
    return unless UNIVERSAL::isa( $sth, 'DBI::st' );
    my ( $id, $self ) = ( bless {}, ref $class || $class )->_id;
    return $_ = $self->finish->_att(
        {
            'id' => $id,
            'bv' => \@bindvals,
            'cb' => $callbacks,
            'sl' => $self->set_slice->{'Slice'},
            'mr' => $self->set_maxrows->{'MaxRows'},
            'st' => $sth->_att( { 'Iterator' => $self } ),
        }
    );
}

sub execute
{
    my $att = $_[0]->_att;
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

sub find
{
    $_[0]->reset if my $row = do {
        $_[0]->execute( @_[ 1 .. $#_ ] ) ? $_[0]->_fetch_row : undef;
    };
    return $_ = $row;
}

sub single
{
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

BEGIN {
    sub head
    {
        my $att = $_[0]->_att;
        $_[0]->reset( @_[ 1 .. $#_ ] )
          if @_ > 1 || $att->{'ex'} || $att->{'st'}{'Active'};
        return $_ = $_[0]->_fetch_row;
    }

    *first = *head;
}

sub all
{
    my $rows = $_[0]->execute( @_[ 1 .. $#_ ] ) ? $_[0]->tail : [];
    return wantarray ? @{$rows} : $rows;
}

sub tail
{
    return if $_[0]->_no_more_rows;
    my $att = $_[0]->_att;
    $_[0]->reset if my $rows = do {
        my @rows;
        push @rows, $_[0]->_fetch_row until $att->{'fi'};
        $att->{'rc'} = @rows;
        \@rows;
    };
    return wantarray ? @{$rows} : $rows;
}

sub next
{
    $_[0]->set_slice_maxrows( @_[ 1 .. $#_ ] ) if @_ > 1;
    return $_ = $_[0]->_fetch_row;
}

sub count
{
    return $_ = scalar @{ $_[0]->all( @_[ 1 .. $#_ ] ) };
}

sub reset
{
    $_[0]->set_slice_maxrows( @_[ 1 .. $#_ ] ) if @_ > 1;
    return $_[0]->finish;
}

sub finish
{
    my ( $att, $self ) = $_[0]->_att;
    $att->{'st'}->finish if $att->{'st'} && $att->{'st'}{'Active'};
    $att->{'fi'} = undef;
    $att->{'ex'} = undef;
    $att->{'bu'} = undef;
    $att->{'rf'} = 0;
    $att->{'bi'} = $DEFAULT_MAXROWS;
    $att->{'bm'} = $BUF_MULT && $BUF_MULT < 11 ? $BUF_MULT : 0;
    $att->{'bl'} = $BUF_MAXROWS || $att->{'bi'};
    return $self;
}

BEGIN {
    sub set_slice_maxrows
    {
        return $_[0] unless @_ > 1;
        return ref $_[1]
          ? $_[0]->set_slice( $_[1] )->set_maxrows( $_[2] )
          : $_[0]->set_maxrows( $_[1] )->set_slice( $_[2] );
    }

    *set_maxrows_slice = *set_slice_maxrows;
}

sub set_slice
{
    if ( defined $_[1] ) {
        throw E_BAD_SLICE
          unless UNIVERSAL::isa( $_[1], 'ARRAY' )
          || UNIVERSAL::isa( $_[1], 'HASH' );
    }
    return $_[0]->_att(
        {
            'sl' => ( $_[0]->{'Slice'} = ( $_[1] // $DEFAULT_SLICE ) ),
        }
    );
}

sub set_maxrows
{
    if ( defined $_[1] ) {
        throw E_BAD_MAXROWS
          unless defined $_[1]
          && !ref $_[1]
          && int $_[1];
    }
    return $_[0]->_att(
        {
            'mr' => ( $_[0]->{'MaxRows'} = int( $_[1] // $DEFAULT_MAXROWS ) ),
        }
    );
}

BEGIN {
    sub rs
    {
        return $_[0]->sth->rs( @_[ 1 .. $#_ ] );
    }

    *resultset = *results = *rs;
}

BEGIN {
    sub sth
    {
        return $_[0]->_att->{'st'};
    }

    *statement_handle = *sth;
}

BEGIN {
    sub finished
    {
        return !!$_[0]->_att->{'fi'};
    }

    *done = *finished;
}

BEGIN {
    sub not_finished
    {
        return !$_[0]->_att->{'fi'};
    }

    *not_done = *not_finished;
}

BEGIN {
    sub executed
    {
        return !!$_[0]->_att->{'ex'};
    }

    *not_pending = *executed;
}

BEGIN {
    sub not_executed
    {
        return !$_[0]->_att->{'ex'};
    }

    *pending = *not_executed;
}

1;
