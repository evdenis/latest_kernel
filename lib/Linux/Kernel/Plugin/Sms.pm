package Linux::Kernel::Plugin::Sms;

use warnings;
use strict;

use Digest::SHA qw(sha512_hex);
use Getopt::Long qw(:config gnu_compat permute no_getopt_compat pass_through);


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
      unless exists $opts->{file} && exists $opts->{ua};

   my $text = $self->{text};

   $text =~ s/###([^#]++)###/my $k = lc($1); exists $opts->{$k} && length $opts->{$k} < 40? $opts->{$k} : $1/gep;

   #valid only for 10 minutes
   my $token = $opts->{ua}->get('https://sms.ru/auth/get_token')->res->body;

   my $tx = $opts->{ua}->post(
      'https://sms.ru/sms/send' => form => {
         api_id => $self->{api_id},
         login  => $self->{login},
         sha512 => sha512_hex($self->{password} . $token . $self->{api_id}),
         token  => $token,
         to     => $self->{to},
         text   => $text
      }
   );

   if (my $res = $tx->success) {
      print "SMS: " . $res->body . "\n"
   } else {
      my $err = $tx->error;
      die "$err->{code} response: $err->{message}"
         if $err->{code};
      die "Connection error: $err->{message}";
   }

   undef
}

1;
