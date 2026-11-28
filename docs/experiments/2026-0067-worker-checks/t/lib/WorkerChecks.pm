use v5.36;

package WorkerChecks;

# Named functions for DBIx::Squirrel's checks of Ekorn-Pipeline's
# fresh-perl workers (Ekorn 2026-0065): blocks, init and done, which
# each worker loads by name. Loading this loads DBIx::Squirrel, as a
# caller's own module would.

use DBIx::Squirrel;


package WorkerChecks::Artist {    ## no critic (Modules::ProhibitMultiplePackages): a row class the workers load with the blocks
    our @ISA = 'DBIx::Squirrel::Result';
    sub shout ($self) { return uc $self->name }
}


# What a worker saw of a value: its pid, its class, whether it's a
# DBIx::Squirrel::Result, its id and name read by accessor (or the
# error), and the values in it, read without methods.
sub seen ($value, @) {
    my $class = ref $value;
    my $isa   = eval { $value->isa('DBIx::Squirrel::Result') } ? 1 : 0;
    my $name  = eval { $value->name }
        // do { my $e = $@; $e =~ s( \ at\ .* )()xs; "died: $e" };
    my $shout = eval { $value->shout };
    my @raw   = $class =~ m( HASH \z )x
        || eval { $value->isa('HASH') } ? @$value{qw(id name)} : @$value[0, 1];
    return [$$, $class, $isa, $name, $shout, @raw];
}


# The value, sent back.
sub echo ($value, @) {
    return $value;
}


# The id of an array, hash or row, read without methods.
sub id_of ($value) {
    return eval { $value->isa('HASH') }
        || ref $value eq 'HASH' ? $value->{id} : $value->[0];
}


sub id ($value, @) {
    return id_of($value);
}


# For once_per: the key, given back, with the pid it was seen in.
sub key ($key, @) {
    return [$$, $key];
}


# For init: make each row class named by [base class, column names], as
# DBIx::Squirrel::Results does as a run starts.
sub make_classes (@classes) {
    for my $class (@classes) {
        my($base, $names) = @$class;
        $base->class_for($names);
    }
    return;
}


# For init and done: a worker's own connection.
sub connect_db ($dsn) {
    return DBIx::Squirrel->connect(
        $dsn, undef, undef,
        {RaiseError => 1, PrintError => 0},
    );
}


sub disconnect_db ($dbh) {
    $dbh->disconnect;
    return;
}


my $count = 'SELECT COUNT(*) FROM probe_album WHERE artist_id = ?';

# A lookup for each value, on the worker's connection.
sub albums ($value, $dbh) {
    my $id = id_of($value);
    return [$id, scalar $dbh->selectrow_array($count, undef, $id)];
}


# A lookup for each key, for once_per.
sub albums_for_id ($id, $dbh) {
    return scalar $dbh->selectrow_array($count, undef, $id);
}


sub die_at_5 ($value, @) {
    my $id = id_of($value);
    die "boom at $id\n" if $id == 5;
    return $id;
}

1;
