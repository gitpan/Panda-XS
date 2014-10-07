use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

# Child Class + Other Class in a single object (join)

{
    package Panda::XS::Test::MyChild;
    our @ISA = 'Panda::XS::Test::MyBase';
    package Panda::XS::Test::MyOther;
    our @ISA = 'Panda::XS::Test::MyChild';
}

ok(!defined new Panda::XS::Test::MyOther(0, 0), "output OEXT-join returns undef for NULL RETVALs");
my $obj = new Panda::XS::Test::MyOther(10, 20);
is(ref $obj, 'Panda::XS::Test::MyOther', "output OEXT-join returns object");
is($obj->val, 10, "input OEXT-join THIS base method works");
is($obj->val2, 20, "input OEXT-join THIS child method works");
is($obj->other_val, 30, "input OEXT-join THIS other method works");
$obj->set_from(undef);
is($obj->val.$obj->val2.$obj->other_val, "102030", "input arg for OEXT-join allows undefs");
ok(!eval{$obj->set_from(new Panda::XS::Test::MyChild(10, 20)); 1}, "input OEXT-join arg doesnt allow wrong type objects");
is($obj->val.$obj->val2.$obj->other_val, "102030", "input OEXT-join arg doesnt allow wrong type objects");
is(Panda::XS::Test::dcnt(), 2, 'tmp obj OEXT desctructors called');
$obj->set_from(new Panda::XS::Test::MyOther(30, 40));
is($obj->val.$obj->val2.$obj->other_val, "304070", "input OEXT-join arg works");
is(Panda::XS::Test::dcnt(), 5, 'tmp obj OEXT-join desctructors called');
undef $obj;
is(Panda::XS::Test::dcnt(), 8, 'obj OEXT-join desctructors called');

done_testing();
