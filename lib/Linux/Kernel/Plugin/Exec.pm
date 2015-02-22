package Linux::Kernel::Plugin::Exec;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);

sub process_options
{
   my ($self, $config) = @_;
   my $cmd;

   GetOptions(
      'plugin-exec-command=s' => \$cmd,
   ) or die("Error in command line arguments\n");

   die "Option --plugin-exec-command should be provided.\n"
      unless $cmd;

   $config->{'exec-command'} = $cmd;

   bless { cmd => $cmd }, $self
}

sub priority
{
   30
}

sub action
{
   ...
}


1;
