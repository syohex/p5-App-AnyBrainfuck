use strict;
use warnings;
use Test::More;

use App::AnyBrainfuck;
use File::Temp ();

use t::Util qw(create_config_file);

my $conf = create_config_file(
    '>' => 'a',
    '<' => 'b',
    '+' => 'c',
    '-' => 'd',
    '.' => 'e',
    ',' => 'f',
    '[' => 'g',
    ']' => 'h',
    'separator' => "Z",
);

my $app = App::AnyBrainfuck->new;
$app->{conf} = $conf->filename;
$app->_load_config;

my @ops = (">", "<", "+", "-", ".", ",", "[", "]");
my @symbols = 'a'..'h';

my %table = map { $ops[$_] => $symbols[$_] } 0..(scalar @ops - 1);
for my $op (@ops) {
    is $app->{op_table}->{$op}, $table{$op}, "operation '$op'";
}

is $app->{separator}, 'Z', "'separator' param";

done_testing;
