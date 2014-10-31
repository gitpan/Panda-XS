use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

{
    package Panda::XS::Test::MyRefCountedChildSP;
    our @ISA = 'Panda::XS::Test::MyRefCountedSP';
}

is(Panda::XS::Test::test_typemap_incast_av([1,2,3]), 3);
is(Panda::XS::Test::test_typemap_incast_av2([1,2,3], [5,6]), 5);
is(Panda::XS::Test::test_typemap_incast_myrefcounted(new Panda::XS::Test::MyRefCounted(123456)), 123456);
cmp_deeply(Panda::XS::Test::test_typemap_outcast_av([1,2,3]), [1,1,1]);
cmp_deeply(Panda::XS::Test::test_typemap_outcast_av(undef), []);

Panda::XS::Test::dcnt(0);
my $ret = Panda::XS::Test::test_typemap_outcast_complex(new Panda::XS::Test::MyRefCountedChildSP(555,666));
is(Panda::XS::Test::dcnt(), 2);
is(ref $ret, 'ARRAY');
is(scalar @$ret, 2);
is($ret->[0], 555);
is(ref $ret->[1], 'Panda::XS::Test::MyClassSP');
is($ret->[1]->val, 666);
undef $ret;
is(Panda::XS::Test::dcnt(), 3);

done_testing();
