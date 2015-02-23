package Linux::Kernel::Plugin::Download;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use Mojo::UserAgent;
use Mojo::DOM;
use List::Util qw/any/;
use File::Spec::Functions qw/catfile/;

use constant KERNEL_PAGE => 'https://www.kernel.org/';

$ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824; # 1GB


sub _get_available_kernels
{
   my $self = $_[0];

   my @kernels = do {
      opendir ((my $fh), $self->{dir});
      my @contents = readdir $fh;
      closedir $fh;
      grep { -f $_ && $_ =~ m/\Alinux-\d\.\d\d\.tar\.(?:\w){2,3}\z/ } @contents;
   };

   $self->{downloaded} = \@kernels;
}


sub process_options
{
   my ($self, $config) = @_;
   my $dir;

   GetOptions(
      'plugin-download-dir=s' => \$dir,
   ) or die("Error in command line arguments\n");

   unless ($dir) {
      if (exists $config->{working_dir}) {
         $dir = $config->{working_dir};
         goto CHECKED;
      } else {
         die "Option --plugin-download-dir should be provided.\n"
      }
   }

   unless (-d $dir && -r _ && -x _) {
      die "Can't access $dir.\n"
   }

CHECKED:
   $config->{'download-dir'} = $dir;

   my $obj = bless { dir => $dir }, $self;
   $obj->_get_available_kernels;

   $obj
}

sub priority
{
   10
}

sub action
{
   my ($self, $opts) = @_;

   return undef
      unless exists $opts->{link};

   my $name = substr $opts->{link}, rindex($opts->{link}, '/') + 1;

   unless (any { $name eq $_ } @{$self->{downloaded}}) {
      print "DOWNLOADING: $name\n";
      my $file = catfile($self->{dir}, $name);
      $opts->{ua}->get(KERNEL_PAGE . $opts->{link})
         ->res
         ->content
         ->asset
         ->move_to($file);
      push @{$self->{downloaded}}, $name;

      $opts->{file} = $file;
      return $file;
   }

   undef
}


1;
