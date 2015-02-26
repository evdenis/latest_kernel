package Linux::Kernel::Plugin::Email;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use Mail::Sendmail;


sub process_options
{
   my ($self, $config, $plugins) = @_;

   bless { priority => ($plugins->[-1]{priority} + 1) }, $self;
}

sub priority
{
   $_[0]->{priority}
}

sub action
{

   %mail = ( To      => $self->{to},
             From    => $self->{from},
             Message => $self->{message}
   );

   sendmail(%mail) or
      die "FAIL: $Mail::Sendmail::error";
}
