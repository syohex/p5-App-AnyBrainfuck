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
    my ($class, ) = @_;

    bless {
        from_encoding => 'utf8',
        to_encoding   => 'utf8',
        op_table      => { %default_op_table },
    }, $class;
}

sub run {
    my $self = shift;

    $self->_parse_options;

    if ($self->{conf}) {
        $self->_load_config;
        $self->_check_param;
    }

    for my $file (@{$self->{argv}}) {
        $self->_interpret_brainfuck($file);
    }
}

sub _interpret_brainfuck {
    my ($self, $file) = @_;

    my $input_str = do {
        local $/;
        open my $fh, "<", $file or die "Can't open $file";
        Encode::decode($self->{from_encoding}, <$fh>);
    };

    my @tokens = $self->_separate_by_symbol($input_str);

    my @inputs = split //, $input_str;
    my (@jump_stack, %jump_table);

    my @tape;
    my $index = 0;

    my $length = scalar @inputs;
    my $token = '';
    my $offset = 0;

    my %op_table = %{$self->{op_table}};
    while ($index < $length) {
        $token .= $inputs[$offset];
        $offset++;

        if ($token =~ m/$op_table{'>'}/) {
            $index++;
        } elsif ($token =~ m/\G $op_table{'<'}/gcxms) {
            $index--;
            Carp::croak("Error: negative index") if $index < 0;
        } elsif ($token =~ m/\G $op_table{'+'}/gcxms) {
            $tape[$index]++;
        } elsif ($token =~ m/\G $op_table{'-'}/gcxms) {
            $tape[$index]--;
        } elsif ($token =~ m/\G $op_table{'.'}/gcxms) {
            print chr $tape[$index];
        } elsif ($token =~ m/\G $op_table{','}/gcxms) {
            chomp(my $c = <STDIN>);
            $tape[$index] = ord $c;
        } elsif ($token =~ m/\G $op_table{'['}/gcxms) {
            push @jump_stack, $index;
        } elsif ($token =~ m/\G $op_table{']'}/gcxms) {
        } elsif ($token =~ m/\G \z}/gcxms) {
            last;
        } else {
            # ignore
        }
    }
}

sub _separate_by_symbol {
    my ($self, $input) = @_;

    my @tokens;
    if ($self->{separator}) {
        @tokens = split /$self->{separator}/, $input;

        my %symbol_table = map { $_ => 1 } values %{$self->{op_table}};

        for my $t (@tokens) {
            unless (exists $symbol_table{$t}) {
                Carp::croak("Found invalid token: $t");
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
    my ($self, $input) = @_;

    my @jump_stack;
    my %jump_table;

    my $left_bracket  = $self->{op_table}->{'['};
    my $right_bracket = $self->{op_table}->{']'};

    while (1) {
        if ($input =~ m/\G $left_bracket/gcxms) {
            push @jump_stack, pos;
        } elsif ($input =~ m/\G $right_bracket/gcxms) {
            my $corresponding_pos = pos @jump_stack;
            my $pos = pos() + length $right_bracket;
            $jump_table{$corresponding_pos} = $pos;
            $jump_table{$pos} = $corresponding_pos;
        } elsif ($input =~ m{\G \z}gcxms) {
            last;
        }
    }

    if (@jump_stack) {
        my $error = "Error: not correspond '$left_bracket', '$right_bracket'";
        Carp::croak( Encode::encode($self->{to_string}, $error) );
    }

    return %jump_table;
}

sub _parse_options {
    my $self = shift;

    Getopt::Long::GetOptions(
        "config|c=s" => \$self->{conf},
        "from|f=s"   => \$self->{from_encoding},
        "to|t=s"     => \$self->{to_encoding},
    );

    $self->{argv} = [ @ARGV ];
}

sub _load_config {
    my $self = shift;

    my $conf = do $self->{conf} or die "Can't load config file: $self->{conf}";

    map {
        $self->{op_table}->{$_}
            = Encode::decode($self->{from_encoding}, $conf->{$_});
    } grep { exists $conf->{$_} } @ops;

    my $separator = delete $conf->{separator} || '';
    $self->{separator} = Encode::decode($self->{from_encoding}, $separator);
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

App::AnyBrainfuck -

=head1 SYNOPSIS

  use App::AnyBrainfuck;

=head1 DESCRIPTION

App::AnyBrainfuck is

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
