package Linux::Kernel;

use warnings;
use strict;

use Exporter qw/import/;

our @EXPORT_OK = qw/get_available_kernels name_from_link/;

use constant KERNEL_PAGE => 'https://www.kernel.org/';


sub get_available_kernels
{
   my $dir = $_[0];

   my @kernels = do {
      opendir ((my $fh), $dir);
      my @contents = readdir $fh;
      closedir $fh;
      grep { -f $_ && $_ =~ m/\Alinux-\d\.\d\d\.tar\.(?:\w){2,3}\z/ } @contents;
   };

   \@kernels
}

sub name_from_link
{
   substr($_[0], rindex($_[0], '/') + 1)
}


1;
