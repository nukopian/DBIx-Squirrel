use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Temp qw(tempdir);

# The POD's spelling, checked as Minilla's own release test,
# xt/minilla/spelling.t, checks it as `minil dist` builds the tarball,
# so that a word it doesn't know fails CI on the push that brings it,
# not the release. A word in the manuals failed only at the release
# before: v3.4.0's reference said "21st" (5d1801c), and Ekorn-Pipeline's
# v0.3.8, tagged before its tarball failed on "setlist", never reached
# CPAN. A word that's right but unknown goes in the stopwords of the
# file it's in: in docs/REFERENCE.md and docs/HOWTO.md, the
# <!-- stopwords: ... --> comment at the top, which scripts/manuals
# makes the manual's =for stopwords; in a module, its =for stopwords
# line. The new documents being written in docs/next/ are checked as
# the manuals will be made from them, by scripts/manuals' own
# conversion, so a construct it refuses fails too, and their README as
# it is (roadmap 2026-0052). CI's coverage job runs it, as it installs
# the cpanfile's develop modules, Test::Spellunker among them; elsewhere
# it's skipped without that module, saying so.


BEGIN {
    eval { require Test::Spellunker; Test::Spellunker->VERSION('v0.2.2') }
        or skip_all "Test::Spellunker v0.2.2 or later isn't installed";
    Test::Spellunker->import;
}

# As Minilla's test does: the distribution's name, and the stopwords in
# minil.toml, of which there are none.
add_stopwords('DBIx-Squirrel');

pod_file_spelling_ok($_) for Test::Spellunker::all_pod_files('lib');

my @next = grep { -e "docs/next/$_" } qw(HOWTO.md REFERENCE.md);
if (@next) {
    require './scripts/manuals';    ## no critic (Modules::RequireBarewordIncludes) a script, not a module
    my %markdown = map { ($_ => Manuals::slurp("docs/next/$_")) } @next;
    my %sections = map { ($_ => Manuals::sections($markdown{$_})) } @next;
    my $dir      = tempdir(CLEANUP => 1);
    for my $file (@next) {
        my $pod = eval { Manuals::convert($markdown{$file}, \%sections, $file) };
        ok defined $pod, "docs/next/$file converts to POD" or diag $@;
        next unless defined $pod;
        open my $out, '>:encoding(UTF-8)', "$dir/$file.pod"
            or die "Can't write $dir/$file.pod: $!";
        print { $out } $pod;
        close $out or die "Can't write $dir/$file.pod: $!";
        pod_file_spelling_ok("$dir/$file.pod", "POD spelling for docs/next/$file");
    }
}
pod_file_spelling_ok('docs/next/README.pod') if -e 'docs/next/README.pod';

done_testing;
