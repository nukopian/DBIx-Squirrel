use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The reference's index lists every module, A to Z, and what callers use
# from each, A to Z, a heading each, as Ekorn's does (roadmap 2026-0039).
# This keeps it in step with the code: each module has an entry; each
# name a public module exports, and each public method it defines, is
# listed, but for those named internal below; each name listed is one
# the module can call; each says "By default." or "On request." as it's
# exported, and ends with a link; Tooling names each of its tags; and an
# internal module lists nothing. An author test, as the reference isn't
# in the distribution.

use B          qw();
use File::Find qw();

my $REFERENCE = 'docs/REFERENCE.md';
skip_all "the reference isn't here" unless -e $REFERENCE;

# Modules for DBIx::Squirrel's own use: their entries list nothing.
my %INTERNAL_MODULE = map { $_ => 1 } qw(
    DBIx::Squirrel::Placeholders
    DBIx::Squirrel::Util
);

# Functions and methods of public modules that are for the modules' own
# use, as the reference says, so not listed.
my %INTERNAL = (
    'DBIx::Squirrel::Context' => [qw(statement_context within)],
    'DBIx::Squirrel::Errors'  => [qw(at_caller failed in_method)],
    'DBIx::Squirrel::Result'  => [qw(class_for)],
);


# Return the key a name sorts by: in any case, with one starting with a
# symbol last.
sub sort_key ($name) {
    my $key = lc $name;
    $key = "\x{ffff}$key" if $key =~ s( \A [^a-z0-9:]+ )()x;
    return $key;
}


# Return the index's entries, in order: each a module's name, the text
# saying what it is, and its names, in order, each with its text.
sub index_entries () {
    open my $in, '<', $REFERENCE or die "Can't read $REFERENCE: $!";
    my $text = do { local $/; <$in> };
    close $in;
    my($index) = $text =~ m( ^\#\#\ Index\n (.*) \z )xms
        or die "No index in $REFERENCE";
    my @entries;
    for my $block (split m( (?= ^\#\#\#\  ) )xm, $index) {
        my($module, $about, $rest)
            = $block =~ m( \A \#\#\#\ (\S+) \n (.*?) (?: ^ (\#\#\#\#\ .*) | \z ) )xms
            or next;
        my @names = map { [m( \A \#\#\#\#\ (\S+) \n (.*) \z )xs] }
            split m( (?= ^\#\#\#\#\  ) )xm, $rest // '';
        push @entries, {module => $module, about => $about, names => \@names};
    }
    return @entries;
}


# Return the module each file under lib is: .pm and .pod alike.
sub modules () {
    my @files;
    File::Find::find(
        sub { push @files, $File::Find::name if m( \. (?: pm | pod ) \z )x },
        'lib',
    );
    return sort map { s( \A lib/ | \. \w+ \z )()xgr =~ s( / )(::)xgr } @files;
}


# Return a module's public names: what it exports, and the subs it
# defines, but for import and those starting with _.
sub public_names ($module) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my %names = map { $_ => 1 } @{ "${module}::EXPORT" },
        @{ "${module}::EXPORT_OK" };
    for my $name (keys %{ "${module}::" }) {
        my $code = *{ "${module}::$name" }{CODE} or next;
        next if $name eq 'import' || $name =~ m( \A _ )x;
        $names{$name} = 1
            if B::svref_2object($code)->GV->STASH->NAME eq $module;
    }
    delete @names{@{ $INTERNAL{$module} // [] }};
    return sort keys %names;
}


my @entries = index_entries();
my @modules = modules();

is [map { $_->{module} } @entries],
    [sort { sort_key($a) cmp sort_key($b) } @modules],
    'each module has an entry, A to Z';

for my $entry (@entries) {
    my $module = $entry->{module};
    my @names  = map { $_->[0] } @{ $entry->{names} };
    is \@names, [sort { sort_key($a) cmp sort_key($b) } @names],
        "$module: its names A to Z";
    is [
        map  { $_->[0] }
        grep { $_->[1] !~ m( \s See \s+ \[ [^\]]+ \] \( \#[^\)]+ \) \. \s* \z )xs }
            @{ $entry->{names} }
        ],
        [], "$module: each name ends with a link to where it's described";
}

for my $entry (@entries) {
    my($module, $about) = @$entry{qw(module about)};
    my %listed = map { $_->[0] => $_->[1] } @{ $entry->{names} };
    if ($module =~ m( ::Manual:: )x || $INTERNAL_MODULE{$module}) {
        is [sort keys %listed], [], "$module: lists nothing";
        next;
    }
    (my $file = "$module.pm") =~ s( :: )(/)xg;
    require $file;
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)

    # Tooling lists no names, but says what its tags are.
    if ($module eq 'DBIx::Squirrel::Tooling') {
        is [sort keys %listed], [], "$module: lists no names";
        my @tags = sort keys %{ "${module}::EXPORT_TAGS" };
        is [grep { $about !~ m( `:\Q$_\E` )x } @tags], [], "$module: names each tag";
        next;
    }

    is [grep { !$listed{$_} } public_names($module)], [],
        "$module: lists every public name";
    is [grep { !$module->can($_) } sort keys %listed], [],
        "$module: lists only names it has";

    # An exported name it lists says how; a name exported by default is
    # so on request too.
    my %default = map { $_ => 1 } grep { $listed{$_} } @{ "${module}::EXPORT" };
    my %request = map { $_ => 1 } grep { $listed{$_} } @{ "${module}::EXPORT_OK" };
    is [grep { $listed{$_} !~ m( \s By \s+ default \. )x } sort keys %default], [],
        "$module: says which are exported by default";
    my @on_request = grep { !$default{$_} } sort keys %request;
    is [grep { $listed{$_} !~ m( \s On \s+ request \. )x } @on_request], [],
        "$module: says which are exported on request";
}

done_testing;
