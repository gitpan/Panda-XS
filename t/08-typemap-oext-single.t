use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

my @bad_values = (*STDOUT{IO}, map {bless $_, 'ABCD'} sub {}, [], {});
push @bad_values, 0, 1, '', 'asd', sub {}, [], {}, map {\(my $a = $_)} 0, 1, '', 'asd';

ok(!defined new Panda::XS::Test::MyBase(0), "output OEXT returns undef for NULL RETVALs");
my $obj = new Panda::XS::Test::MyBase(123);
is(ref $obj, 'Panda::XS::Test::MyBase', "output OEXT returns object");
is($obj->val, 123, "input THIS for OEXT works");
ok(!eval {Panda::XS::Test::MyBase::val(undef); 1}, "input THIS for OEXT doesnt allow undefs");
for my $badval (@bad_values) {
    ok(!eval {Panda::XS::Test::MyBase::val($badval); 1}, "input THIS for OEXT doesnt allow bad values ($badval)");
}

$obj->set_from(undef);
is($obj->val, 123, "input arg for OEXT allows undefs");
$obj->set_from(new Panda::XS::Test::MyBase(1000));
is($obj->val, 1000, "input arg for OEXT works");
is(Panda::XS::Test::dcnt(), 1, 'tmp obj desctructor called');
for my $badval (@bad_values) {
    ok(!eval {$obj->set_from($badval); 1}, "input arg for OEXT doesnt allow bad values ($badval)");
}
undef $obj;
is(Panda::XS::Test::dcnt(), 2, '$obj desctructor called');

done_testing();
