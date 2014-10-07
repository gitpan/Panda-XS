use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

{
    package Panda::XS::Test::OPTRChild;
    our @ISA = 'Panda::XS::Test::OPTR';
}

my $obj = new Panda::XS::Test::OPTRChild(10, 20);
is(ref $obj, 'Panda::XS::Test::OPTRChild', "output OPTR-child return object");
is($obj->val, 10, "input THIS base method works");
is($obj->val2, 20, "input THIS child method works");
$obj->set_from(new Panda::XS::Test::OPTRChild(7,8));
is(Panda::XS::Test::dcnt(), 2, 'tmp obj desctructors called');
is($obj->val.'-'.$obj->val2, "7-8", "input arg child method works");

my $base = new Panda::XS::Test::OPTR(123);
ok(!eval{$base->Panda::XS::Test::OPTRChild::val2(); 1}, "input THIS doesnt allow wrong type objects");
ok(!eval{$obj->set_from($base); 1}, "input arg doesnt allow wrong type objects");
undef $base;
undef $obj;
is(Panda::XS::Test::dcnt(), 5, 'base and obj desctructors called');

done_testing();
