package Linux::Kernel::Plugin::Configure;

use warnings;
use strict;

use Getopt::Long qw(:config gnu_compat no_permute no_getopt_compat pass_through);
use List::Util qw/any/;
use IO::Handle;
use IO::Select;
use File::Spec::Functions qw/catfile/;
require 'sys/ioctl.ph';


sub _read_config
{
   my $file = $_[0];
   my %config;

   open my $f, '<', $file
      or die "Can't open $file.\n";

   while(<$f>) {
      chomp;
      s/#.*+//;
      if (m/\A\h*+\Z/) {
         next
      }
      if (m/\A\h*+(\w++)\h++(yes|mod|no)\h*+\Z/) {
         $config{$1} = $2
      } else {
         warn "Error in line '$_'. Ignoring.\n"
      }
   }

   \%config
}

sub process_options
{
   my ($self, $config) = @_;
   my $file;

   GetOptions(
      'plugin-configure-file=s' => \$file,
   ) or die("Error in command line arguments\n");

   unless (any {$_ eq 'unpack'} @{$config->{plugins}}) {
      die "Unpack plugin should be loaded.\n"
   }

   die "Option --plugin-configure-file should be provided.\n"
      unless $file;

   my ($cfg, $date);
   if (-f $file && -r _) {
      $date = (stat(_))[9];
      $cfg = _read_config $file;
      die "FAIL: Configure file is empty.\n"
         unless %$cfg;
   } else {
      die "FAIL: Can't access file $file.\n"
   }

   $config->{'configure-file'} = $file;

   bless { file => $file, config => $cfg, date => $date }, $self
}

sub priority
{
   30
}

sub action
{
   my ($self, $opts) = @_;

   return undef
      unless exists $opts->{'kernel-dir'};

   die "FAIL: PLUGINS CONFLICT\n"
      if exists $opts->{'kernel-config'};

   my $date = (stat($self->{file}))[9];
   if ($date > $self->{date}) {
      print "CONFIGURE: Rereading configuration file $self->{file}.\n";
      $self->{config} = _read_config $self->{file};
      die "FAIL: CONFIGURE: Configure file is empty.\n"
         unless %{$self->{config}};
   }
   my %config = %{$self->{config}}; # copy

   my ($parent_read, $parent_write);
   my ($child_read,  $child_write);

   pipe($parent_read, $child_write) and
   pipe($child_read,  $parent_write) or
      die "FAIL: CONFIGURE: Failed to setup pipe: $!\n";
   $parent_write->autoflush(1);
   $child_write->autoflush(1);
   #autoflush STDOUT 1;
   $child_read->blocking(1);
   $parent_read->blocking(1);


   if (my $pid = fork()) {
      close $parent_read; close $parent_write;

      my %answers = (
         yes => 'y',
         no  => 'n',
         mod => 'm',
         y   => 'y',
         n   => 'n',
         m   => 'm',
         module => 'm'
      );

      my $s = IO::Select->new();
      $s->add($child_read);
      my $fd;
      my $lastline = '';

      while (1) {
         $fd = undef;
         ($fd) = $s->can_read(1);
         if ($fd) {
            my $size = pack("L", 0);
            $child_read->ioctl(FIONREAD(), $size);
            $size = unpack("L", $size);

            last unless $size;

            $child_read->read(my $c, $size);
            #print "$c";
            $lastline .= $c;
            if ($lastline =~ m/\[[^]]*+\]:?\h*+(\(NEW\)\h*+)?\Z/) {
               my $ok = 0;
               foreach my $k (keys %config) {
                  if (rindex($lastline, $k) != -1) {
                     print $child_write "$answers{$config{$k}}\n";
                     print "CONFIGURE: SWITCH: $k $config{$k}\n";
                     delete $config{$k};
                     $ok = 1;
                    last
                  }
               }

               print $child_write "\n"
                  unless $ok;
               $lastline = '';
            }
         }
      }

      waitpid($pid, 0);

      foreach (keys %config) {
         print STDERR "CONFIGURE: UNDEF: $_\n"
      }
   } else {
      close $child_read; close $child_write;

      chdir $opts->{'kernel-dir'};

      open STDOUT, '>&', $parent_write;
      open STDIN,  '<&', $parent_read;
      #system qw/make defconfig/; # TODO: do we really need this?
      exec qw/make config/;
   }

   my $cfg_file = catfile $opts->{'kernel-dir'}, '.config';
   if (-f $cfg_file) {
      $opts->{'kernel-config'} = $cfg_file;
      return $cfg_file
   }

   undef
}


1;
