use Test::More;

use CPAN::Mini::Inject;
use File::Path;

mkdir( 't/local/MYCPAN' );

my $mcpi;
$mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg;

my $archive_file = 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz';
ok( -e $archive_file, "file <$archive_file> exists" );

$mcpi->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.01',
  file     => $archive_file
 )->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.02',
  file     => $archive_file
 );

my $soriche_path = File::Spec->catfile( 'S', 'SS', 'SSORICHE' );
is( $mcpi->{authdir}, $soriche_path, 'author directory' );
ok(
  -r 't/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz',
  'Added module is readable'
);
my $module
 = "CPAN::Mini::Inject                 0.02  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz";
ok( grep( /$module/, @{ $mcpi->{modulelist} } ),
  'Module added to list' );
is( grep( /^CPAN::Mini::Inject\s+/, @{ $mcpi->{modulelist} } ),
  1, 'Module added to list just once' );

SKIP: {
  skip "Not a UNIX system", 2 if ( $^O =~ /^MSWin|^cygwin/ );
  my $dir = 't/local/MYCPAN/authors/id/S/SS/SSORICHE';
  ok( -e $dir, "Author dir <$dir> exists" );
  is( (stat($dir))[2] & 07777, 0775, "author dir <$dir> mode is 0775" );

  my $file = "$dir/CPAN-Mini-Inject-0.01.tar.gz";
  ok( -e $file, "Author file <$file> exists" );
  is( (stat($file))[2] & 07777, 0664, "Added module <$file> mode is 0664" );
}

# XXX do the same test as above again, but this time with a ->readlist after
# the ->parsecfg

rmtree( 't/local/MYCPAN', 0, 1 );

done_testing();
