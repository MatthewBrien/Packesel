#!/usr/bin/perl

use strict;
use warnings;

require "list.pl";

sub is_git_repo{
  #if param passed, check if that directory is a git repo
  #otherwise, check current directory
  if (@_){
      if(system "git -C $_[0] rev-parse")
      {return 0;}
  }
  else{
    if(system "git rev-parse")
      {return 0;}
  }
    return 1;
}

if(@ARGV){
  if(is_git_repo($ARGV[0])){
    print "$ARGV[0] is a git repo\n";
  }
  else{
    print "$ARGV[0] is not a git repo\n";
  }
}
else{
  if(is_git_repo()){
    print "current directory is git repo\n";
  }
  else{
    print "current directory is not git repo\n";
  }
}
