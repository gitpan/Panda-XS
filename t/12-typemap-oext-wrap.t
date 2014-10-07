use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

# Class with wrapper

my $obj = new Panda::XS::Test::Wrap(777);
is(ref $obj, 'Panda::XS::Test::Wrap', "output OEXT-wrap returns object");
is($obj->val, 777, "input OEXT-wrap wrapped method works");
is($obj->xval, 0, "input OEXT-wrap wrapper method works");
$obj->xval(100);
is($obj->val.$obj->xval, "777100", "input OEXT-wrap wrapper method works");
undef $obj;
is(Panda::XS::Test::dcnt(), 2, 'obj OEXT-wrap desctructors called');

done_testing();
