package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::rs;
use strict;
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

{
     ( my $r = __PACKAGE__ ) =~ s/::\w+$//;

    sub ROOT_CLASS {
        return $r unless wantarray;
        return RootClass => $r;
    }
}

sub _fetch_row {
    return if $_[0]->_no_more_rows;
    my ( $att, $self ) = $_[0]->_attr;
    if ( $self->_is_empty ) {
        return unless $self->_fetch;
    }
    my ( $row, @t ) = @{ $att->{'bu'} };
    $att->{'bu'} = \@t;
    $att->{'rc'} += 1;
    return @{ $att->{'cb'} }
      ? $self->_transform( $self->_bless($row) )
      : $self->_bless($row);
}

{
    no strict 'refs';

    sub _bless {
        return unless ref $_[0];
        my ( $row_class, $self, $row ) = ( $_[0]->row_class, @_ );
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
}

{
    no strict 'refs';

    sub _undef_autoloaded_accessors {
        undef &{$_} for @{ $_[0]->row_class . '::AUTOLOAD_ACCESSORS' };
        return $_[0];
    }
}

{
    no strict 'refs';

    sub DESTROY {
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        local ( $., $@, $!, $^E, $?, $_ );
        my $self      = $_[0];
        my $row_class = $self->row_class;
        if ( %{ $row_class . '::' } ) {
            $self->_undef_autoloaded_accessors;
        }
        undef &{ $row_class . '::rs' };
        undef &{ $row_class . '::resultset' };
        undef *{$row_class};
        return $self->SUPER::DESTROY;
    }
}

{
    no strict 'refs';

    sub set_slice {
        my ( $att, $self, $slice ) = ( $_[0]->_attr, @_[ 1 .. $#_ ] );
        my $old = defined $att->{'sl'} ? $att->{'sl'} : '';
        $self->SUPER::set_slice($slice);
        if ( my $new = defined $att->{'sl'} ? $att->{'sl'} : '' ) {
            $self->_undef_autoloaded_accessors
              if ref $new ne ref $old && %{ $self->row_class . '::' };
        }
        return $self;
    }
}

sub row_class {
    return sprintf 'DBIx::Squirrel::rs_0x%x', 0+ $_[0];
}

BEGIN {

    sub result_class {
        return 'DBIx::Squirrel::rc';
    }

    *row_base_class = *result_class;
}

1;
