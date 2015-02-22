package Linux::Kernel::Plugin::Unpack;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);

sub process_options
{
   my ($self, $config) = @_;
   my $dir;

   GetOptions(
      'plugin-unpack-dir=s' => \$dir,
   ) or die("Error in command line arguments\n");

   die "Option --plugin-unpack-dir should be provided.\n"
      unless $dir;

   unless (-d $dir && -r _) {
      die "Can't access $dir.\n"
   }

   $config->{'unpack-dir'} = $dir;

   bless { dir => $dir }, $self
}

sub priority
{
   0
}

sub action
{
   ...
}


1;
