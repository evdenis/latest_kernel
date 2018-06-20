package Linux::Kernel::Plugin::Prepare;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat permute no_getopt_compat pass_through);
use POSIX ":sys_wait_h";

sub process_options
{
   my ($self, $config) = @_;

   bless {}, $self;
}

sub priority
{
   35;
}

sub action
{
   my ($self, $opts) = @_;

   return undef
     unless exists $opts->{'kernel-dir'};

   my $pid = fork();
   die "FAIL: can't fork $!"
     unless defined $pid;

   unless ($pid) {
      print "PREPARE: $opts->{'kernel-dir'}\n";
      chdir $opts->{'kernel-dir'};
      open(STDIN,  '</dev/null');
      open(STDOUT, '>/dev/null');
      exec(qw/make modules_prepare/);
   }

   waitpid $pid, 0;

   undef;
}

1;
