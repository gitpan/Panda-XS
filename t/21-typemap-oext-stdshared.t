use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 CPP11X=1 to enable std::shared_ptr tests' unless Panda::XS::Test->can('hold_myclass_ssp');

{
    package Panda::XS::Test::MyClassChildSSP;
    our @ISA = 'Panda::XS::Test::MyClassSSP';
}

my $o = new Panda::XS::Test::MyClassSSP(777);
is(Panda::XS::Test::dcnt(), 0);
is(ref $o, 'Panda::XS::Test::MyClassSSP');
is($o->val, 777);
is($o->val, 777);
undef $o;
is(Panda::XS::Test::dcnt(), 1);

Panda::XS::Test::dcnt(0);
$o = new Panda::XS::Test::MyClassChildSSP(888, 999);
is(Panda::XS::Test::dcnt(), 0);
is(ref $o, 'Panda::XS::Test::MyClassChildSSP');
is($o->val, 888);
is($o->val2, 999);
undef $o;
is(Panda::XS::Test::dcnt(), 2);

Panda::XS::Test::dcnt(0);
$o = new Panda::XS::Test::MyClassSSP(567);
Panda::XS::Test::hold_myclass_ssp($o);
undef $o;
is(Panda::XS::Test::dcnt(), 0);
my $o2 = Panda::XS::Test::release_myclass_ssp();
is(Panda::XS::Test::dcnt(), 0);
is($o2->val, 567);
undef $o2;
is(Panda::XS::Test::dcnt(), 1);

done_testing();
