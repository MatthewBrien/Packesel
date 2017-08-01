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
    $working_directory .= "~/rpmbuild/SOURCES/$name";
    quiet_system("mkdir $working_directory");
}

#remove files and folders created during process
sub clean_up{
  quiet_system("rm -rf $working_directory");
  quiet_system("rm -rf $spec_file_location");
  quiet_system("rm -rf $build_source_location");
  quiet_system("rm -rf /home/".getpwuid($<)."/rpmbuild/BUILD/$name");
}

set_source();
set_name();
create_working_dir();
$spec_file_location = "/home/".getpwuid($<)."/rpmbuild/SPECS/$name.spec";
$build_source_location = "/home/".getpwuid($<)."/rpmbuild/SOURCES/$name.tar.gz";

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

  quiet_system("cp -a $source/. ~/rpmbuild/SOURCES/$name");

  @files = list( "~/rpmbuild/SOURCES/$name", "relative");

  quiet_system("tar czvf $working_directory.tar.gz -C ~/rpmbuild/SOURCES/ $name" );
}


#generate spec file
open( $SPEC_FILE_HANDLE,">", $spec_file_location) or die "couldn't not open file '$spec_file_location $!'";
print $SPEC_FILE_HANDLE "Name:           $name\n";
print $SPEC_FILE_HANDLE "Version:        1.0\n";
print $SPEC_FILE_HANDLE "Release:        0\n";
print $SPEC_FILE_HANDLE "Summary:        idk, look for a readme\n";
print $SPEC_FILE_HANDLE "Prefix:         /usr\n";
print $SPEC_FILE_HANDLE "License:        none\n";
print $SPEC_FILE_HANDLE "Source0:        %{name}.tar.gz\n";
print $SPEC_FILE_HANDLE "BuildArch:      noarch\n";
print $SPEC_FILE_HANDLE "BuildRoot:      %{_tmppath}/%{name}-build";
print $SPEC_FILE_HANDLE "\n%description\nan RPM built by Packesel\n\n";
print $SPEC_FILE_HANDLE "\n%prep\n\n";
print $SPEC_FILE_HANDLE "\n%setup -n %{name}\n\n";
print $SPEC_FILE_HANDLE "\n%build\n\n";
print $SPEC_FILE_HANDLE "\n%install\n";
print $SPEC_FILE_HANDLE "mkdir -p \$RPM_BUILD_ROOT/%{name}\n";
for my $i (@files){
  $i =~ /^\/.*\/(?<current_file>.*+$)/;
print $SPEC_FILE_HANDLE "install $+{current_file} \$RPM_BUILD_ROOT/%{name}\n";
}

print $SPEC_FILE_HANDLE "\n%clean\n";
print $SPEC_FILE_HANDLE "rm -rf \$RPM_BUILD_ROOT\n";
print $SPEC_FILE_HANDLE "%files\n";
print $SPEC_FILE_HANDLE "%defattr(-,root,root,-)\n";
print $SPEC_FILE_HANDLE "/%{name}/\n";
for my $i(@files){
    $i =~ /^\/.*\/(?<current_file>.*$)/;
    print $SPEC_FILE_HANDLE "/%{name}/$+{current_file}\n";
}
print $SPEC_FILE_HANDLE "\n\n%doc\n";
print $SPEC_FILE_HANDLE "\n\n%changelog\n";
#* Thu Jul 27 2017 rpmmaker
#-
close($SPEC_FILE_HANDLE);

quiet_system("rpmbuild -v -bb /home/".getpwuid($<)."/rpmbuild/SPECS/$name.spec");

clean_up();

#setup temp folder
