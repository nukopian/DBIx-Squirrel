use v5.36;

package WorkerChecks::Hooks;

# A trial, not DBIx::Squirrel's code: Storable hooks on DBIx::Squirrel's
# row classes, so a row makes its class as it's thawed in a perl that
# never ran its query. Loading this installs them, in the parent and, as
# the blocks below are named from it, in each worker before its first
# value.
#
# Storable finds STORABLE_thaw by the row's class, which doesn't exist
# in a fresh perl; before failing, Storable requires the class. An @INC
# hook answers that require for any "Base::Row_<16 hex>" by making it a
# subclass of Base, so it inherits STORABLE_thaw, which then makes the
# class's accessors from the column names frozen with the row.

use DBIx::Squirrel;
use WorkerChecks;

# Each row class's column names, as given to class_for: the trial keeps
# them, as DBIx::Squirrel::Result doesn't yet.
my %names_of;

{
    no warnings qw(redefine);    ## no critic (TestingAndDebugging::ProhibitNoWarnings): the trial wraps class_for
    my $class_for = \&DBIx::Squirrel::Result::class_for;
    *DBIx::Squirrel::Result::class_for = sub ($base, $names) {
        my $class = $class_for->($base, $names);
        $names_of{$class} //= [@$names];
        return $class;
    };
}

our $FROZEN = 0;
our $THAWED = 0;


sub DBIx::Squirrel::Result::STORABLE_freeze ($self, $cloning) {
    my $names = $names_of{ref $self}
        // die "WorkerChecks::Hooks: no column names for ${\ ref $self}\n";
    $FROZEN++;
    return ('', [@$self], $names);
}


sub DBIx::Squirrel::Result::STORABLE_thaw (
    $self,   $cloning, $serialized,
    $values, $names,
) {
    my($base) = ref($self) =~ m( \A (.+) ::Row_ [0-9a-f]{16} \z )x
        or die "WorkerChecks::Hooks: not a row class: ${\ ref $self}\n";
    my $class = $base->class_for($names);
    die "WorkerChecks::Hooks: $class made, not ${\ ref $self}\n"
        unless $class eq ref $self;
    @$self = @$values;
    $THAWED++;
    return;
}


# The @INC hook: source for a row class that's only its base.
my $row_class = sub ($hook, $file) {
    my($base_file) = $file =~ m( \A (.+) /Row_ [0-9a-f]{16} \.pm \z )x
        or return;
    (my $class = $file)     =~ s( \.pm \z )()x;
    $class                  =~ s( / )(::)gx;
    (my $base = $base_file) =~ s( / )(::)gx;
    return unless $base->isa('DBIx::Squirrel::Result');
    my $source = "package $class; our \@ISA = ('$base'); 1;\n";
    return \$source;
};
push @INC, $row_class unless grep { ref $_ && $_ == $row_class } @INC;


# Blocks named from here, so a worker loads this module, and the hooks,
# before its first value.
sub seen ($value, @state) { return WorkerChecks::seen($value, @state) }
sub echo ($value, @state) { return $value }


# How many rows this process froze and thawed through the hooks.
sub counts ($value, @) { return [$$, $FROZEN, $THAWED] }

1;
