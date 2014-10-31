use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

{
    package Panda::XS::Test::PTRMyRefCountedChild;
    our @ISA = 'Panda::XS::Test::PTRMyRefCounted';
}

my $o = new Panda::XS::Test::PTRMyRefCounted(123);
is(Panda::XS::Test::dcnt(), 0);
is(ref $o, 'Panda::XS::Test::PTRMyRefCounted');
is($o->val, 123);
is($o->val, 123);
undef $o;
is(Panda::XS::Test::dcnt(), 1);

Panda::XS::Test::dcnt(0);
$o = new Panda::XS::Test::PTRMyRefCountedChild(123, 321);
is(Panda::XS::Test::dcnt(), 0);
is(ref $o, 'Panda::XS::Test::PTRMyRefCountedChild');
is($o->val, 123);
is($o->val2, 321);
undef $o;
is(Panda::XS::Test::dcnt(), 2);

Panda::XS::Test::dcnt(0);
$o = new Panda::XS::Test::PTRMyRefCounted(890);
Panda::XS::Test::hold_ptr_myrefcounted($o);
undef $o;
is(Panda::XS::Test::dcnt(), 0);
my $o2 = Panda::XS::Test::release_ptr_myrefcounted();
is(Panda::XS::Test::dcnt(), 0);
is($o2->val, 890);
undef $o2;
is(Panda::XS::Test::dcnt(), 1);

done_testing();
