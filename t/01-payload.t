use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

my $var = 10;
ok(!Panda::XS::sv_payload_exists($var));
Panda::XS::sv_payload_attach($var, 20);
ok(Panda::XS::sv_payload_exists($var));
is($var, 10);
is(Panda::XS::sv_payload($var), 20);

{
    my $payload = {a => 1};
    $var = "jopa";
    ok(Panda::XS::sv_payload_exists($var));
    Panda::XS::sv_payload_attach($var, $payload);
    cmp_deeply(Panda::XS::sv_payload($var), {a => 1});
}
ok(Panda::XS::sv_payload_exists($var));
cmp_deeply(Panda::XS::sv_payload($var), {a => 1});

Panda::XS::sv_payload_detach($var);
ok(!Panda::XS::sv_payload_exists($var));
# RV test
my $var_rv = bless {aaa => "aaa", bbb => "bbb"},"someclass";
my $some_class = bless {ccc => "ccc"}, "someclass2";
ok(!Panda::XS::rv_payload_exists($var_rv));
Panda::XS::rv_payload_attach($var_rv, $some_class);
ok(Panda::XS::rv_payload_exists($var_rv));

my $dTemp = $var_rv;
ok(Panda::XS::rv_payload($dTemp));
{
    my $payload = {a => 1};
    bless $var_rv,"numberclass";
    ok(Panda::XS::rv_payload_exists($var_rv));
    Panda::XS::rv_payload_attach($var_rv, $payload);
    cmp_deeply(Panda::XS::rv_payload($var_rv), {a => 1});
}
ok(Panda::XS::rv_payload_exists($var_rv));
cmp_deeply(Panda::XS::rv_payload($var_rv), {a => 1});

Panda::XS::rv_payload_detach($var_rv);
ok(!Panda::XS::rv_payload_exists($var_rv));

done_testing();
