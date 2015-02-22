package Linux::Kernel::Plugin::Configure;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use File::Slurp qw/read_file/;
use List::Util qw/any/;


sub process_options
{
   my ($self, $config) = @_;
   my $file;

   GetOptions(
      'plugin-configure-file=s' => \$file,
   ) or die("Error in command line arguments\n");


   unless (any {$_ eq 'unpack'} @{$config->{plugins}}) {
      die "Unpack plugin should be loaded.\n"
   }

   die "Option --plugin-configure-file should be provided.\n"
      unless $file;

   if (-f $file && -r _) {
      $file = read_file $file
   } else {
      die "Can't access file $file.\n"
   }

   $config->{'configure-file'} = $file;

   bless { file => $file }, $self
}

sub priority
{
   1
}

sub action
{
   ...
}


1;
