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

our $VERSION     = 0.04;
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


=pod

=encoding utf8

=head1 名称

L<SimpleR::Stat> Simple Stat on arrayref, like sum, mean, calc rate, etc

简单数据统计处理

=head1 说明

传入 scalar num / arrayref，计算 sum 求和, mean 均值, rate 比例 等

=head1 函数

=begin html

实例参考<a href="xt/">xt子文件夹</a>

=end html

=head2 calc_rate

计算比例

    my $r = calc_rate(3, 4);
    # $r = 0.75

=head2 calc_rate_arrayref

将数组中某些项求和，并计算比例，最后传入原来的数组

calc_fields : 指定数组中的项

rate_sub : 对计算出来的rate做进一步处理，例如 3/8 = 0.675，转换成 67.50

    my $data = [ '2013-10-22', 'gym', 3, 4, 1 , 'china' ];
    my $r = calc_rate_arrayref($data, 
            calc_fields => [ 2, 3, 4 ], 
            rate_sub => sub { sprintf("%.2f", 100*$_[0]) },
    );
    # $r =  [ '2013-10-22', 'gym',   3,     4,     1 , 'china' , 
    #                         8, 37.50, 50.00, 12.50 ];

=head2 format_percent

将比例转换成百分比，例如 0.675 -> 67.50%

    my $r = format_percent(0.675, "%.2f%%");
    # $r = '67.50%'

=head2 calc_compare_rate

计算增量

    my $r = calc_compare_rate(4, 7);
    # $r = 0.75
    my ($r2, $diff) = calc_compare_rate(4, 7);
    # $r2 = 0.75, $diff = 3

=head2 sum_arrayref

数组求和
    
    my $d = [ 1, 4, 3 ];
    my $r = sum_arrayref($d);
    # $r = 8

=head2 mean_arrayref

数组均值
    
    my $d = [ 1, 4, 3 ];
    my $r = mean_arrayref($d);
    # $r = 2.66666667

=head2 median_arrayref

数组中位数
    
    my $d = [ 1, 4, 3 ];
    my $r = median_arrayref($d);
    # $r = 3

=head2 uniq_arrayref

数组去重
    
    my $d = [ 1, 1, 4, 4, 3 ];
    my $r = uniq_arrayref($d);
    # $r = [ 1, 3, 4 ] 

=head2 uniq_arrayref_cnt

数组去重后的元素个数
    
    my $d = [ 1, 1, 4, 4, 3 ];
    my $r = uniq_arrayref_cnt($d);
    # $r = 3

=head2 conv_arrayref_to_hash 

将arrayref转换为hash，注意重复的key会被覆盖掉，数据可能变少

    my $data=[ ['a','b',3],['e','f',6], ['a','f',9]];
    my $r = conv_arrayref_to_hash($data, [ 0, 1 ], 2);
    # $r =  { a => { b => 3, f => 9 }, e => { f => 6 } },

=cut
