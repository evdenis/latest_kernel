package Linux::Kernel::Plugin::Sms;

use warnings;
use strict;

use LWP::Simple;
use HTTP::Request::Common qw(POST);
use Digest::SHA qw(sha512_hex);

sub process_options
{
}

sub action
{
   #valid only for 10 minutes
   my $token = $self->{ua}->get('http://sms.ru/auth/get_token')->res->body;

   my $res = $self->{ua}->post(
      'http://sms.ru/sms/send' =>
         api_id => '' ,
         login  => '',
         sha512 => sha512_hex("ваш пароль".$token."api_id"),
         token  => $token,
         to     => '',
         text   => 'hello world'
   );

   #print $ua->request($req)->res->code;
   #->res->content
}

