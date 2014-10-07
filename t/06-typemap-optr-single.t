use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

is(Panda::XS::Test::dcnt(), 0, "dcnt is 0");

my @bad_values = (*STDOUT{IO}, map {bless $_, 'ABCD'} sub {}, [], {});
push @bad_values, 0, 1, '', 'asd', sub {}, [], {}, map {\(my $a = $_)} 0, 1, '', 'asd';

ok(!defined new Panda::XS::Test::OPTR(0), "output OPTR returns undef for NULL RETVALs");
my $obj = new Panda::XS::Test::OPTR(123);
is(ref $obj, 'Panda::XS::Test::OPTR', "output OPTR return object");
is($obj->val, 123, "input THIS for OPTR works");
ok(!eval {Panda::XS::Test::OPTR::val(undef); 1}, "input THIS for OPTR doesnt allow undefs");
for my $badval (@bad_values) {
    ok(!eval {Panda::XS::Test::OPTR::val($badval); 1}, "input THIS for OPTR doesnt allow bad values ($badval)");
}

$obj->set_from(undef);
is($obj->val, 123, "input arg for OPTR allows undefs");
$obj->set_from(new Panda::XS::Test::OPTR(1000));
is($obj->val, 1000, "input arg for OPTR works");
is(Panda::XS::Test::dcnt(), 1, 'tmp obj desctructor called');
for my $badval (@bad_values) {
    ok(!eval {$obj->set_from($badval); 1}, "input arg for OPTR doesnt allow bad values ($badval)");
}
undef $obj;
is(Panda::XS::Test::dcnt(), 2, '$obj desctructor called');

done_testing();
