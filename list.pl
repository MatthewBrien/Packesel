#!/usr/bin/perl
use strict;
use warnings;

sub say{ print @_, "\n" }

sub list{

  my $current_directory = $_[0];

  opendir my $dir, $current_directory or die "Cannot open directory: $!";

  my @files = readdir $dir;

  closedir $dir;

  for my $file (@files)

  {
      if(-d "$current_directory$file"){
        if( !($file eq '.') && !($file eq '..') ){
            list("$current_directory$file/");
          }
        }
      else{
          say "$current_directory$file";
      }
  }

} #end list
1;
