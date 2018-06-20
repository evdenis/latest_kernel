package Linux::Kernel::Get;

use warnings;
use strict;

use Mojo::UserAgent;
use Mojo::DOM;
use List::Util qw/any/;
use File::Spec::Functions qw/catfile/;
use Linux::Kernel;

use Exporter qw/import/;

our @EXPORT_OK = qw/link_to_latest_kernel link_to_kernel_version/;

sub link_to_latest_kernel
{
   my ($ua) = @_;

   my $link = $ua->get(Linux::Kernel::KERNEL_PAGE)->res->dom->find('#latest_link > a:nth-child(1)')->map(attr => 'href')
     ->join("\n");

   Linux::Kernel::KERNEL_PAGE . $link;
}

sub link_to_kernel_version
{
   my ($version) = @_;
   my @v = split /\./, $version;
   my $link;

   if ($v[0] == 2) {
      $link = Linux::Kernel::KERNEL_LONGTERM_VERSIONS . "/v$v[0].$v[1].$v[2]/linux-$version.tar.gz";
   } else {
      $link = Linux::Kernel::KERNEL_X_VERSIONS . "/v$v[0].x/linux-$version.tar.xz";
   }

   $link;
}

1;
