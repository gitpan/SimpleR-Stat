# ABSTRACT: Simple Stat on arrayref, like sum, mean, calc rate, etc
package SimpleR::Stat;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw( calc_rate calc_rate_arrayref format_percent 
calc_compare_rate
sum_arrayref mean_arrayref median_arrayref
uniq_arrayref uniq_arrayref_cnt
conv_arrayref_to_hash
);

use strict;
use warnings;

our $VERSION     = 0.03;
our $DEFAULT_SEP = ',';

sub conv_arrayref_to_hash {
    #注意:重复的cut_fields会被覆盖掉
    my ( $data, $cut_fields, $v_field ) = @_;
    my $finish_cut = pop @$cut_fields;

    my %result;
    for my $row (@$data) {
        my $s = \%result;

        for my $cut (@$cut_fields) {
            my $c = map_arrayref_row( $row, $cut );
            $s->{$c} ||= {};
            $s = $s->{$c};
        }

        my $fin_c = map_arrayref_row( $row, $finish_cut );
        my $v     = map_arrayref_row( $row, $v_field );
        $s->{$fin_c} = $v;
    }

    return \%result;
} ## end sub conv_ref_to_hash

sub map_arrayref_row {
    my ( $row, $calc ) = @_;

    my $t = ref($calc);
    my $v = ($t eq 'CODE') ? $calc->($row) : 
    ($t eq 'ARRAY') ? join($DEFAULT_SEP,  @{$row}[@$calc]) :
    $row->[$calc];

    return $v;
}

sub calc_rate {
    my ( $val, $sum ) = @_;
    return 0 unless ( $sum and $sum > 0 );
    $val ||= 0;

    my $rate = $val / $sum;
    return $rate;
} ## end sub calc_rate

sub calc_rate_arrayref {
    my ($r, %opt) = @_;
    my $fields = $opt{calc_fields} || [ 0 .. $#$r ];

    my $num = sum_arrayref([ @{$r}[@$fields] ] );
    push @$r, $num;

    for my $i (@{$opt{calc_fields}}){
        $r->[$i] ||= 0;
        my $x = calc_rate($r->[$i], $num);
        $x = $opt{rate_sub}->($x) if(exists $opt{rate_sub});
        push @$r, $x;
    }

    return $r;
}

sub format_percent {
    my ( $rate, $format ) = @_;
    $format ||= "%.2f%%";
    $format = "%d%%" if ( $rate == 0 || $rate == 1 );
    return sprintf( $format, 100 * $rate );
}

sub calc_compare_rate {
    my ( $old, $new ) = @_;
    $old ||= 0;
    $new ||= 0;
    my $diff = $new-$old;

    my $rate = ($old == $new) ? 0 : 
    ($new == 0 ) ? -1 :
    ($old == 0 ) ? 1 :
    $diff / $old;
    return wantarray ? ($rate, $diff) : $rate;
} ## end sub calc_compare_rate

sub sum_arrayref {
    my ($r) = @_;
    my $num=0;
    $num += $_ || 0 for @$r;
    return $num;
}

sub mean_arrayref {
    my ($data) = @_;
    my $n = scalar(@$data);
    return calc_rate( sum_arrayref($data), $n );
}

sub median_arrayref {
    my ($data) = @_;
    my $n = $#$data;

    my @d = sort { $a <=> $b } @$data;

    return $d[ $n / 2 ] if ( $n % 2 == 0 );

    my $m = ( $n - 1 ) / 2;
    return ( $d[$m] + $d[ $m + 1 ] ) / 2;
}

sub uniq_arrayref {
    my ($r) = @_;
    my %d = map { $_ => 1 } @$r;
    return [ sort keys(%d) ];
}

sub uniq_arrayref_cnt {
    my ($r) = @_;
    my %d = map { $_ => 1 } @$r;
    my $c = scalar(keys(%d));
    return $c;
}

1;
