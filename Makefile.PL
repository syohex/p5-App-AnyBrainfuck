use inc::Module::Install;
use Module::Install::AuthorTests;

name 'App-AnyBrainfuck';
all_from 'lib/App/AnyBrainfuck.pm';

author_tests('xt');
WriteAll;
