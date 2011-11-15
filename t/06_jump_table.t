use strict;
use warnings;
use Test::More;

use App::AnyBrainfuck;

use t::Util qw(create_config_file);

{
    my $app = App::AnyBrainfuck->new;
    my @tokens = split //, '[><]>';
    my %jump_table = $app->_create_jump_table(@tokens);

    is_deeply(\%jump_table, { 0 => 4, 3 => 0 }, 'default symbols');


    @tokens = split //, '[>[]<]>';
    %jump_table = $app->_create_jump_table(@tokens);

    is_deeply(\%jump_table, {
        2 => 4, 3 => 2,
        0 => 6, 5 => 0
    }, 'multi branches');

    @tokens = split //, '[><]]>';
    eval {
        %jump_table = $app->_create_jump_table(@tokens);
    };
    like $@, qr/Error: too many right bracket/, 'too many right bracket op';

    @tokens = split //, '[><][[';
    eval {
        %jump_table = $app->_create_jump_table(@tokens);
    };
    like $@, qr/Error: too many left bracket/, 'too many left bracket op';
}

{
    # user symbols without separator
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
        my @tokens = qw/いい いい きき うう ええ くく おお かか/;
        my %jump_table = $app->_create_jump_table(@tokens);
        is_deeply(\%jump_table, {
            2 => 6, 5 => 2
        }, 'user defined multibyte symbols');
    }
}

done_testing;
