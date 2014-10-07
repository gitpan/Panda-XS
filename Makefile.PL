use 5.014;
use Config;
use Panda::Install;

my $ivbits = $Config{ivsize}*8;
my %xs = ('XS.xs' => 'XS.c');
my @typemaps = ('typemap', "typemap$ivbits");
my $define = '';

if ($ENV{TEST_FULL}) { # add test C code to build
    $xs{'test.xs'} = 'test.c';
    $define = '-DTEST_FULL';
    push @typemaps, 'testmap';
} else {
    unlink 'test.c', 'test.o';
}

write_makefile(
    NAME      => 'Panda::XS',
    INC       => '-Isrc',
    XS        => \%xs,
    SRC       => 'src',
    TYPEMAPS  => \@typemaps,
    CPLUS     => 1,
    PREREQ_PM => {'Panda::Install' => '0.1.5'},
    BIN_SHARE => {
        CPLUS    => 1,
        INCLUDE  => {'src' => '/'},
        XSOPT    => '-hiertype',
        TYPEMAPS => {
            'typemap'        => '',
            "typemap$ivbits" => '',
        },
    },
    MIN_PERL_VERSION => '5.14.0', # required for mg_findext/sv_unmagicext
    OPTIMIZE => '-g',
    DEFINE   => $define,
);
