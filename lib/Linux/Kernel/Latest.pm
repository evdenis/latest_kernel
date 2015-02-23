package Linux::Kernel::Latest;

use warnings;
use strict;

use Mojo::UserAgent;
use Mojo::DOM;
use List::Util qw/any/;
use File::Spec::Functions qw/catfile/;

use Exporter qw/import/;

our @EXPORT = qw/latest_kernel/;

use constant KERNEL_PAGE => 'https://www.kernel.org/';

sub latest_kernel
{
   my ($ua) = @_;

   $ua->get(KERNEL_PAGE)
      ->res
      ->dom
      ->find('#latest_link > a:nth-child(1)')
      ->map(attr => 'href')
      ->join("\n")
}

1;
