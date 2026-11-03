use v5.36;

package DBIx::Squirrel::Helpers;

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(
    split_stages
    study_statement
    trim_statement
);

# Remove the blank space from around a statement; return what's left, or
# an empty string if it was all blank.
sub trim_statement ($statement) {
    return ($statement // '') =~ s/ \A \s+ | \s+ \z //gxr;
}

# Study a statement; return a map of its placeholders' positions, from 1,
# to their names, the statement with each placeholder rewritten as "?",
# and the statement as trimmed. Return nothing if the statement is blank.
sub study_statement ($statement) {
    my $trimmed = trim_statement($statement);
    return unless length $trimmed;

    # What isn't SQL code, and is stepped over unchanged: quoted strings and
    # identifiers, comments, and PostgreSQL's dollar-quoted bodies.
    state $QUOTED  = qr( ' (?: [^'] | '' )* ' | " (?: [^"] | "" )* " | ` [^`]* ` )x;
    state $COMMENT = qr( -- [^\n]* | /\* .*? \*/ )xs;
    state $DOLLARS = qr( \$ (?<tag> (?: [A-Za-z_]\w* )? ) \$ .*? \$ \k<tag> \$ )xs;
    state $NOT_SQL = qr( $QUOTED | $COMMENT | $DOLLARS )x;

    # A placeholder: "?", "?" and a position, or ":" or "$" and a position or
    # a name; not after a colon, as in a cast, or inside an identifier.
    state $PLACEHOLDER = qr( (?<! [:\w\$] ) (?: \? \d* | [:\$] \w+ ) )x;

    my @placeholders;
    my $normalised = $trimmed =~ s(
        (?<not_sql> $NOT_SQL ) | (?<placeholder> $PLACEHOLDER )
    )(
        if (exists $+{not_sql}) {
            $+{not_sql};
        }
        else {
            push @placeholders, $+{placeholder};
            '?';
        }
    )gerx;

    my %positions = map { ($_ + 1 => $placeholders[$_]) } keys @placeholders;
    return \%positions, $normalised, $trimmed;
}

# Split the trailing code-references off a list; return them in an array
# reference, and the rest.
sub split_stages (@args) {
    my $n = @args;
    while ($n && is_coderef($args[$n - 1])) { $n -= 1 }
    my @stages = splice @args, $n;
    return \@stages, @args;
}


1;
