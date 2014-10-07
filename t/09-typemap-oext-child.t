use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

{
    package Panda::XS::Test::MyChild;
    our @ISA = 'Panda::XS::Test::MyBase';
}

my $obj = new Panda::XS::Test::MyChild(10, 20);
is(ref $obj, 'Panda::XS::Test::MyChild', "output OEXT-child return object");
is($obj->val, 10, "input OEXT THIS base method works");
is($obj->val2, 20, "input OEXT THIS child method works");
$obj->set_from(new Panda::XS::Test::MyChild(7,8));
is($obj->val.'-'.$obj->val2, "7-8", "input OEXT arg child method works");
is(Panda::XS::Test::dcnt(), 2, 'tmp obj OEXT desctructors called');

my $base = new Panda::XS::Test::MyBase(123);
ok(!eval{$base->Panda::XS::Test::MyChild::val2(); 1}, "input OEXT THIS doesnt allow wrong type objects");
ok(!eval{$obj->set_from($base); 1}, "input OEXT arg doesnt allow wrong type objects");
undef $base;
undef $obj;
is(Panda::XS::Test::dcnt(), 5, 'tmp and obj OEXT desctructors called');

done_testing();
