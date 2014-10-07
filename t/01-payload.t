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

done_testing();
