#!/usr/bin/perl
use strict;
use warnings;
#TODO list.pl does not take symbolic links into account, will probably cause stack overflow if directory passed contains one


sub list{
  my ($current_directory, $absolute) = @_;
  if($absolute){
    return absolute_list($current_directory);
  }
  else{
    $current_directory =~ /(?<head>^\/.*)(?<start>\/[^\0]+$)/;
    return relative_list($+{start}, $+{head});
  }
} #end list

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
  print @list,"\n";
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
