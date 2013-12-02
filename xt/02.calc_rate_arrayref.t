#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

    my $data = [ '2013-10-22', 'gym', 3, 4, 1 , 'china' ];
    my $r = calc_rate_arrayref($data, 
            calc_fields => [ 2, 3, 4 ], 
            rate_sub => sub { sprintf("%.2f", 100*$_[0]) },
    );
dump($r);

done_testing;

