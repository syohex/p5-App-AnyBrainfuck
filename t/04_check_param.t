use strict;
use warnings;
use Test::More;

use App::AnyBrainfuck;

use t::Util qw(create_config_file);

{
    # setting separator
    my $conf = create_config_file(
        '>' => 'a',
        '<' => 'aa',
        '+' => 'aaa',
        '-' => 'aaaa',
        '.' => 'aaaaa',
        ',' => 'aaaaaa',
        '[' => 'aaaaaaa',
        ']' => 'aaaaaaaa',
        'separator' => "Z",
    );

    my $app = App::AnyBrainfuck->new;
    $app->{conf} = $conf->filename;

    $app->_load_config;

    eval {
        $app->_check_param;
    };
    ok !$@, 'valid paramters';
}

{
    # Has same parameter with 'separator'
    my $conf = create_config_file(
        '>' => 'aa',
        '<' => 'aa',
        'separator' => "Z",
    );

    my $app = App::AnyBrainfuck->new;
    $app->{conf} = $conf->filename;

    $app->_load_config;

    eval {
        $app->_check_param;
    };
    like $@, qr/some symbol is duplicated/, 'has duplicate parameter';
}

{
    # setting separator
    my $conf = create_config_file(
        '>' => 'abcd',
        '<' => 'abdc',
        '+' => 'acbd',
        '-' => 'acdb',
        '.' => 'adbc',
        ',' => 'adcb',
        '[' => 'bacd',
        ']' => 'badc',
    );

    my $app = App::AnyBrainfuck->new;
    $app->{conf} = $conf->filename;

    $app->_load_config;

    eval {
        $app->_check_param;
    };
    ok !$@, 'valid paramters with no separator';
}

{
    # ambigous syntax with no separator
    my $conf = create_config_file(
        '>' => 'a',
        '<' => 'aa',
    );

    my $app = App::AnyBrainfuck->new;
    $app->{conf} = $conf->filename;

    $app->_load_config;

    eval {
        $app->_check_param;
    };
    like $@, qr/matched \S+ too/, 'ambiguous syntax';
}

done_testing;
