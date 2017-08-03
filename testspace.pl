#!/usr/bin/perl
use Cwd 'abs_path'; #for finding path of running perl script
require "list.pl";

#my @test = list("ansible-role-stacki-frontend.1501255501");


my @files = list("/home/rpmmaker/rpmbuild/BUILD/BasicCalculator", "files_relative");

for my $i (@files){
  print "$i\n";
}
