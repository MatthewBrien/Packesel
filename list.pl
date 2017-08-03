#!/usr/bin/perl
#generates lists of files, directories and paths

#Given a directory, returns a list of absolute paths to every file
sub list_files{
  my @list;
  my $current_directory = $_[0];
  opendir my $dir, $current_directory or die "Cannot open directory: $!";
  my @files = readdir $dir;
  closedir $dir;

  for my $file (@files)
  {
      if(-d "$current_directory$file"){
        if( !($file eq '.') && !($file eq '..') ){
            push( @list, list_files("$current_directory$file/"));
          }
        }
      else{
          push(@list, "$current_directory$file");
      }
  }
return @list;
}

#given a directory, returns a path to every sub directory
sub list_directories{
  my @list;
  my $current_directory = $_[0];
  opendir my $dir, $current_directory or die "Cannot open directory: $!";
  my @files = readdir $dir;
  closedir $dir;

  for my $file (@files)
  {
      if(-d "$current_directory$file"){
        if( !($file eq '.') && !($file eq '..') ){
            push(@list, "$current_directory$file");
            push( @list, list_directories("$current_directory$file/"));
          }
        }
  }
return @list;
}

sub list{
  my ($directory_to_list, $list_type) = @_;
  my @list;

  #replace ~ with absolute path
  if($directory_to_list =~ /^~(?<dir>.*)/){
  $directory_to_list = "/home/".getpwuid($<)."/$+{dir}";
  }
  #add trailing '/'
  if(!($directory_to_list =~/.*\/$/)){
    $directory_to_list .= '/';
  }

  if($list_type eq "files"){
    @list = list_files($directory_to_list);

    for (my $i = 0; $i < @list; $i++){
      $list[$i] =~ /(?<file_name>[a-zA-Z0-9\.\-\_\~]+$)/;
      $list[$i] = $+{file_name};
    }
  }
  elsif($list_type eq "directories"){
    @list = list_directories($directory_to_list);
    for (my $i = 0; $i < @list; $i++){
      $list[$i] =~ /(?<dir_name>[a-zA-Z0-9\.\-\_\~]+$)/;
      $list[$i] = $+{dir_name};
    }
  }
  elsif($list_type eq "files_absolute"){
    @list = list_files($directory_to_list);
  }
  elsif($list_type eq "files_relative"){
    @list = list_files($directory_to_list);

    for (my $i = 0; $i < @list; $i++){
      my $re = qr/$directory_to_list/;
      $list[$i] =~ /${re}(?<file_name>.*$)/;
      $list[$i] = $+{file_name};
    }
  }
  elsif($list_type eq "directories_absolute"){
    @list = list_directories($directory_to_list);
  }
  elsif($list_type eq "directories_relative"){
    @list = list_directories($directory_to_list);
    for (my $i = 0; $i < @list; $i++){
      my $re = qr/$directory_to_list/;
      $list[$i] =~ /${re}(?<file_name>.*$)/;
      $list[$i] = $+{file_name};
    }
  }
  else{
      print "list takes a directory path, and one of the following parameters: 'files, files_relative, files_absolute, directories, directories_relative, or directories_absolute\n";
  }

  return @list;
}
1;
