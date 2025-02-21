use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::util;

our @ISA = qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = (all => [
    our @EXPORT_OK = qw(
        args_partition
        global_destruct_phase
        result
        slurp
        statement_digest
        statement_normalise
        statement_study
        statement_trim
        throw
        whine
    )
]);

use Carp                          ();
use Compress::Bzip2               qw(memBunzip memBzip);
use DBIx::Squirrel::Crypt::Fernet qw(Fernet);
use Devel::GlobalDestruction      ();
use Dotenv                        ();
use Encode                        ();
use Exporter                      ();
use JSON::Syck                    ();
use Scalar::Util;
use Sub::Name;

if (-e '.env') {
    Dotenv->load();
}

sub args_partition {
    # Gathers trailing, contiguous CODEREFs into their own list, returning
    # a reference to that list followed by the remaining arguments.
    my $s = @_;
    return [] unless $s;
    my $n = $s;
    while ($n) {
        last unless UNIVERSAL::isa($_[$n - 1], 'CODE');
        $n -= 1;
    }
    return [@_] if $n == 0;
    return [], @_ if $n == $s;
    return [@_[$n .. $#_]], @_[0 .. $n - 1];
}

sub global_destruct_phase {
    # Perl versions older than 5.14 don't support ${^GLOBAL_PHASE}, so
    # provide a shim that works around that wrinkle.
    return Devel::GlobalDestruction::in_global_destruction();
}

sub throw {
    Carp::confess do {
        if (@_) {
            my($f, @a) = @_;
            @a ? sprintf($f, @a) : $f || $@ || 'Unknown exception thrown';
        }
        else {
            $@ || 'Unknown exception thrown';
        }
    };
}

sub whine {
    Carp::cluck do {
        if (@_) {
            my($f, @a) = @_;
            @a ? sprintf($f, @a) : $f || 'Unhelpful warning issued';
        }
        else {
            'Unhelpful warning issued';
        }
    };
}

sub slurp {
    my($filename, $opt) = @_;
    open my $fh, '<:raw', $filename
        or throw "$! - $filename";
    read $fh, my $buffer, -s $filename;
    close $fh;
    if ($filename =~ /\.encrypted/) {
        $buffer = do {
            if (!exists($opt->{key})) {
                Fernet($ENV{FERNET_KEY})->decrypt($buffer);
            }
            else {
                Fernet($opt->{key})->decrypt($buffer);
            }
        };
    }
    if ($filename =~ /\.bz2/) {
        $buffer = memBunzip($buffer);
    }
    if ($filename =~ /\.json/) {
        local $JSON::Syck::ImplicitUnicode = !!1;
        return do { $_ = JSON::Syck::Load(Encode::decode_utf8($buffer)) };
    }
    if (!exists($opt->{decode_utf8}) || !!$opt->{decode_utf8}) {
        return do { $_ = Encode::decode_utf8($buffer) };
    }
    return do { $_ = $buffer };
}

1;
