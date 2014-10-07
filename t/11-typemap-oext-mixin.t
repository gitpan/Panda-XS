use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

# Mixin (many unrelated objects) in a single object

{
    package Panda::XS::Test::Mixin;
    use mro 'c3';
    our @ISA = qw/Panda::XS::Test::MixPluginB Panda::XS::Test::MixPluginA Panda::XS::Test::MixBase/;
    package Panda::XS::Test::BadMixin;
    use mro 'c3';
    our @ISA = qw/Panda::XS::Test::MixPluginB Panda::XS::Test::MixBase/;
}

ok(!defined new Panda::XS::Test::Mixin(0), "output OEXT-mix returns undef for NULL RETVALs");
my $obj = new Panda::XS::Test::Mixin(555);
is(ref $obj, 'Panda::XS::Test::Mixin', "output OEXT-mix returns object");
is($obj->val.$obj->val_a.$obj->val_b, "55500", "input OEXT-mix THIS methods work");
$obj->val(222);
$obj->val_a(444);
$obj->val_b(333);
is($obj->val.$obj->val_a.$obj->val_b, "222444333", "input OEXT-mix THIS methods work");
$obj->set_from(undef);
is($obj->val.$obj->val_a.$obj->val_b, "222444333", "input arg for OEXT-mix allows undefs");
undef $obj;
is(Panda::XS::Test::dcnt(), 3, 'obj OEXT-mix desctructors called');
$obj = new Panda::XS::Test::Mixin(555);
ok(!eval{$obj->set_from(new Panda::XS::Test::MyChild(10, 20)); 1}, "input OEXT-mix arg doesnt allow wrong type objects");
ok(!eval{$obj->set_from(new Panda::XS::Test::MyBase(20)); 1}, "input OEXT-mix arg doesnt allow wrong type objects");
ok(!eval{$obj->set_from(new Panda::XS::Test::BadMixin(20)); 1}, "input OEXT-mix arg doesnt allow wrong type objects");
Panda::XS::Test::dcnt(0);
my $obj2 = new Panda::XS::Test::Mixin(300);
$obj2->val_a(200);
$obj2->val_b(100);
$obj->set_from($obj2);
is($obj->val.$obj->val_a.$obj->val_b, "300200100", "input arg for OEXT-mix works");
undef $obj;
undef $obj2;
is(Panda::XS::Test::dcnt(), 6, 'obj OEXT-mix desctructors called');

done_testing();
