use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::util;

our @ISA = qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = (all => [
    our @EXPORT_OK = qw(
        cluckf
        confessf
        decode_utf8
        decompress
        decrypt
        get_file_contents
        global_destruct_phase
        isolate_callbacks
        result
        slurp
    )
]);

use Carp                          ();
use Compress::Bzip2               ();
use DBIx::Squirrel::Crypt::Fernet ();
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

Throws and exception with a stack-trace.

    confessf();

The error will be set to C<$@> if it contains something useful (effectivly
re-throwing the previous exception). Otherwise it will an "Unknown error"
exception is thrown.

    confessf($message);
    confessf(\@message);

The error will be set to C<$message>, or the concatenated C<@message> array,
or C<$@>, if there is no viable message. If there is still no viable message
then an "Unknown error" is thrown.

During concatenation, the elements of the C<@message> array are separated
by a single space. The intention is to allow for long error messages to be
split apart in a tidier manner.

    confessf($format, @arguments);
    confessf(\@format, @arguments);

The error message is composed using a C<sprintf> format-string (C<$format>),
together with any remaining arguments. Alternatively, the format-string may
be produced by concatenating the C<@format> array whose elements are separated
by a single space.

=cut

sub confessf {
    @_ = do {
        if (@_) {
            my $format = UNIVERSAL::isa($_[0], 'ARRAY') ? join(' ', @{+shift}) : shift;
            if (@_) {
                sprintf($format, @_);
            }
            else {
                $format or $@ or 'Unknown error';

            }
        }
        else {
            $@ or 'Unknown error';
        }
    };
    goto &Carp::confess;
}


=head3 C<cluckf>

Emits a warning with a stack-trace.

    cluckf();

The warning will be set to C<$@> if it contains something useful. Otherwise 
an "Unhelpful warning" will be emitted.

    cluckf($message);
    cluckf(\@message);

The warning will be set to C<$message>, or the concatenated C<@message> array,
or C<$@>, if there is no viable message. If there is still no viable message
then an "Unhelpful warning" is emitted.

During concatenation, the elements of the C<@message> array are separated
by a single space. The intention is to allow for long warning messages to be
split apart in a tidier manner.

    cluckf($format, @arguments);
    cluckf(\@format, @arguments);

The warning is composed using a C<sprintf> format-string (C<$format>), together
with any remaining arguments. Alternatively, the format-string may be produced
by concatenating the C<@format> array whose elements are separated by a single
space.

=cut

sub cluckf {
    @_ = do {
        if (@_) {
            my $format = UNIVERSAL::isa($_[0], 'ARRAY') ? join(' ', @{+shift}) : shift;
            if (@_) {
                sprintf($format, @_);
            }
            else {
                $format or $@ or 'Unhelpful warning';
            }
        }
        else {
            $@ or 'Unhelpful warning';
        }
    };
    goto &Carp::cluck;
}


sub decode_utf8 {
    my $buffer = shift;
    return $_ = Encode::decode_utf8($buffer, @_);
}


sub decompress {
    my $buffer = shift;
    return $_ = Compress::Bzip2::memBunzip($buffer);
}


sub decrypt {
    my($buffer, $fernet) = @_;
    unless (defined $fernet) {
        unless (defined $ENV{FERNET_KEY}) {
            confessf [
                "Neither a Fernet key nor a Fernet object have been",
                "defined. Decryption is impossible",
            ];
        }
        $fernet = $ENV{FERNET_KEY};
    }
    $fernet = DBIx::Squirrel::Crypt::Fernet->new($fernet)
        unless UNIVERSAL::isa($fernet, 'DBIx::Squirrel::Crypt::Fernet');
    return $_ = $fernet->decrypt($buffer);
}


sub get_file_contents {
    my($filename, $opt) = @_;
    my $buffer = slurp($filename);
    if ($filename =~ /\.enc(?:rypted)?\b/ || $opt->{decrypt}) {
        $buffer = decrypt($buffer, $opt->{fernet});
    }
    if ($filename =~ /\.(?:bz2|compressed)\b/ || $opt->{decompress}) {
        $buffer = decompress($buffer);
    }
    if ($filename =~ /\.json\b/ || $opt->{unmarshal}) {
        return unmarshal($buffer);
    }
    unless (exists($opt->{decode_utf8}) && !$opt->{decode_utf8}) {
        return decode_utf8($buffer);
    }
    return $_ = $buffer;
}


sub slurp {
    my($filename) = @_;
    open my $fh, '<:raw', $filename
        or confessf "$! - $filename";
    read $fh, my $buffer, -s $filename;
    close $fh;
    return $_ = $buffer;
}


sub unmarshal {
    my $utf8   = @_ > 1 ? !!pop                      : !!1;
    my $buffer = $utf8  ? Encode::decode_utf8(shift) : shift;
    local $JSON::Syck::ImplicitUnicode = $utf8;
    return $_ = JSON::Syck::Load($buffer);
}

1;
