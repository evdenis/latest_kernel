package Linux::Kernel::Plugin::Unpack;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use File::Spec::Functions qw/catdir/;

sub process_options
{
   my ($self, $config) = @_;
   my $dir;

   GetOptions(
      'plugin-unpack-dir=s' => \$dir,
   ) or die("Error in command line arguments\n");

   unless ($dir) {
      if (exists $config->{working_dir}) {
         $dir = $config->{working_dir};
         goto CHECKED;
      } else {
         die "Option --plugin-unpack-dir should be provided.\n"
      }
   }

   unless (-d $dir && -r _) {
      die "Can't access $dir.\n"
   }

CHECKED:
   $config->{'unpack-dir'} = $dir;

   bless { dir => $dir }, $self
}

sub priority
{
   10
}

sub action
{
   my ($self, $opts) = @_;

   return undef
      unless exists $opts->{file};

   print "UNPACKING $opts->{file} to directory $self->{dir}\n";
   system('tar', 'xf', $opts->{file}, '-C', $self->{dir}) == 0 or
      die "UNPACK FAIL\n";
   my $dir = $opts->{file} =~ s/\.tar\.(?:\w){2,3}\z//r;
   $dir = catdir $self->{dir}, $dir;
   if (-d $dir) {
      $opts->{'kernel-dir'} = $dir
   }
}


1;
