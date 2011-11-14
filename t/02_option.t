use strict;
use warnings;
use Test::More;

use App::AnyBrainfuck;

my $app = App::AnyBrainfuck->new;
{
    local @ARGV = qw(--config=a.conf --from=shift_jis --to=euc-jp);
    $app->_parse_options;

    is $app->{conf}, 'a.conf', 'conf option';
    is $app->{from_encoding}, 'shift_jis', 'from_encoding option';
    is $app->{to_encoding}, 'euc-jp', 'to_encoding option';

}

done_testing;
