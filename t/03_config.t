use strict;
use warnings;
use Test::More;

use App::AnyBrainfuck;
use File::Temp ();

my $tmp_conf = File::Temp->new;

print {$tmp_conf} <<'...';
+{
    '>' => 'a',
    '<' => 'b',
    '+' => 'c',
    '-' => 'd',
    '.' => 'e',
    ',' => 'f',
    '[' => 'g',
    ']' => 'h',
}
...
$tmp_conf->autoflush;

my $app = App::AnyBrainfuck->new;
$app->{conf} = $tmp_conf->filename;
$app->_load_config;

my @ops = (">", "<", "+", "-", ".", ",", "[", "]");
my @symbols = 'a'..'h';

my %table = map { $ops[$_] => $symbols[$_] } 0..(scalar @ops - 1);
for my $op (">", "<", "+", "-", ".", ",", "[", "]") {
    is $app->{op_table}->{$op}, $table{$op}, "operation '$op'";
}

done_testing;
