use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

# Class with wrapper

my $obj = new Panda::XS::Test::MyBaseAV(777);
is(ref $obj, 'Panda::XS::Test::MyBaseAV', "output OEXT_AV returns object");
$obj->[1] = 10;
is($obj->[1], 10, "OEXT_AV object is an ARRAYREF");
is($obj->val, 777, "input OEXT_AV works");
undef $obj;
is(Panda::XS::Test::dcnt(), 1, 'obj OEXT_AV desctructors called');

Panda::XS::Test::dcnt(0);
$obj = new Panda::XS::Test::MyBaseHV(888);
is(ref $obj, 'Panda::XS::Test::MyBaseHV', "output OEXT_HV returns object");
$obj->{abc} = 22;
is($obj->{abc}, 22, "OEXT_HV object is a HASHREF");
is($obj->val, 888, "input OEXT_HV works");
undef $obj;
is(Panda::XS::Test::dcnt(), 1, 'obj OEXT_HV desctructors called');

done_testing();
