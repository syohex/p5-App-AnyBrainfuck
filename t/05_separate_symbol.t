use strict;
use warnings;
use Test::More;

use App::AnyBrainfuck;

use t::Util qw(create_config_file);

{
    # default symbols without separator
    my $app = App::AnyBrainfuck->new;
    my $input = '><+-.,[]';
    my @symbols = $app->_separate_by_symbol($input);

    is_deeply(\@symbols, [ split //, $input ], 'default symbols');

    $input = '><+-.,[]1234';
    @symbols = $app->_separate_by_symbol($input);
    is_deeply(\@symbols, [ split //, '><+-.,[]' ], 'has noise character');

    @symbols = $app->_separate_by_symbol('');
    is_deeply(\@symbols, [], 'empty string');
}

{
    # user symbols without separator
    my $conf = create_config_file(
        '>' => 'aa',
        '<' => 'bb',
        '+' => 'cc',
        '-' => 'dd',
        '.' => 'ee',
        ',' => 'ff',
        '[' => 'gg',
        ']' => 'hh',
    );

    my $app = App::AnyBrainfuck->new;
    $app->{conf} = $conf->filename;

    $app->_load_config;
    my $input = 'aabbccddeeffgghh';
    my @symbols = $app->_separate_by_symbol($input);
    is_deeply(\@symbols, [qw/aa bb cc dd ee ff gg hh/], "user defined symbols");

    $input = 'aa988bb892983cc988923dd75875ee11ffggpppphhkk';
    @symbols = $app->_separate_by_symbol($input);
    is_deeply(\@symbols, [qw/aa bb cc dd ee ff gg hh/],
              "user defined symbols with noise");
}

{
    my $conf = create_config_file(
        '>' => 'ああ',
        '<' => 'いい',
        '+' => 'うう',
        '-' => 'ええ',
        '.' => 'おお',
        ',' => 'かか',
        '[' => 'きき',
        ']' => 'くく',
    );

    my $app = App::AnyBrainfuck->new;
    $app->{conf} = $conf->filename;
    $app->_load_config;

    {
        use utf8;
        my $input = 'ああいいううええおおかかききくく';
        my @symbols = $app->_separate_by_symbol($input);
        is_deeply(\@symbols, [qw/ああ いい うう ええ おお かか きき くく/],
                  "user defined multibyte symbols");
    }

    {
        use utf8;
        my $input = 'ああいいううええここおおかかききくく';
        my @symbols = $app->_separate_by_symbol($input);
        is_deeply(\@symbols, [qw/ああ いい うう ええ おお かか きき くく/],
                  "user defined multibyte symbols with noise");
    }
}

{
    # user symbols with separator
    my $conf = create_config_file(
        '>' => 'a',
        '<' => 'aa',
        '+' => 'aaa',
        '-' => 'aaaa',
        '.' => 'aaaaa',
        ',' => 'aaaaaa',
        '[' => 'aaaaaaa',
        ']' => 'aaaaaaaa',
        separator => 'T',
    );

    my $app = App::AnyBrainfuck->new;
    $app->{conf} = $conf->filename;

    $app->_load_config;
    my $input = 'aTaaTaaaTaaaaTaaaaaTaaaaaaTaaaaaaaTaaaaaaaa';
    my @symbols = $app->_separate_by_symbol($input);
    is_deeply(\@symbols, [qw/a aa aaa aaaa aaaaa aaaaaa aaaaaaa aaaaaaaa/],
              "user defined symbols with separator");

    $input = 'aTBaa';
    eval {
        @symbols = $app->_separate_by_symbol($input);
    };
    like $@, qr/Found invalid token:/, 'invalid token with separator';
}

done_testing;
