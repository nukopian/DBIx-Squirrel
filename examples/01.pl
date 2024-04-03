use Benchmark ':all';
use DBIx::Squirrel::util ':all';

my @ary = (
    1 .. 2,
    sub { 1 },
);

my ( $c1, @a1 );
my ( $c2, @a2 );

sub a
{
    return 1 if $_[0] % 2;
    return undef;
}

sub b
{
    return $_[0] % 2 ? 1 : undef;
}

@range = 1 .. 100;

for ( 1 .. 5 ) {
    cmpthese(
        5000000 => {
            'b' => sub {
                b($_);
            },
            'a' => sub {
                a($_);
            },
        }
    );
}
