package Linux::Kernel::Plugin::Sms;

use warnings;
use strict;

use Digest::SHA qw(sha512_hex);
use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);


sub process_options
{
   my ($self, $config, $plugins) = @_;
   my $text = << "END";
There is a new version of Linux kernel ###VERSION### available at https://kernel.org
END
   my ($login, $password, $api_id, $to);

   GetOptions(
      'plugin-sms-to=s'       => \$to,
      'plugin-sms-login=s'    => \$login,
      'plugin-sms-password=s' => \$password,
      'plugin-sms-api_id=s'   => \$api_id,
      'plugin-sms-text=s'     => \$text,
   ) or die("Error in command line arguments\n");

   die "Option --plugin-sms-to should be provided.\n"
      unless $to;
   die "Option --plugin-sms-login should be provided.\n"
      unless $login;
   die "Option --plugin-sms-password should be provided.\n"
      unless $password;
   die "Option --plugin-sms-api_id should be provided.\n"
      unless $api_id;

   die "Wrong format of --plugin-sms-to option. Please use numbers only with optional + prefix\n"
      unless $to =~ /\+?\d++/;

   bless { priority => ((@$plugins ? $plugins->[-1]->priority : 0) + 1), # dynamic priority
           to       => $to,
           login    => $login,
           password => $password,
           api_id   => $api_id,
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

   my $text = $self->{text};

   $text =~ s/###([^#]++)###/my $k = lc($1); exists $opts->{$k} && length $opts->{$k} < 40? $opts->{$k} : $1/gep;

   #valid only for 10 minutes
   my $token = $self->{ua}->get('http://sms.ru/auth/get_token')->res->body;

   my $res = $self->{ua}->post(
      'http://sms.ru/sms/send' =>
         api_id => $opts->{api_id},
         login  => $opts->{login},
         sha512 => sha512_hex($opts->{password} . $token . $opts->{api_id}),
         token  => $token,
         to     => $opts->{to},
         text   => $text
   );

   undef
}

1;
