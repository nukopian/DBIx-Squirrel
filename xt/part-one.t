use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Find qw(find);

# Each document comes in two parts: Part 1 is DBIx::Squirrel, complete,
# and Part 2 is Ekorn::Pipeline, by choice (roadmap 2026-0052). This
# keeps the line between them (its D5): in a document with a "Part 2:
# With Ekorn::Pipeline" heading, a "Part 1: DBIx::Squirrel" heading
# comes first, and nothing before the Part 2 heading names Ekorn, in
# code or in text, or DBIx::Squirrel::Tooling, or one of Ekorn's names,
# in code or as code in the text. So a reader learns Ekorn::Pipeline
# exists only after Part 1.
#
# Ekorn's names are those DBIx::Squirrel::Tooling exports that none of
# DBIx::Squirrel's own modules does, as it imports them from Ekorn's
# (its D2), worked out here, so a name Ekorn adds is caught with no
# change to this file. The attributes named ekorn_, such as ekorn_slice,
# are DBIx::Squirrel's own, as is the word "stage" or "pipeline" in
# the text: 1.x had both.

my @DOCS = grep { -e } qw(
    docs/next/README.pod
    docs/next/HOWTO.md
    docs/next/REFERENCE.md
);

my $PART_1 = qr( \A (?: =head2 | \#\# ) \s+ Part\ 1:\ DBIx::Squirrel \s* \z )x;
my $PART_2
    = qr( \A (?: =head2 | \#\# ) \s+ Part\ 2:\ With\ Ekorn::Pipeline \s* \z )x;

# Return the names DBIx::Squirrel::Tooling exports from Ekorn's modules.
sub ekorn_names () {
    my @own;
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return unless m( \.pm \z )x;
                my $module = s( \A lib/ )()xr =~ s( \.pm \z )()xr =~ s( / )(::)xgr;
                push @own, $module unless $module eq 'DBIx::Squirrel::Tooling';
            },
        },
        'lib/DBIx/Squirrel',
    );
    my %ours  = map { $_ => 1 } map { exports($_) } @own;
    my @names = sort grep { !$ours{$_} } exports('DBIx::Squirrel::Tooling');
    return @names;
}

# Return the names a module exports, by default or on request.
sub exports ($module) {
    eval "require $module; 1" or die $@;    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    no strict 'refs';                       ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return @{ "${module}::EXPORT" }, @{ "${module}::EXPORT_OK" };
}

# Return a document's Part 1, as paragraphs, each the line it starts at,
# whether it's code, and its text; or nothing, if it has no Part 2.
sub part_one ($file) {
    open my $in, '<:encoding(UTF-8)', $file or die "Can't read $file: $!";
    my @lines = <$in>;
    close $in;
    chomp @lines;
    my $pod = $file =~ m( \.pod \z )x;
    my(@paragraphs, $fenced);
    for my $n (1 .. @lines) {
        my $line = $lines[$n - 1];
        return @paragraphs if $line =~ $PART_2;
        if (!$pod && $line =~ m( \A ``` )x) {
            $fenced = !$fenced;
            push @paragraphs, [$n + 1, 1, ''] if $fenced;
            next;
        }
        if ($line !~ m( \S )x) {
            push @paragraphs, [$n + 1, 0, '']
                unless $fenced || (@paragraphs && $paragraphs[-1][2] eq '');
            next;
        }
        my $code = $fenced || ($pod && $line =~ m( \A \s )x);
        push @paragraphs, [$n, $code, '']
            if !@paragraphs || $paragraphs[-1][1] != $code;
        $paragraphs[-1][2] .= "$line\n";
    }
    return;
}

# Return what a paragraph names of Ekorn's.
sub named ($code, $text, $names) {
    my @named;
    push @named, 'Ekorn' if $text =~ m( \b Ekorn \b )x;
    push @named, 'DBIx::Squirrel::Tooling'
        if $text =~ m( DBIx::Squirrel::Tooling )x;
    my @code;
    if ($code) {
        @code = map { s( (?: \A | \s ) \# \s .* \z )()xr } split m( \n )x, $text;
    }
    else {
        @code = (
            $text =~ m( C <{2,} \s+ (.*?) \s+ >{2,} )xgs,
            $text =~ m( C < ([^<>]*) > )xg,
            $text =~ m( ` ([^`]+) ` )xg,
        );
    }
    for my $name (@$names) {
        push @named, $name
            if grep { m( (?<! [\$\@\%\w>:-] ) \b \Q$name\E \b (?! \s* => ) )x } @code;
    }
    return @named;
}

skip_all 'no document in docs/next/ has a Part 2'
    unless grep { part_one($_) } @DOCS;

my @names = ekorn_names();
ok scalar @names, "Ekorn's names are known: @names";

for my $doc (@DOCS) {
    my @paragraphs = part_one($doc) or next;
    subtest $doc => sub {
        ok + (grep { $_->[2] =~ $PART_1 } @paragraphs), 'Part 1 has its heading';
        my @found;
        for my $paragraph (@paragraphs) {
            my($line, $code, $text) = @$paragraph;
            push @found, map { "line $line: $_" } named($code, $text, \@names);
        }
        is \@found, [], "Part 1 names nothing of Ekorn's";
    };
}

done_testing;
