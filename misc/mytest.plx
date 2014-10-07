#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Panda::XS;
use Devel::Peek;

say "START";

Dump(Panda::XS::Test::mytest(undef));

say "END";
