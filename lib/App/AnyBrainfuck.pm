package App::AnyBrainfuck;
use 5.008_001;

use strict;
use warnings;

use Carp ();
use Getopt::Long ();
use Encode ();

our $VERSION = '0.01';

my @ops = (">", "<", "+", "-", ".", ",", "[", "]");
my %default_op_table = map { $_ => $_ } @ops;

sub new {
    my $class = shift;

    bless {
        from_encoding => 'utf8',
        to_encoding   => 'utf8',
        op_table      => { %default_op_table },
        separator     => 0,
    }, $class;
}

sub run {
    my $self = shift;

    $self->_parse_options;

    if ($self->{conf}) {
        $self->_load_config;
        $self->_check_param;
    }

    if ($self->{helloworld}) {
        $self->_output_hello_world;
        exit;
    }

    for my $file (@{$self->{argv}}) {
        $self->_interpret_brainfuck($file);
    }
}

sub _output_hello_world {
    my $self = shift;

    my $hello_world =<<'...';
+++++++++[>++++++++>+++++++++++>+++++<<<-]>.>++.+++++++..+++.>-.
------------.<++++++++.--------.+++.------.--------.>+.
...

    my @outputs;
    my $length = 0;
    for my $c (split //, $hello_world) {
        if (exists $self->{op_table}->{$c}) {
            my $symbol = $self->{op_table}->{$c};

            push @outputs, $self->{separator} ? "$symbol " : $symbol;
            $length += length $symbol;

            if ($length >= 40) {
                push @outputs, "\n";
                $length = 0;
            }
        }
    }

    print Encode::encode($self->{to_encoding}, join '', @outputs);
    print "\n";
}

sub _interpret_brainfuck {
    my ($self, $file) = @_;

    my $input_str = do {
        local $/;
        open my $fh, "<", $file or die "Can't open $file";
        Encode::decode($self->{from_encoding}, <$fh>);
    };

    my @tokens = $self->_separate_by_symbol($input_str);
    my %jump_table = $self->_create_jump_table(@tokens);

    my @tape;
    my $tape_pos = 0;
    my $pc = 0;

    my $length = scalar @tokens;
    my %op_table = %{$self->{op_table}};
    while ($pc < $length) {
        my $token = $tokens[$pc++];

        if ($token eq $op_table{'>'}) {
            $tape_pos++;
        } elsif ($token eq $op_table{'<'}) {
            $tape_pos--;
            Carp::croak("Error: negative tape position") if $tape_pos < 0;
        } elsif ($token eq $op_table{'+'}) {
            $tape[$tape_pos]++;
        } elsif ($token eq $op_table{'-'}) {
            $tape[$tape_pos]--;
        } elsif ($token eq $op_table{'.'}) {
            print chr $tape[$tape_pos];
        } elsif ($token eq $op_table{','}) {
            my $c = getc STDIN;
            $tape[$tape_pos] = $c;
        } elsif ($token eq $op_table{'['}) {
            if ($tape[$tape_pos] == 0) {
                $pc = $jump_table{$pc-1};
            }
        } elsif ($token eq $op_table{']'}) {
            if ($tape[$tape_pos] != 0) {
                $pc = $jump_table{$pc-1};
            }
        } else {
            Carp::croak("Internal Error");
        }
    }
}

sub _separate_by_symbol {
    my ($self, $input) = @_;

    my @tokens;
    if ($self->{separator}) {
        @tokens = split /\s+/, $input;

        my %symbol_table = map { $_ => 1 } values %{$self->{op_table}};

        for my $t (@tokens) {
            unless (exists $symbol_table{$t}) {
                my $err = Encode::encode($self->{to_encoding},
                                         "Found invalid token: $t");
                Carp::croak($err);
            }
        }

        return @tokens;
    } else {
        my $op_regexp
            = join '|', map { quotemeta $self->{op_table}->{$_} } @ops;
        while (1) {
            if ($input =~ m/\G ($op_regexp)/gcxms) {
                push @tokens, $1;
            } elsif ($input =~ m{\G \z}gcxms) {
                last;
            } elsif ($input =~ m{\G .}gcxms) {
                # do nothing
            }
        }
    }

    return @tokens;
}

sub _create_jump_table {
    my ($self, @tokens) = @_;

    my $left_bracket  = $self->{op_table}->{'['};
    my $right_bracket = $self->{op_table}->{']'};

    my (@jump_stack, %jump_table);
    my $index = 0;
    for my $token (@tokens) {
        if ($token eq $left_bracket) {
            push @jump_stack, $index;
        } elsif ($token eq $right_bracket) {
            my $corresponding = pop @jump_stack;
            unless (defined $corresponding) {
                my $error = "Error: too many right bracket '$right_bracket'";
                Carp::croak( Encode::encode($self->{to_encoding}, $error) );
            }

            $jump_table{$corresponding} = $index + 1;
            $jump_table{$index}         = $corresponding;
        }

        $index++;
    }

    if (@jump_stack) {
        my $error = "Error: too many left bracket '$left_bracket'";
        Carp::croak( Encode::encode($self->{to_encoding}, $error) );
    }

    return %jump_table;
}

sub _parse_options {
    my $self = shift;

    Getopt::Long::GetOptions(
        "config|c=s" => \$self->{conf},
        "from|f=s"   => \$self->{from_encoding},
        "to|t=s"     => \$self->{to_encoding},
        "helloworld" => \$self->{helloworld},
        "help|h"     => \$self->{help},
    );

    if ($self->{help}) {
        die <<'...';
Usage : any-brainfuck [options] file...

Options:
  -h,--help     display this help message
  -c,--config   config file
  -f,--from     config file encoding(default is 'utf8')
  -t,--to       output encoding(default is 'utf8')
  --helloworld  generate 'hello world' program from config file
...
    }

    $self->{argv} = [ @ARGV ];
}

sub _load_config {
    my $self = shift;

    my $conf = do $self->{conf} or die "Can't load config file: $self->{conf}";

    map {
        $self->{op_table}->{$_}
            = Encode::decode($self->{from_encoding}, $conf->{$_});
    } grep { exists $conf->{$_} } @ops;

    if ($conf->{separator}) {
        $self->{separator} = 1;
    }
}

sub _check_param {
    my $self = shift;

    if ($self->{separator}) {
        my $key_num = scalar keys %{$self->{op_table}};
        my %symbol  = map { $_ => 1 } values %{$self->{op_table}};
        my $symbol_num = scalar keys %symbol;

        if ($symbol_num != $key_num) {
            Carp::croak("Error: some symbol is duplicated");
        }
    } else {
        my @symbols = sort {
            length $a <=> length $b
        } values %{$self->{op_table}};

        my $length = scalar @symbols;
        while (my $elm = shift @symbols) {
            for my $e (@symbols) {
                if ($e =~ m{$elm}) {
                    Carp::croak("Error: $e is matched $elm too");
                }
            }
        }
    }
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::AnyBrainfuck - Anything is Brainfuck

=head1 SYNOPSIS

  use App::AnyBrainfuck;

=head1 DESCRIPTION

App::AnyBrainfuck is brainfuck created from config file.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
