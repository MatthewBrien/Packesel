#!/usr/bin/perl
use strict;
use warnings;
#TODO list.pl does not take symbolic links into account, will probably cause stack overflow if directory passed contains one


sub list{
  #replace '~' with home/usrname/
  my ($current_directory, $absolute) = @_;
  if($current_directory =~ /^~(?<dir>.*)/){
    $current_directory = "/home/".getpwuid($<).$+{dir};
  }
  #add trailing '/'
  if(!($current_directory =~/.*\/$/)){
    $current_directory .= '/';
  }

  if($_[1] eq 'absolute'){
    return absolute_list($current_directory);
  }
  elsif($_[1] eq 'relative'){
    ($current_directory =~ /(?<head>.*)(?<start>\/[a-zA-Z0-9\.\_\-\~]+\/$)/);
    return relative_list($+{start}, $+{head});
  }
  else{
    #TODO remove duplicate code here
    $current_directory =~ /(?<head>^\/.*)(?<start>\/[^\0]+$)/;
    return relative_list($+{start}, $+{head});
  }
}#end list

#generate list of absolute paths
sub absolute_list{
  my @list;
  my $current_directory = $_[0];

  opendir my $dir, $current_directory or die "Cannot open directory: $!";

  my @files = readdir $dir;

  closedir $dir;

  for my $file (@files)
  {
      if(-d "$current_directory$file"){
        if( !($file eq '.') && !($file eq '..') ){
            push( @list, absolute_list("$current_directory$file/"));
          }
        }
      else{
          push(@list, "$current_directory$file");
      }
  }
return @list;
}

#generate list of paths relative to deepest directory
sub relative_list{
  my ($current_directory, $head) = @_;
  my @list;

  opendir my $dir, "$head$current_directory" or die "Cannot open directory: $!";

  my @files = readdir $dir;

  closedir $dir;

  for my $file (@files)
  {
      if(-d "$head$current_directory$file"){
        if( !($file eq '.') && !($file eq '..') ){
            push( @list, relative_list("$current_directory$file/", $head));
          }
        }
      else{
          push(@list, "$current_directory$file");
      }
  }
return @list;
}
1;
