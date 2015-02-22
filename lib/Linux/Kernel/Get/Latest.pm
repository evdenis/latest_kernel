package Linux::Kernel::Get::Latest;

use warnings;
use strict;

use Mojo::UserAgent;
use Mojo::DOM;
use List::Util qw/any/;
use File::Spec::Functions qw/catfile/;

use Exporter qw/import/;

our @EXPORT = qw/get_latest_kernel/;


use constant KERNEL_PAGE => 'https://www.kernel.org/';

$ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824; # 1GB


sub _get_available_kernels
{
   my ($dir) = @_;

   my @kernels = do {
      opendir ((my $fh), $dir);
      my @contents = readdir $fh;
      closedir $fh;
      grep { -f $_ && $_ =~ m/linux-\d\.\d\d\.tar\.xz/ } @contents;
   };

   \@kernels
}

sub get_latest_kernel
{
   my ($ua, $dir, $available) = @_;

   $available = _get_available_kernels $dir
      unless $available;

   my $latest_link = $ua->get(KERNEL_PAGE)
                        ->res
                        ->dom
                        ->find('#latest_link > a:nth-child(1)')
                        ->map(attr => 'href')
                        ->join("\n");

   my $name = substr $latest_link, rindex($latest_link, '/') + 1;
   print "LATEST KERNEL: $name\n";

   unless (any { $name eq $_ } @$available) {
      print "DOWNLOADING: $name\n";
      my $file = catfile($dir, $name);
      $ua->get(KERNEL_PAGE . $latest_link)
         ->res
         ->content
         ->asset
         ->move_to($file);
      push $available, $name;
      return $file
   }

   undef
}

1;
