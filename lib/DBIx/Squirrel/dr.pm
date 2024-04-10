package    # hide from PAUSE
  DBIx::Squirrel::dr;
use strict;
use warnings;

BEGIN {
    require DBIx::Squirrel
      unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBI::dr';
}

{
    my $r;

    sub ROOT_CLASS
    {
        ( $r = __PACKAGE__ ) =~ s/::\w+$// unless defined $r;
        return wantarray ? ( RootClass => $r ) : $r;
    }
}

sub _is_attr
{
    return UNIVERSAL::isa( $_[0], 'HASH' ) ? $_[0] : undef;
}

sub _is_dbh
{
    return UNIVERSAL::isa( $_[0], 'DBI::db' ) ? $_[0] : undef;
}

sub connect
{
    return _is_dbh( $_[1] ) ? &connect_clone : shift->DBI::connect(
          ( @_ && _is_attr( $_[$#_] ) )
        ? ( @_[ 0 .. $#_ - 1 ], { %{ $_[$#_] }, __PACKAGE__->ROOT_CLASS } )
        : ( @_,                 { __PACKAGE__->ROOT_CLASS } )
    );
}

sub connect_cached
{
    return shift->DBI::connect_cached(
          ( @_ && _is_attr( $_[$#_] ) )
        ? ( @_[ 0 .. $#_ - 1 ], { %{ $_[$#_] }, __PACKAGE__->ROOT_CLASS } )
        : ( @_,                 { __PACKAGE__->ROOT_CLASS } )
    );
}

sub connect_clone
{
    return undef unless _is_dbh( $_[1] );
    $_[1]->clone(
          ( @_ && _is_attr( $_[$#_] ) )
        ? ( { %{ $_[$#_] }, __PACKAGE__->ROOT_CLASS } )
        : ( { __PACKAGE__->ROOT_CLASS } )
    );
}

1;
