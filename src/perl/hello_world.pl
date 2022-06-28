use File::Basename;
use lib dirname (__FILE__);
use gnoll;

print "GNOLL in PERL\n";

# my $result = gnoll::roll_verbose("1d100+3");
# print $result;

my $result_file = 'result.die';
unlink($result_file);
my $result = gnoll::roll_and_write("1d100+3", $result_file);

open(FH, '<', $result_file) or die $!;
while(<FH>){
   print $_;
}
close(FH);

print "\n";
;