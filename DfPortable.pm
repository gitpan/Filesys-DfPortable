package Filesys::DfPortable;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;
require DynaLoader;
require 5.006;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(dfportable);
$VERSION = '0.82';
bootstrap Filesys::DfPortable $VERSION;

sub dfportable {
my ($dir, $block_size) = @_;

	(defined($dir)) ||
		(croak "Usage: df\(\$dir\) or df\(\$dir\, \$block_size)");

	#### If no requested block size then we will return the values in bytes
	($block_size) ||
		($block_size = 1);

	my ($frsize, $blocks, $bfree, $bavail) = _dfportable($dir);

	if($frsize == 0) {
		$! = "_dfportable call failed\n";
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

	#print "frsize:$frsize blocks:$blocks bfree:$bfree bavail:$bavail\n";

	return($blocks, $bfree, $bavail);
}

1;
__END__

=head1 NAME

Filesys::DfPortable - Perl extension for filesystem space.

=head1 SYNOPSIS


  use Filesys::DfPortable;


  ($blocks, $bfree, $bavail) = dfportable("c:\\"); # Default block size is 1, which outputs bytes
  if(defined($blocks)) {
     print"Total bytes: $blocks\n";
     print"Total bytes free: $bfree\n";
     print"Total bytes avail to me: $bavail\n"
  }


  ($blocks, $bfree, $bavail) = dfportable("/tmp", 1024); # Display output in 1K blocks
  if(defined($blocks)) {
     print"Total 1k blocks: $blocks\n";
     print"Total 1k blocks free: $bfree\n";
     print"Total 1k blocks avail to me: $bavail\n"
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

The values returned are as followed:
blocks = Total blocks for the filesystem.
bfree = Total blocks free on the filesystem.
bavail = Total blocks available to the user executing the Perl 
application. This can be different than bfree if you have per-user 
quotas on the filesystem, or if the super user has a reserved amount.
bavail can also be a negative value because of this.

If the dfportable() call fails for any reason, it will return
undef and set $!. This will probably happen if you do anything
crazy like try to get the space for /proc, or if you pass an invalid
filesystem, or if there is an internal error. dfportable() will 
croak() if you pass it a undefined value.


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
