use v5.36;

package DBIx::Squirrel::Helpers;

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(
    split_stages
    statement_study
    statement_trim
);

# A placeholder in any of the styles DBIx::Squirrel accepts: "?", ":" or
# "$", followed by a position or a name.
my $PLACEHOLDER = qr/[:\$?]\w+\b/x;

# Split the trailing code-references off a list; return them in an array
# reference, and the rest.
sub split_stages (@args) {
    my $n = @args;
    while ($n && is_coderef($args[$n - 1])) { $n -= 1 }
    my @stages = splice @args, $n;
    return \@stages, @args;
}


# Remove " -- " comments, and the blank space around each line, from a
# statement; return what's left, or an empty string if it was all blank.
sub statement_trim ($statement) {
    $statement //= '';
    $statement        =~ s/\s+--\s+.*$//gmx;
    $statement        =~ s/^[[:blank:]\r\n]+//gmx;
    $statement        =~ s/[[:blank:]\r\n]+$//gmx;
    return $statement =~ m/\S/x ? $statement : '';
}


# Study a statement; return a map of its placeholders' positions, from 1,
# to their names, the statement with each placeholder rewritten as "?",
# and the statement as trimmed. Return nothing if the statement is blank.
sub statement_study ($statement) {
    my $trimmed = statement_trim($statement);
    return unless length $trimmed;
    my @names        = $trimmed =~ m/($PLACEHOLDER)/gx;
    my %placeholders = map { ($_ + 1 => $names[$_]) } keys @names;
    (my $normalised = $trimmed) =~ s/$PLACEHOLDER/?/gx;
    return \%placeholders, $normalised, $trimmed;
}

1;
