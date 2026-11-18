use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The reference's index lists every module, A to Z, and what callers use
# from each, A to Z (roadmap 2026-0039). This keeps it in step with the
# code: each module has an entry; each name a public module exports, and
# each public method it defines, is listed, but for those named internal
# below; each name listed is one the module exports or can call; and an
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


# Return the index's entries, in order, each a module's name and the
# names it lists, in order: each row's first code, up to its arguments.
sub index_entries () {
    open my $in, '<', $REFERENCE or die "Can't read $REFERENCE: $!";
    my $text = do { local $/; <$in> };
    close $in;
    my($index) = $text =~ m( ^\#\#\ Index\n (.*) \z )xms
        or die "No index in $REFERENCE";
    my @entries;
    for my $block (split m( (?= ^\#\#\#\  ) )xm, $index) {
        my($module) = $block =~ m( \A \#\#\#\ (\S+) )x or next;
        my @names = $block =~ m( ^ \|\ \[ ` ( [^`]+ ) ` )xmg;
        push @entries, [$module, \@names];
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
my %listed  = map { $_->[0] => $_->[1] } @entries;
my @modules = modules();

is [map { $_->[0] } @entries],
    [sort { sort_key($a) cmp sort_key($b) } @modules],
    'each module has an entry, A to Z';

for my $entry (@entries) {
    my($module, $names) = @$entry;
    my @sorted = sort { sort_key($a) cmp sort_key($b) } @$names;
    is $names, \@sorted, "$module: its names A to Z";
}

for my $module (grep { m( \A DBIx::Squirrel (?: :: | \z ) )x } @modules) {
    my $names = $listed{$module} // next;
    if ($module =~ m( ::Manual:: )x || $INTERNAL_MODULE{$module}) {
        is $names, [], "$module: lists nothing";
        next;
    }
    (my $file = "$module.pm") =~ s( :: )(/)xg;
    require $file;

    # Tooling is listed by its tags, not the names they hold.
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my @public
        = $module eq 'DBIx::Squirrel::Tooling'
        ? map { ":$_" } keys %{ "${module}::EXPORT_TAGS" }
        : public_names($module);

    # A name as written, such as batch($n) or drop_if { ... }, is listed
    # as its name; one that's a usage, such as use ..., or an operator,
    # isn't a name.
    my %words = map { $_ => 1 } grep { defined }
        map { m( \A ( [\@:]? [A-Za-z_]\w* ) (?: \( | \  \{ | \z ) )x ? $1 : undef }
        @$names;
    is [grep { !$words{$_} } sort @public], [], "$module: lists every public name";

    my %public  = map { $_ => 1 } @public;
    my @unknown = grep {
        my $name = $_;
        !$public{$name}
            && !($name =~ m( \A \w+ \z )x      && $module->can($name))
            && !($name =~ m( \A \@ (\w+) \z )x && @{ "${module}::$1" })
    } sort keys %words;
    is \@unknown, [], "$module: lists only names it has";
}

done_testing;
