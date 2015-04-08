package Linux::Kernel::Plugin::Email;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use Email::Stuffer;

sub process_options
{
   my ($self, $config, $plugins) = @_;
   my $dir;
   my $subj = "Linux kernel release ###VERSION###";
   my $text = << "END";
There is a new version of Linux kernel available at https://kernel.org
LINK: ###LINK###
END
   my $from;
   my $to;

   GetOptions(
      'plugin-email-from=s' => \$from,
      'plugin-email-to=s'   => \$to,
      'plugin-email-subj=s' => \$subj,
      'plugin-email-text=s' => \$text,
   ) or die("Error in command line arguments\n");

   die "Option --plugin-email-from should be provided.\n"
      unless $from;
   die "Option --plugin-email-to should be provided.\n"
      unless $to;

   bless { priority => ((@$plugins ? $plugins->[-1]->priority : 0) + 1), # dynamic priority
           from     => $from,
           to       => $to,
           subj     => $subj,
           text     => $text }, $self;
}

sub priority
{
   $_[0]->{priority}
}

sub action
{
   my ($self, $opts) = @_;

   return undef
      unless exists $opts->{file};

   my $subj = $self->{subj};
   my $text = $self->{text};

   foreach ($subj, $text) {
      s/###([^#]++)###/my $k = lc($1); exists $opts->{$k} ? $opts->{$k} : ${^MATCH}/gep
   }

   Email::Stuffer
      ->text_body($text)
      ->subject($subj)
      ->from($self->{from})
      ->to($self->{to})
      ->send_or_die;

   undef
}

1;
