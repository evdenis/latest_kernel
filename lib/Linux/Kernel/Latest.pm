package Linux::Kernel::Latest;

use warnings;
use strict;

use Mojo::UserAgent;
use Mojo::DOM;
use List::Util qw/any/;
use File::Spec::Functions qw/catfile/;
use Linux::Kernel;

use Exporter qw/import/;

our @EXPORT = qw/latest_kernel/;


sub latest_kernel
{
   my ($ua) = @_;

   my $link = $ua->get(Linux::Kernel::KERNEL_PAGE)
                 ->res
                 ->dom
                 ->find('#latest_link > a:nth-child(1)')
                 ->map(attr => 'href')
                 ->join("\n");

   Linux::Kernel::KERNEL_PAGE . $link
}

1;
