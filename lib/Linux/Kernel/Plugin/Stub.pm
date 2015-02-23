package Linux::Kernel::Plugin::Stub;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use File::Spec::Functions qw/catfile/;


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
   my $times = 1; # 1 for once; -1 - forever

   GetOptions(
      'plugin-stub-dir=s'   => \$dir,
      'plugin-stub-times=i' => \$times,
   ) or die("Error in command line arguments\n");

   unless ($dir) {
      if (exists $config->{working_dir}) {
         $dir = $config->{working_dir};
         goto CHECKED;
      } else {
         die "Option --plugin-stub-dir should be provided.\n"
      }
   }

   unless (-d $dir && -r _ && -x _) {
      die "Can't access $dir.\n"
   }

CHECKED:
   $config->{'stub-dir'} = $dir;
   $config->{'stub-times'} = $times;

   my $obj = bless { dir => $dir, times => $times }, $self;
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

   die "PLUGINS CONFLICT\n"
      if exists $opts->{file};

   my $name = substr $opts->{link}, rindex($opts->{link}, '/') + 1;

   if ($self->{times} > 0 || $self->{times} == -1) {
      my $file = catfile($self->{dir}, $name);
      if (-r $file) {
         $opts->{file} = $file;
         $self->{times}--
            if $self->{times} > 0;
         return $file;
      }
   }

   undef
}


1;
