package Linux::Kernel::Plugin::Defconfig;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat permute no_getopt_compat pass_through);
use File::Spec::Functions qw/catfile/;
use POSIX ":sys_wait_h";

sub process_options
{
   my ($self, $config) = @_;

   bless {}, $self
}

sub priority
{
   30
}

sub action
{
   my ($self, $opts) = @_;

   return undef
      unless exists $opts->{'kernel-dir'};

   die "FAIL: PLUGINS CONFLICT\n"
      if exists $opts->{'kernel-config'};


   my $pid = fork();
   die "FAIL: can't fork $!"
      unless defined $pid;

   unless ($pid) {
      print "DEFCONFIG: $opts->{'kernel-dir'}\n";
      chdir $opts->{'kernel-dir'};
      open (STDIN,  '</dev/null');
      open (STDOUT, '>/dev/null');
      exec(qw/make defconfig/);
   }

   waitpid $pid, 0;

   my $cfg_file = catfile $opts->{'kernel-dir'}, '.config';
   if (-f $cfg_file) {
      $opts->{'kernel-config'} = $cfg_file;
      return $cfg_file
   }

   undef
}


1;
