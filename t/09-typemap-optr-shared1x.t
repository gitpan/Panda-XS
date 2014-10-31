use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

{
    package Panda::XS::Test::PTRMyRefCountedChildSP;
    our @ISA = 'Panda::XS::Test::PTRMyRefCountedSP';
}

my $o = new Panda::XS::Test::PTRMyRefCountedSP(777);
is(Panda::XS::Test::dcnt(), 0);
is(ref $o, 'Panda::XS::Test::PTRMyRefCountedSP');
is($o->val, 777);
is($o->val, 777);
undef $o;
is(Panda::XS::Test::dcnt(), 1);

Panda::XS::Test::dcnt(0);
$o = new Panda::XS::Test::PTRMyRefCountedChildSP(888, 999);
is(Panda::XS::Test::dcnt(), 0);
is(ref $o, 'Panda::XS::Test::PTRMyRefCountedChildSP');
is($o->val, 888);
is($o->val2, 999);
undef $o;
is(Panda::XS::Test::dcnt(), 2);

Panda::XS::Test::dcnt(0);
$o = new Panda::XS::Test::PTRMyRefCountedSP(345);
Panda::XS::Test::hold_ptr_myrefcounted_sp($o);
undef $o;
is(Panda::XS::Test::dcnt(), 0);
my $o2 = Panda::XS::Test::release_ptr_myrefcounted_sp();
is(Panda::XS::Test::dcnt(), 0);
is($o2->val, 345);
undef $o2;
is(Panda::XS::Test::dcnt(), 1);

done_testing();
