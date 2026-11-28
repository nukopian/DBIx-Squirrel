use v5.36;

package WorkerChecks::Bare;

# A block that loads nothing of DBIx::Squirrel's, to measure what
# starting workers costs with Ekorn's modules alone.


sub id ($value, @) {
    return ref $value eq 'HASH' ? $value->{id} : $value->[0];
}

1;
