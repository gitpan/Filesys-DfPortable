package Filesys::DfPortable;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;
require DynaLoader;
require 5.006;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(dfportable);
$VERSION = '0.83';
bootstrap Filesys::DfPortable $VERSION;

sub dfportable {
my ($dir, $block_size) = @_;
my %fs;
my $used;
my $per;

	(defined($dir)) ||
		(croak "Usage: df\(\$dir\) or df\(\$dir\, \$block_size)");

	#### If no requested block size then we will return the values in bytes
	($block_size) ||
		($block_size = 1);

	my ($frsize, $blocks, $bfree, $bavail) = _dfportable($dir);

	#### Some system or XS failure, or something like /proc
	if($frsize == 0 || $blocks == 0) {
		return();
	}

	#### Change to requested or default block size
	if($block_size > $frsize) {
		my $result = $block_size / $frsize;
		$blocks /= $result;
		($bfree != 0) &&
			($bfree /= $result);
		#### Keep bavail -
		($bavail < 0) &&
			($result *= -1);

		($bavail != 0) &&
			($bavail /= $result);
	}

	elsif($block_size < $frsize) {
		my $result = $frsize / $block_size;
		$blocks *= $result;
		$bfree *= $result;
		#### Keep bavail -
		($bavail < 0) &&
			($result *= -1);
		$bavail *= $result;
	}

	$used = $blocks - $bfree;

	#### There is a reserved amount for the su
	#### or there are disk quotas
        if($bfree > $bavail) {
                my $user_blocks = $blocks - ($bfree - $bavail);
                my $user_used = $user_blocks - $bavail;
                if($bavail < 0) {
                        #### over 100%
                        my $tmp_bavail = $bavail;
                        $per = ($tmp_bavail *= -1) / $user_blocks;
                }
                                                                                                         
                else {
                        $per = $user_used / $user_blocks;
                }
        }
                                                                                                         
        #### No reserved amount or quotas
        else {
                if($used == 0)  {
                        $per = 0;
                }
                                                                                                         
                else {
                        $per = $used / $blocks;
                }
        }

	#### round
        $per *= 100;
        $per += .5;
                                                                                                         
        #### over 100%
        ($bavail < 0) &&
                ($per += 100);
                                                                                                         
        $fs{per} = int($per);
	$fs{blocks} = $blocks;
	$fs{bfree} = $bfree;
	$fs{bavail} = $bavail;
	$fs{bused} = $used;

	return(\%fs);
}

1;
__END__

=head1 NAME

Filesys::DfPortable - Perl extension for filesystem space.

=head1 SYNOPSIS


  use Filesys::DfPortable;

  my $ref = dfportable("C:\\"); # Default block size is 1, which outputs bytes
  if(defined($ref)) {
     print"Total bytes: $ref->{blocks}\n";
     print"Total bytes free: $ref->{bfree}\n";
     print"Total bytes avail to me: $ref->{bavail}\n";
     print"Total bytes used: $ref->{bused}\n";
     print"Percent full: $ref->{per}\n"
  }
                                                                                                                
                                                                                                                
  my $ref = dfportable("/tmp", 1024); # Display output in 1K blocks
  if(defined($ref)) {
     print"Total 1k blocks: $ref->{blocks}\n";
     print"Total 1k blocks free: $ref->{bfree}\n";
     print"Total 1k blocks avail to me: $ref->{bavail}\n";
     print"Total 1k blocks used: $ref->{bused}\n";
     print"Percent full: $ref->{per}\n"
  }



=head1 DESCRIPTION

This module provides a portable way to obtain filesystem 
disk space information.

The module should work with all versions of Windows (95 and up),
all flavors of Unix, Mac OS X (Darwin, Tiger, etc), and Cygwin.

dfportable() requires a directory argument that represents the filesystem
you want to query. There is also an optional block size argument so the
you can tailor the size of the values returned. The default for block
size is 1, this will cause the function to return the values in bytes.
If you never use the block size argument, then you can think of any
instance of "blocks" in this document to really mean "bytes". 

dfportable() returns a reference to a hash. The keys available in 
the hash are as follows:

{blocks} = Total blocks on the filesystem.

{bfree} = Total blocks free on the filesystem.

{bavail} = Total blocks available to the user executing the Perl 
application. This can be different than bfree if you have per-user 
quotas on the filesystem, or if the super user has a reserved amount.
bavail can also be a negative value because of this. For instance
if there is more space being used than on the disk than is available
to you.

{bused} = Total blocks used on the filesystem.

{per} = Percent of disk space used. This is based on the disk space
available to the user executing the application. In other words, if
the filesystem has 10% of its space reserved for the superuser, then
the percent used can go up to 110%.)


If the dfportable() call fails for any reason, it will return
undef. This will probably happen if you do anything crazy like try
to get the space for /proc, or if you pass an invalid filesystem name,
or if there is an internal error. dfportable() will croak() if you pass
it a undefined value.


Requirements:
Your system must contain statvfs(), statfs(), GetDiskFreeSpaceA(), or GetDiskFreeSpaceEx().
You must be running Perl 5.6 or higher.


=head1 AUTHOR

Ian Guthrie
IGuthrie@aol.com

Copyright (c) 2006 Ian Guthrie. All rights reserved.
               This program is free software; you can redistribute it and/or
               modify it under the same terms as Perl itself.

=head1 SEE ALSO

statvfs(2), df(1M), statfs(1M), GetDiskFreeSpaceA, GetDiskFreeSpaceEx

perl(1).

=cut
