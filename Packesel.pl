#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
require "list.pl";

#command line default arguments
my $source = "./";

GetOptions(
'source=s' => \$source,
) or die "Usage: $0 --source Dir or Git Repo";

sub is_git_url{
  if($_[0] =~ /http.*\.git/)
  {  return 1;}
  else
  {  return 0;}
}

sub is_valid_path{
  if(system "ls $_[0] > /dev/null 2>&1")
  {  return 0;}
  else
  {  return 1;}
}

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

if(is_git_url($source)){
 say ("Get around to writing code to package a git url");
}
elsif(is_valid_path($source)){
  say ("Get around to wring code to package this directory");
}
else{
  say( "package this directory I guess");
}
