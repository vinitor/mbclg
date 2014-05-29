#! /usr/bin/perl
use Getopt::Long;
use Time::Piece;
use Time::Seconds;
#
$MY_ROOT=$ENV{HOME};
$MY_DATA=$MY_ROOT."/data";
$MY_TMP="/tmp";
#
# Create timers
$start=time();
# Use Primary data feeds for catagorizations
#
$MB_TITLES="mbTitle.dat";
$ZIP_CODES="mbZipCodes.lis";
$OFILE=$MY_DATA."/mblis";
#
# Pick up options
#
GetOptions('zipcode=s' => \$zipcode,
	   'meritbadge=s', => \$meritbadge,
		);
#
# Use timings for sleep to cause intervals of soliciting pages
#
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#
$MBC_URL="http://www.senecawaterways.org/members_mbcSWW.php";
if ( $meritbadge ) {

   print "...choosing meritbadge $meritbadge";
   push(@mbTitle,$meritbadge);

} else {

   print "...reading mb database";
   open(tmp,"cat $MB_TITLES | ") || die "can not read mbTitle.dat:$?\n";
   #
   @mbTitle=<tmp>;
   close tmp;
}
#
print "...load Zip COdes";
#
if ( $zipcode ) {

    push(@zipCodes,$zipcode);

} else {

   open(tmp, "< $ZIP_CODES") || die " can not open ZIP CODE list : $ZIP_CODES :$?\n";
   @zipCodes=<tmp>;
   close tmp;

}
#
chomp(@zipCodes);
#
print "...display titles";
print @mbTitle;
#
print "looking up counselors";
#
# Collect command line arguments
#
# Define defaults for arguments
#
$T=" | html2text";
#
# The decision to randomize the time queries run #
#

# and to make sure the wait is never zero

@_tmpZipStorage=@zipCodes;

while ($z=shift(@_tmpZipStorage)) {

   # Opening an ofile for listing MB for this ZipCode
   #
   $oFile=join(".",$OFILE,$z,'html');
   open(tmp_o, "> $oFile") || die "can not open $oFile : $?\n";
   #
   @_tmpmbTitle=@mbTitle;
   while ($mb=shift(@_tmpmbTitle)) {

      # What am I processing now
      print "...looking up $mb for $z\n";
      chomp($mb);
      $q_String="\"frmZipCode=$z&frmMeritBadge=$mb&action=search\"";
      open(tmp, "curl --data  $q_String $MBC_URL $T | ") || die "can not open URL: $MBC_URL: $?\n";  
      @mbOUT=<tmp>;
      close tmp;

      # Add header information for output.
      unshift(@mbOUT,"<H1>$mb : $z</H1>\n<PRE>");

      if ( /Sorry/ ~~ @mbOUT ) {

         print @mbOUT;
         while ( $xout1=shift(@mbOUT) ) { $xout1 !~ /^$/ && print tmp_o $xout1."\n" } ;
	 print tmp_o "</PRE>";

      } else {
      # grooming output to standardize for Troop
      print "...removing Members area\n";
      s/Members Area// for @mbOUT;

      print "...changing records found to counelors listed\n";
      s/records found/counselors listed/ for @mbOUT;

      print "...removing search from output\n";
      s/search.*// for @mbOUT;

      print "...removing again from output\n";
      s/again.*// for @mbOUT;

      print "...removing images and compass";
      s/\[images.*// for @mbOUT;
      s/compass.*\.gif\]// for @mbOUT;
   
      # print tmp_o @mbOUT;
      print @mbOUT;

      # Parse header of output:
      # Display/print everything returned from the lookup.

      $xout1=shift(@mbOUT); chomp $xout1;

      while ( $xout1 !~ /Distance.*/ ) {
         $xout1 !~ /^$/ && print tmp_o  $xout1."\n";
         $xout1=shift(@mbOUT); chomp $xout1;

      } 

     # list the addresses as a block of addresses, one per line.
     while ( $xout1=shift(@mbOUT) ) { 
        
        chomp $xout1; 
        # When the ZIPCODE is encountered inthe record, print the CR
	if ( $xout1 =~ /[0-9]{5}/ ) {
	   
           print tmp_o  $xout1."\n";

	} else {
	   
           # Just print the information from the line as contiguous.
           print tmp_o  $xout1."\t";

        } # End IF ZIPCODE

     } # End While

        $FOOTER="\n-- MB:$mb -----------------------------------------------\n</PRE>\n";
        print tmp_o $FOOTER;


      print "...recalibrating wait time\n";
     ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
      $t= int(rand($sec));
      print "...sleeping $t\n"; print;
      sleep $t;

   } # while ($mb=shift(@_tmpmbTitle)) {

   } # End IF 'Sorry'

   close tmp_o;

} # End ZipCOde
   
#
# finished
#
$end=time();
$run_time=$end-$start;

my $Conversion=Time::Seconds->new($run_time);
print "information saved in $oFile\n";
printf "run time: %3.2f seconds\n",$Conversion->seconds;
printf "run time: %3.2f minutes\n",$Conversion->minutes;
printf "run time: %3.2f hours\n",$Conversion->hours;
