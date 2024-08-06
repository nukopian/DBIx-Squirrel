package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::rs;
use strict;
no strict 'refs';
use warnings;

BEGIN {
    require DBIx::Squirrel
      unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBIx::Squirrel::it';
}

use namespace::autoclean;
use Scalar::Util 'weaken';
use Sub::Name 'subname';

sub _fetch_row {
    my ( $attr, $self ) = shift->_attr;

    return if $self->_no_more_rows;

    if ( $self->_is_empty ) {
        return unless $self->_fetch;
    }

    my ( $head, @tail ) = @{ $attr->{'buffer'} };

    $attr->{'buffer'} = \@tail;
    $attr->{'row_count'} += 1;

    if ( @{ $attr->{'callbacks'} } ) {
        return $self->_transform( $self->_bless($head) );
    }

    return $self->_bless($head);
}

sub _bless {
    my $self = shift;

    return unless ref $self;

    my ( $row_class, $row ) = ( $self->row_class, @_ );
    my $result_class = $self->result_class;
    my $resultset_fn = $row_class . '::resultset';
    my $rs_fn        = $row_class . '::rs';

    unless ( defined &{$rs_fn} ) {
        undef &{$rs_fn};
        undef &{$resultset_fn};

        *{$resultset_fn} = *{$rs_fn} = do {
            weaken( my $rs = $self );
            subname( $rs_fn, sub {$rs} );
        };

        @{ $row_class . '::ISA' } = $result_class;
    }

    return $row_class->new($row);
}

sub _undef_autoloaded_accessors {
    my $self = shift;

    undef &{$_} for @{ $self->row_class . '::AUTOLOAD_ACCESSORS' };

    return $self;
}

sub DESTROY {
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    local ( $., $@, $!, $^E, $?, $_ );
    my $self      = shift;
    my $row_class = $self->row_class;

    if ( %{ $row_class . '::' } ) {
        $self->_undef_autoloaded_accessors;
    }

    undef &{ $row_class . '::rs' };
    undef &{ $row_class . '::resultset' };
    undef *{$row_class};

    return $self->SUPER::DESTROY;
}

sub slice {
    my ( $attr, $self ) = shift->_attr;
    my $slice = shift;
    my $old   = defined $attr->{'slice'} ? $attr->{'slice'} : '';

    $self->SUPER::slice($slice);

    if ( my $new = defined $attr->{'slice'} ? $attr->{'slice'} : '' ) {
        if ( ref $new ne ref $old && %{ $self->row_class . '::' } ) {
            $self->_undef_autoloaded_accessors;
        }
    }

    return $self;
}

sub row_class { sprintf 'DBIx::Squirrel::rs_0x%x', 0+ $_[0]; }

BEGIN {
    *row_base_class = *result_class = sub () { 'DBIx::Squirrel::rc'; }
}

1;
