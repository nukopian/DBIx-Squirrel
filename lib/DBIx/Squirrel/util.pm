use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::util;

our @ISA = qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = (all => [
    our @EXPORT_OK = qw(
        isolate_callbacks
        global_destruct_phase
        result
        readfile
        statement_digest
        statement_normalise
        statement_study
        statement_trim
        confessf
        cluckf
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


=head3 C<isolate_callbacks>

    (\@callbacks, @arguments) = isolate_callbacks(@argments);
    (\@callbacks, @arguments) = &isolate_callbacks;

While using C<DBIx::Squirrel>, some calls may include a trailing, contiguous
set of lambdas or callbacks, referred to as a transformation pipeline.

This function takes an array of arguments that may or may not contain a
transformation pipeline. It moves any and all stages of a pipeline from the
end of the array of arguments into a separate array, and returns a reference
to that array, followed by any remaining arguments, to the caller.

=cut

sub isolate_callbacks {
    my $n = my $s = scalar @_;
    $n-- while $n && UNIVERSAL::isa($_[$n - 1], 'CODE');
    return ([],              @_)              if $n == $s;
    return ([@_[$n .. $#_]], @_[0 .. $n - 1]) if $n;
    return ([@_]);
}


=head3 C<global_destruct_phase>

    $bool = global_destruct_phase();

Perl versions older than 5.14 don't support ${^GLOBAL_PHASE}, so
provide a shim that does the same so that DESTROY methods can be
made safer.

=cut

sub global_destruct_phase {
    return Devel::GlobalDestruction::in_global_destruction();
}


=head3 C<confessf>

    confessf [$message];
    confessf [$format_string[, @arguments]];

Throw an exception with a stack trace. If nothing helpful is passed then C<$@>
will be re-thrown if it is not empty, or an unknown exception will be thrown.

=cut

sub confessf {
    @_ = do {
        if (@_) {
            my $format = shift;
            if (@_) {
                sprintf($format, @_);
            }
            else {
                $format or $@ or 'Unknown exception thrown';

            }
        }
        else {
            $@ or 'Unknown exception thrown';
        }
    };
    goto &Carp::confess;
}


=head3 C<cluckf>

    cluckf [$message];
    cluckf [$format_string[, @arguments]];

Emit a warning with a stack trace. If nothing helpful is passed then an
equally unhelpful warning is emitted.

=cut

sub cluckf {
    @_ = do {
        if (@_) {
            my $format = shift;
            if (@_) {
                sprintf($format, @_);
            }
            else {
                $format or 'Unhelpful warning issued';
            }
        }
        else {
            'Unhelpful warning issued';
        }
    };
    goto &Carp::cluck;
}


sub readfile {
    my($filename, $opt) = @_;
    open my $fh, '<:raw', $filename
        or confessf "$! - $filename";
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
