use strict;
use warnings;

use base qw(Exporter);

use File::Temp ();

our @EXPORT_OK = qw(create_config_file);

my @ops = (">", "<", "+", "-", ".", ",", "[", "]");

sub create_config_file {
    my %conf = @_;

    my $tmp_conf = File::Temp->new;

    my $str = "+{\n";
    map {
        $str .= "'$_' => '" . $conf{$_} . "',\n";
    } grep { defined $conf{$_} } @ops, 'separator';
    $str .= "}\n";

    print {$tmp_conf} $str;
    $tmp_conf->autoflush;

    return $tmp_conf;
}

1;
