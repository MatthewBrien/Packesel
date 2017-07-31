#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Cwd 'abs_path';
use Cwd 'getcwd';
require "/home/rpmmaker/packesel/list.pl";

#command line default arguments
my $source = '';
my $name = '';
my $verbose = '';

my $timestamp = time();
my $source_type = '';
my $working_directory = '';
my @files;
my $SPEC_FILE_HANDLE;
my $spec_file_location = '';
my $build_source_location = '';

GetOptions(
'source=s' => \$source,
'name=s' => \$name,
'verbose' => \$verbose
) or die "Usage: $0 --source Dir or Git Repo, --name, --verbose";

sub say{ print @_, "\n" }

#make a system call without getting terminal output unless -Verbose has been specified
sub quiet_system {
  if(!$verbose){
    return system "@_ > /dev/null 2>&1";
  }
  else{
    return system "@_";
  }
}

#test if a string is a Git-URL
sub is_git_url{
  if($_[0] =~ /http.*\.git/)
  {  return 1;}
  else
  {  return 0;}
}

#test if a path is valid
sub is_valid_path{
  #append end slash if necessary
  if(!($_[0] =~ /.*\/$/)){
    $_[0].='/';
  }
  if(quiet_system("ls $_[0]"))
  {  return 0;}
  else
  {  return 1;}
}

#test if a local directory is a git repo
sub is_git_repo{
  #if param passed, check if that directory is a git repo
  #otherwise, check current directory
  if (@_){
      if(quiet_system ("git -C $_[0] rev-parse"))
      {return 0;}
  }
  else{
    if(quiet_system ("git rev-parse"))
      {return 0;}
  }
    return 1;
}

#set name for the rpm, it not a git repo, and name was not supplied, create new name
sub set_name{
  if(is_git_url($source)){
    if($source =~ /^http.*\/(?<name>.*).git$/){
      $name = $+{name};
    }
  }
  #TODO capture name of deepest directory for name
  elsif(is_valid_path($source)){
    if(!$name){
      $name = "newRPM".$timestamp;
    }
  }
  else{
    if(!$name){
      $name = "newRPM".$timestamp;
    }
  }
}
#validate user supplied path
sub set_source{
  if(!$source){
    $source = getcwd;
    quiet_system("echo 'No path specified, current directory selected.'");
  }
  set_source_type($source);
  if($source_type eq "dir" && !is_valid_path($source)){
    $source = getcwd;
    say ("$source is not a valid directory");
    say ("Use -source <git-repo or directory-path> to specify directory");
    exit;
  }
}
#set source type
sub set_source_type{
  if(is_git_url($source)){
    $source_type = "git";
  }
  else{
    $source_type = "dir";
  }
}

sub create_working_dir{
    $working_directory .= "/tmp/$name";
    quiet_system("mkdir $working_directory");
    say ("working_directory : $working_directory");
}

#remove files and folders created during process
sub clean_up{
  quiet_system("rm -rf $working_directory");
  #quiet_system("rm -rf $spec_file_location");
  #quiet_system("rm -rf $build_source_location");
}

set_source();
set_name();
create_working_dir();
$spec_file_location = "/home/".getpwuid($<)."/rpmbuild/SPECS/$name.spec";
$build_source_location = "/home/".getpwuid($<)."/rpmbuild/SOURCES/$name-1.0.tar.gz";

#if source is git repo, clone
if($source_type eq 'git'){
  if(quiet_system("git clone $source $working_directory")){
    say ("unable to access $source");
    exit;
  }
}

#list files, and zip

if($source_type eq 'git'){
  @files = list($working_directory);
  quiet_system("tar czvf $build_source_location $working_directory");
}
else{
  @files = list($source);
  print "source : $source\n";
  print "build source location: $build_source_location\n";
  quiet_system("cp -r $source /tmp/$name/$name-1.0");
  quiet_system("tar czvf $build_source_location -C $working_directory/ .");
}

for my $i(@files){
  print("$i\n");
}

#generate spec file


open( $SPEC_FILE_HANDLE,">", $spec_file_location) or die "couldn't not open file '$spec_file_location $!'";
print $SPEC_FILE_HANDLE "Name:           $name\n";
print $SPEC_FILE_HANDLE "Version:        1.0\n";
print $SPEC_FILE_HANDLE "Release:        1%{?dist}\n";
print $SPEC_FILE_HANDLE "Summary:        idk, look for a readme\n";
print $SPEC_FILE_HANDLE "Prefix:         /\n";
print $SPEC_FILE_HANDLE "License:        GPL\n";
print $SPEC_FILE_HANDLE "Source0:        $name-1.0.tar.gz\n";
print $SPEC_FILE_HANDLE "BuildArch:      noarch\n";
print $SPEC_FILE_HANDLE "%description    \nmove along, nothing to see here\n";
print $SPEC_FILE_HANDLE "\n";
print $SPEC_FILE_HANDLE "%prep\n";
print $SPEC_FILE_HANDLE "%setup -q\n";
print $SPEC_FILE_HANDLE "%install\n";
#print $SPEC_FILE_HANDLE "rm -rf \$RPM_BUILD_ROOT\n";
#print $SPEC_FILE_HANDLE "install -d \$RPM_BUILD_ROOT/$name\n";
for my $i (@files){
  $i =~ /.*(?<current_file>\/[a-zA-Z0-9.]+$)/;
#print $SPEC_FILE_HANDLE "install $+{current_file} \$RPM_BUILD_ROOT$i\n";
}
#install myscript1.sh $RPM_BUILD_ROOT/myscript/myscript1.sh
#install myscript2.sh $RPM_BUILD_ROOT/myscript/myscript2.sh
print $SPEC_FILE_HANDLE "%clean\n";
#print $SPEC_FILE_HANDLE "rm -rf \$RPM_BUILD_ROOT\n";
print $SPEC_FILE_HANDLE "%files\n";
print $SPEC_FILE_HANDLE "%defattr(-,root,root,-)\n";
for my $i(@files){
#  print $SPEC_FILE_HANDLE "$i\n";
}
print $SPEC_FILE_HANDLE "%doc\n";
print $SPEC_FILE_HANDLE "%changelog\n";
#* Thu Jul 27 2017 rpmmaker
#-
close($SPEC_FILE_HANDLE);
clean_up();

#setup temp folder
