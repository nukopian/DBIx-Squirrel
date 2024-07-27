package                                                                                                                            # hide from PAUSE
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
    ( my $root = __PACKAGE__ ) =~ s/::\w+$//;

    sub RootClass {
        return $root unless wantarray;
        return RootClass => $root;
    }
}

sub connect {
    goto &_clone_connection if UNIVERSAL::isa( $_[1], 'DBI::db' );
    my $invocant   = shift;
    my $attributes = @_ && UNIVERSAL::isa( $_[$#_], 'HASH' ) ? pop : {};
    return $invocant->DBI::connect( @_, { %{$attributes}, __PACKAGE__->RootClass } );
}

sub connect_cached {
    my $invocant   = shift;
    my $attributes = @_ && UNIVERSAL::isa( $_[$#_], 'HASH' ) ? pop : {};
    return $invocant->DBI::connect_cached( @_, { %{$attributes}, __PACKAGE__->RootClass } );
}

sub _clone_connection {
    my $invocant = shift;
    return unless UNIVERSAL::isa( $_[0], 'DBI::db' );
    my $connection = shift;
    my $attributes = @_ && UNIVERSAL::isa( $_[$#_], 'HASH' ) ? pop : {};
    return $connection->clone( { %{$attributes}, __PACKAGE__->RootClass } );
}

1;
