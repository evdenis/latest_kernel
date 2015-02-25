package Linux::Kernel::Plugin::Compile;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use File::Spec::Functions qw/catfile/;
use POSIX ":sys_wait_h";

sub process_options
{
   my ($self, $config) = @_;
   my $wait = 1;
   my $target = '';
   my $jobs = 3;

   GetOptions(
      'plugin-compile-wait!'    => \$wait,
      'plugin-compile-target=s' => \$target,
      'plugin-compile-jobs=i'   => \$jobs,
   ) or die("Error in command line arguments\n");

   $config{'compile-wait'}   = $wait;
   $config{'compile-target'} = $target;
   $config{'compile-jobs'}   = $jobs;

   bless { wait => $wait, target => $target, jobs => $jobs }, $self
}

sub priority
{
   40
}

sub action
{
   my ($self, $opts) = @_;

   return undef
      unless exists $opts->{'kernel-dir'};

   die "FAIL: PLUGINS CONFLICT\n"
      if exists $opts->{'vmlinux'};


   my $pid = fork();
   die "FAIL: can't fork $!"
      unless defined $pid;

   unless ($pid) {
      print "COMPILE: $opts->{'kernel-dir'}\n";
      chdir $opts->{'kernel-dir'};
      open (STDIN,  '</dev/null');
      open (STDOUT, '>/dev/null');
      exec('make', '-j', $self->{jobs}, $self->{target} || ());
   }

   if ($self->{wait}) {
      waitpid $pid, 0;
      #TODO: add bzImage handling
      my $vmlinux = catfile $opts->{'kernel-dir'}, 'vmlinux';
      if (-e $vmlinux) {
         $opts->{'vmlinux'} = $vmlinux;
         return $vmlinux
      }
   }

   undef
}


1;
