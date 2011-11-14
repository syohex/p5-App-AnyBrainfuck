use strict;
use warnings;
use Test::More;

use App::AnyBrainfuck;

my $app = App::AnyBrainfuck->new;
ok $app, "contructor";
isa_ok $app, 'App::AnyBrainfuck';

is $app->{from_encoding}, 'utf8', 'default from_encoding';
is $app->{to_encoding}, 'utf8', 'default to_encoding';

done_testing;
