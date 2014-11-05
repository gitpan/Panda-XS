use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

plan skip_all => 'rebuild Makefile.pl with TEST_FULL=1 to enable typemap tests' unless Panda::XS::Test->can('i8');

my %data = (
    AV => [],
    HV => {},
    CV => \&Panda::XS::Test::cv_out,
    IO => *STDOUT{IO},
);
test_type($_) for keys %data;

sub test_type {
    my $type = shift;
    my ($out_sub, $in_sub);
    {
        no strict 'refs';
        $out_sub = \&{"Panda::XS::Test::".lc($type)."_out"};
        $in_sub = \&{"Panda::XS::Test::".lc($type)."_in"};
    }
    # OUTPUT
    is($out_sub->(), undef, "output ($type*)NULL as undef");
    cmp_deeply($out_sub->(1), $data{$type}, "output $type* as ${type}REF");
    # INPUT
    is($in_sub->(undef), 0, "input undef as ($type*)NULL");
    ok($in_sub->($data{$type}), "input ${type}REF as $type*");
    ok(!eval {$in_sub->(0); 1}, "input $type* croaks for 0 numbers");
    ok(!eval {$in_sub->(int rand 100); 1}, "input $type* croaks for numbers");
    ok(!eval {$in_sub->(''); 1}, "input $type* croaks for empty strings");
    ok(!eval {$in_sub->('asdfdasf'); 1}, "input $type* croaks for strings");
    ok(!eval {$in_sub->(\'asdfdasf'); 1}, "input $type* croaks for SVREF");
    foreach my $other_type (grep {$_ ne $type} keys %data) {
        ok(!eval {$in_sub->($data{$other_type}); 1}, "input $type* croaks for ${other_type}REF");
    }
}

done_testing();
