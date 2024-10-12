#! /usr/bin/perl

# last updated: 17 November 2015
sub libplversion { (1,6,2015) }
#
# Read the tutorial, lib.html, that comes with the script
# before using. Otherwise you'll be lost.  Also contains other stuff.



sub ReadParse {
    local (*in) = @_ if @_;
    local ($i, $key, $val);

    if ($ENV{'REQUEST_METHOD'} eq "POST") {
        read(STDIN,$in,$ENV{'CONTENT_LENGTH'});
    }
    else {
        $in = $ENV{'QUERY_STRING'};
        if (!$in) {
            ($in = $ENV{'PATH_INFO'}) =~ s/^\///;
        }
    }

    @in = split(/&/,$in);

    foreach $i (0 .. $#in) {
        $in[$i] =~ s/\+/ /g;

        ($key, $val) = split(/=/,$in[$i],2);

        $key =~ s/%(..)/pack("c",hex($1))/ge;
        $val =~ s/%(..)/pack("c",hex($1))/ge;

        $in{$key} .= "\0" if (defined($in{$key}));
        $in{$key} .= $val;

    }
    return length($in);
}


sub forminputs {
   my (%input) = @_;
   my (@keys) = keys %input;
   my (@values) = values %input;

   for (@keys) {
      $$_ = $input{$_};
   }

}


sub check_email {
 chomp (my $email = ($_[0] or $_));
   !($email =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||
       $email !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/)
}


sub random {
 local ($i);
 srand( time () ^ ($$ + ($$ << 15)) );
  if ($#_ == 0){
    if ($_[0] =~ /^\d+$/) {
      return int(rand $_[0]) + 1;
    }
    else {
      return ($_[0]);
    }
  }
  else {
    $i = rand (@_);
    return ($_[$i]);
  }
}



sub send_mail {
  local ($program, $to, $from, $subject, @body) = @_;
  local (*MAIL);
  open(MAIL,"|$program -t");
  print MAIL "To: $to\n";
  print MAIL "From: $from\n";
  print MAIL "Subject: $subject\n\n";
  for $MAIL (0..$#body) {
    print MAIL "$body[$MAIL]\n";
  }
  close (MAIL);
 }

sub send_mail_bcc {
  local ($program, $to, $from, $cc, $bcc, $subject, @body) = @_;
  local (*MAIL);
  open(MAIL,"|$program -t");
  print MAIL "To: $to\n";
  print MAIL "From: $from\n";
  print MAIL "Cc: $cc\n";
  print MAIL "Bcc: $bcc\n";
  print MAIL "Subject: $subject\n\n";
  for $MAIL (0..$#body) {
    print MAIL "$body[$MAIL]\n";
  }
  close (MAIL);
}

sub append {
  local (*APPEND);
  open (APPEND, ">>$_[0]") or open (APPEND, ">$_[0]") or die "can't append file, $_[0], $!";
  print APPEND @_[1..$#_];
}

sub rewrite {
  local (*REWRITE);
  open (REWRITE,">$_[0]") or die "can't rewrite file, $_[0], $!";
  print REWRITE @_[1..$#_];
}


sub read {
  local (*READ);
  @READ = ();
  open (READ, "$_[0]") or return "0";
  if ($_[1] eq ''){
    @READ = <READ>;
  }
  else {
    for $READ (0..$_[1]-1){
      $READ[$READ] = <READ>;
    }
  }
  @READ;
}


sub time {
  my ($i,$seconds,$month,@timeonly,@dateonly,$timedate,@mdy);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
  $timedate = $seconds = '';
  $month = (January, Feburary, March, April, May, June, July, August, September, October, November, December)[$mon];
  $day = (Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday)[$wday];
  $mon++;
  $year += 1900;
  $AMPM = 'AM';
  $AMPM = 'PM' unless ($hour < 12);
  $hour -= 12 if ($hour > 12);
  $hour += 12 unless $hour;
  $min = "0" . "$min"  unless ($min > 9);
  for $i (0..$#_) {
    if ($_[$i] =~ /sec/){
      $seconds = ":" . "$sec";
      $seconds = ":0" . "$sec" if ($sec < 10);
    }
  }

   # default #
  if (($#_ == -1) || (($#_ == 0) and ($_[0] =~ /sec/))){
    return "$hour:$min$seconds$AMPM  $day, $month $mday, $year";
  }

  for $i (0..$#_) {
    $timeonly[$i] = join '',$hour,':',$min,$seconds,' ',$AMPM        if ($_[$i] eq 'time');
    $dateonly[$i] = join '',$day,', ',$month,' ',$mday,', ',$year    if ($_[$i] eq 'date');
    $mdy[$i]      = join '',$mon,'/',$mday,'/',$year                 if ($_[$i] eq 'mdy');

    $timedate .= "$timeonly[$i]" . '  '   if $timeonly[$i];
    $timedate .= "$dateonly[$i]" . '  '   if $dateonly[$i];
    $timedate .= "$mdy[$i]" . '  '        if $mdy[$i];
  }

  $timedate;
}



sub itslaterthan {
  # returns a true value if today's date is later than the date specified
  my ($m,$d,$y) = @_;
  my ($day,$mon,$yr) = ((localtime)[3,4,5]);
   $yr += 1900;
   $mon++;
(($yr > $y) or (($yr == $y) and ($mon > $m)) or (($yr == $y) and ($mon == $m) and ($day > $d)));
}
sub islaterthan {&itslaterthan(@_)}

sub dayofweek{
# written by Steve Driver, sed10@po.cwru.edu
# feel free to optimize the code if you want to
# as always, no warranty, use at your own risk
# just call as &dayofweek(1,2,2000) for Jan. 2, 2000 day of the week
#       *********** NEW STUFF ***************
# also works with        ("January 2, 2000")
#   or                   ('1/2/2000')
# or even                ("1 2 2000")
# and now                ("2 January, 2000")

  my ($daytotal, $month, $year) = (0,1,0);
  my ($m, $d, $y) = @_;
  my @dayweek =
('Friday','Saturday','Sunday','Monday','Tuesday','Wednesday','Thursday');
  @dayweek = ('Fri','Sat','Sun','Mon','Tue','Wed','Thu') if ($_[3]);

   ($m,$d,$y) = split /[,-\/\s]+/, $m unless ($d ne '');


  if ($y =~ /(\d+)\s*B.?C/i) {
    $y = $1*(-1);        # translate "BC" to a negative sign and get rid of the BC
  }

  return 0 unless ($y);  # after gettting the numerical part make sure it's not 0.
                         # also, "0 BC" is not valid
  $y++ if ($y < 0);
  $y = $y%400;           # knock it down (or up if negative) to an integer between 0 and 400

  @m = (0, 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec');
  for $i (1..12) {
    $m = $i if ($m =~ /$m[$i]/i);
    if ($d =~ /$m[$i]/i){
      $d = $m;
      $m = $i;
    }
  }

  my @daysinmonth = (0,31,28,31,30,31,30,31,31,30,31,30,31);
  $daysinmonth[2]=29 if ((!($y%4) && ($y%100)) || !($y));
   return 0 unless (($m =~ /^\d+$/) and ($d =~ /^\d+$/) and ($m < 13) and ($d <= $daysinmonth[$m]));
   # no beans if $m and $d don't both have 1 or more digits, or they are too high

  # **FYI** 146097 days in a 400 year cycle

  for ($year = 0; $year < $y; $year++){
       $daytotal = $daytotal + 365;
   if ((!($year%4) && ($year%100)) || !($year)){
       $daytotal++;
   }
  }

  for ($month = 1; $month < $m; $month++){
       $daytotal = $daytotal + $daysinmonth[$month];
  }

 $dayweek[($daytotal + $d)%7];
}


sub dow {
# 0.006 ms per iteration (2.4GHz i5 quad-core processor , only using 1 core)
# written by David Iberri <diberri@ucla.edu>
# edited by Steve Driver <sd@cwru.edu>
    my($month, $day, $year) = @_; # 1 <= $month <= 12
    my $leap = not ($year % 4 or $year % 400 and not $year % 100);
    my @daysinmonth = (0,31,28+$leap,31,30,31,30,31,31,30,31,30,31);
    return 0 unless ($day > 0 and $daysinmonth[$month] >= $day);
    my @ary = (3+$leap, 0+$leap, 0, 4, 2, 6, 4, 1, 5, 3, 0, 5);
    my $a = $year%400;
    my($b, $c) = ($a % 12, int($a/100));
    ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')[(2+$b-$c+$day+int($a/12)+int($b/4)+int($c/4)-$ary[$month-1])%7];
}

# determines if a time period intersects another time period
# good for determining time conflicts
# uses military time (0000 to 2400)
# input 3 or 4 times (assumes the first time is before second
# so if the second number is less than the first it will assume the second
# is for the next day.

sub is_between {
my (@time) = @_;
my $i;

for $i (0..$#time){
 $time[$i] %= 2400 if $time[$i] > 2400;
 # this makes time 2500 -> 0100 (1:00am)
}


$time[3] = $time[2] if ($time[3] eq '');

$time[1] += 2400 if ($time[1] < $time[0]);
$time[3] += 2400 if ($time[3] < $time[2]);
# $time[2] = 2400 if ($time[1] == 0);
# $time[3] = 2400 if ($time[3] == 0);

(($time[2] >= $time[0] and $time[2] < $time[1])
   or
  ($time[3] > $time[0] and $time[3] <= $time[1])
  )
or
($time[0] >= $time[2] and $time[0] < $time[3] and $time[2] != $time[3])

}

sub timeformat {
# 12:00AM = midnight
# 12:00PM = noon

 my ($time) = @_;
 return '12:00AM' unless $time;
 my ($AP, $mid) = 'AM';
 if ($time =~ /(\d+):?(\d\d)(AM|PM)/i) {
   ($hrs,$min,$AP) = ($1,$2,$3);
   $hrs = ($hrs + 12) if ($AP =~ /pm/i and $hrs != 12);
   $hrs = '0' if ($AP =~ /am/i and $hrs == 12);
   $hrs = '0'."$hrs" if ($hrs < 10);
   $AP = '';
   }
 else {
   $time =~ /(\d?\d)(\d\d)/;
   ($hrs,$min) = ($1%24,$2);
   if ($hrs >= 12){
     $hrs -= 12 unless ($hrs == 12);
     $AP = 'PM';
   }
   ($hrs += 12) unless ($hrs > 0);
   $mid = ':';
 }
   $time = $hrs.$mid.$min.$AP;
}

sub timeplus {
  my ($time, $addsub) = @_;
  my ($hrs, $min, $AMPM, $newhrs, $newmin);
  return $time unless ($addsub);
  $time =~ /(\d+):?(\d\d)(AM|PM)?/i;
  ($hrs,$min,$AMPM) = ($1,$2,$3);
  $time = timeformat($time) if $AMPM;
  $time = ($hrs*60 + $min + $addsub);
  while ($time < 0) {
    $time += 1440 if ($time < 0)
  }
  $time %= 1440 if ($time >= 1440);
  return '0000' unless $time;
  $newmin = ($time)%60;
  $newmin = '0'."$newmin" if $newmin < 10;
  $newhrs = int $time/60;
  $newhrs = '0'."$newhrs" if $newhrs < 10;
  $time = "$newhrs"."$newmin";
  $time = timeformat($time) if $AMPM;

  $time;
}

sub timeconvert { # converts text timestamp into (6 item array)
                  # representing sec, min, hr, day, month, and year
                  # or 6 items into text timestamp
                  # timeconvert('12/3/11','y') = (0,0,0,11,3,12)
                  # the 'y' assumes the first number is a year
                  # you can use 2 digit years for dates up to 80 years in the past, 20 years into future
		  # not fully tested as of (32,18,12,13,9,2017)
 my ($sec,$min,$hr,$day,$mon,$year,$time) = @_;
 $_ = $sec;
  s/-/\//g;
  if (/\//){
    ($hr,$min,$sec) = (0,0,0); # initial values
    /(\d+)\/(\d+)\/(\d+)\s+?([0-9:]*)/;
    ($mon,$day,$year,$time) = ($1,$2,$3,$4);
    if ($time =~ /:/){
      ($hr,$min,$sec) = split /:/, $time;
      $sec = $3 or 0;
      $hr += 12 if (/p/i and $hr < 12);
      $hr -= 12 if (/a/i and $hr == 12);
      $hr %= 24;
    }
    if (($mon > 12) or ($_[1] eq 'y')){
      ($year,$mon,$day) = ($mon,$day,$year);
	if ($year<100) {
	$year += 2000;
	$year -= 100 if ($year > ((localtime(time))[5]+1920));
	}
    }
  return ($sec,$min,$hr,$day,$mon,$year);
  }
  else {
    return $mon.'/'.$day.'/'.$year.' '.sprintf ("%02d:%02d:%02d", $hr, $min, $_);
  }
}


sub exceldatevalue {
    # input is an 6-element array ($sec,$min,$hr,$day,$mon,$year) or
    # 1-2 element array ($datevalue,$baseyear)
    # sub will return single value from 6-element input, or 6-element from single value input
    # baseyear can be 1900 or 1904
    # by default, it's 1900, and if creating an Excel date value, creates with 1/1/1900 = 1 as a base date
    my ($sec,$min,$hr,$day,$mon,$year,$i) = @_;
    if ($sec =~ /\/|-/) {
	($sec,$min,$hr,$day,$mon,$year) = timeconvert($_[0]);
    }
    if ($year) {
	# 
	# ($sec,$min,$hr,$day,$mon,$year) = timeshift($sec,$min,$hr,$day,$mon,$year,0,0,0,0,0,0);
	for $i (1900..$year-1){
	    $day+=365;
	    $day++ if (not ($i % 4 or $i % 400 and not $i % 100))
	}
	for $i (1..$mon){
	    $day += (0,0,31,28+(not ($year % 4 or $year % 400 and not $year % 100)),31,30,31,30,31,31,30,31,30)[$i];
	}
	$day++ if ($day >= 60); # date bug issue with Lotus 1-2-3 making 1900 a leap year and Excel replicated it for compatibility
	
	return ($day+($hr+($min+$sec/60)/60)/24);
    }
    else {
	$i=0;
	if ($_[0]>=60) {$i=1} # date bug issue with Lotus 1-2-3 and Excel 2/29/1900 = 60
	timeshift(0,0,0,1,1,1900,0,0,0,$_[0]-1-$i);
    }
}

sub timeshift {
# From 0.01ms for normal stuff up to 0.03 msec for large shifts 40000+ days.
# provide any datestamp (to the tenth of a second)
# and a shift (unlimited seconds, minutes, hours, days, months, years)
# and have the final date provided
# you could shift a date 86400 seconds and it'll return the next day
# or even 800 million seconds and it'll figure out the time (leap years included)
# complete precision is limited to 32-bit (about 4 billion) steps integer and floating point. 
#  Order of shift VERY IMPORTANT is years/months first
#  then sec, min, hours, and days, with positives and negatives carried forward
#  to the next unit. It does days last so that you won't get a Feb 29, 2013 type output
#  Since not all months or years are equal, using them in a timeshift is not
#  as relevent, but it's there in case you need it

  my ($sec,$min,$hr,$day,$mon,$year,$dsec,$dmin,$dhr,$dday,$dmon,$dyr) = @_;
  # sec,min,hr,day,mon,year and shifted sec,min,hr,day,mon,year

  $dhr += ($dday-int $dday + $day - int $day)*24;  # fractional days to hours
  $dmin += ($dhr-int $dhr + $hr - int $hr)*60;   # fractional hours to minutes
  $dsec += ($dmin-int $dmin + $min - int $min)*60; # fractional minutes to seconds
  ($dmin,$dhr,$dday,$min,$hr,$day) = (int $dmin, int $dhr, int $dday, int $min, int $hr, int $day);

    $dmin += int (($dsec+$sec)/60);
    $sec = ($dsec+$sec) - 60 * int (($dsec+$sec)/60);
    if ($sec < 0){
      $min--;
      $sec+=60;
    }
   $sec =  round($sec,-1);
   if ($sec == 60) {
	$min++;
	$sec = 0;
   }
   
   $dhr += int (($dmin+$min)/60);
   $min = ($dmin+$min) - 60 * int (($dmin+$min)/60);
   if ($min < 0){
      $hr--;
      $min+=60;
   }
    $dday += int (($dhr+$hr)/24);
    $hr = ($dhr+$hr) - 24 * int (($dhr+$hr)/24);
  if ($hr < 0){
    $dday--;
    $hr+=24;
  }
  $day += $dday;
  $mon--; # for the math, Jan is month 0, Dec is month 11
  $mon += $dmon;
  while ($mon < 0){
    $year--;
    $mon+=12;
  }
  $year += ($dyr + int($mon/12));
  $mon %= 12;
 
  
  while ($day > 366) {
    $day -= (365+leapyear($year));
    $year++;
  }
  
  my $leap = not ($year % 4 or $year % 400 and not $year % 100);
  my @daysin = (31,31,28+$leap,31,30,31,30,31,31,30,31,30,31);
  while (($day > $daysin[$mon+1]) or ($mon > 11)){
    while ($mon > 11) {
	$year++;
	$mon-=12;
    }
    $leap = not ($year % 4 or $year % 400 and not $year % 100);
    @daysin = (31,31,28+$leap,31,30,31,30,31,31,30,31,30,31);
    $day -= $daysin[$mon+1];
    $mon++;
  }
  while (($day < 1) or ($mon < 0)){
    while ($mon < 0) {
      $year--;
      $mon += 12;
    }
    $leap = not ($year % 4 or $year % 400 and not $year % 100);
    @daysin = (31,31,28+$leap,31,30,31,30,31,31,30,31,30,31);
    while ($mon >= 0){
      last if ($day > 0);
      $day += $daysin[$mon];
      $mon--;
    }
  }
  ($sec,$min,$hr,$day,$mon+1,$year);
}
sub leapyear{ # input is 4-digit year, returns 1 or 0 for a leap year or not
    # returns no error if year < 1582
   not ($_[0] % 4 or $_[0] % 400 and not $_[0] % 100);
}


###  ******    Below are little functions that just save     ******   ###
###  ******     you time typing but don't do much else       ******   ###

 # "slurps" an entire file (line breaks and all) into a scalar variable

sub slurp {
  join '',(&read($_[0]));
}

 # checks if a text file contains a given string
 # returns the number of times the string is found
 # or a given number
 # if the number of matches is less than the given number
 #   the routine returns 0

sub file_contains {
  my ($return,$i) = 0;

  if ($_[2] ne '') {
    open (FILE, "$_[0]");
    while ((<FILE>) and ($return < $_[2])) {
      $return++ while /$_[1]/g;
    }
    close (FILE);
    return 0 unless ($return >= $_[2]);
  }

# if you have a huge file and just need to find a few
# matches, the above code won't go through the entire file
# keep in mind that it will exec the above block if you
# have "0" as $_[2].  Only the null char will make
# the code below will load (or "slurp") the entire file into a variable

  else {
    $_ = &slurp($_[0]);
    $return++ while /$_[1]/g;
  }
 $return;
}

sub dates {
    # Provides all dates in an array in mm/dd/yyyy or yyyy/mm/dd format between a min/max year, month, and days
    my ($ymin,$ymax,$mmin,$mmax,$dmin,$dmax,$delim,$format) = @_;
    timeshift(0,0,0,$dmin,$mmin,$ymin);
    for $y ($ymin..$ymax){
      for $m ($mmin..$mmax){
	for $d ($dmin..$dmax){
	    $file[$i] = sprintf("%02d", $m).$delim.sprintf("%02d", $d).$delim.sprintf("%02d", $y) if (($format eq '') or ($format eq 'mdy'));
	    $file[$i] = sprintf("%02d", $y).$delim.sprintf("%02d", $m).$delim.sprintf("%02d", $d) if ($format eq 'ymd');
	    $i++;
	}
      }
    }  
  @file;  
}


 # Print a new line after the print command
sub printl {
  print @_,"\n";
}
 # Print a new line after each list element in the print command
sub printll {
 my $i;
 for $i (0..$#_) {
   print $_[$i],"\n";
 }
}

sub greater_of {
  sub greater { $b <=> $a; }
  my $i;
  @new = sort greater @_;
  while ((! defined($new[$i])) || ($new[$i] eq '')) {
    $i++;
  }
 $new[$i];
}

sub lesser_of {
  sub lesser { $a <=> $b; }
  local ($i, @new);
  @new = sort lesser @_;
  while ((! defined($new[$i])) || ($new[$i] eq '')) {
    $i++;
  }
 $new[$i];
}

sub print_html { &html(@_) }
sub html {
  my $html;
  $html = join '', @_;

print "Content-type: text/html\n\n" ;
print <<"(HTML)";
$html
(HTML)

}

sub sum {
 my $total;
 $total += $_ for (@_);
 $total;
}
sub product {
 my $total = 1;
 $total *= $_ for (@_);
 $total;
}

sub sumproduct {
    # for multiplying arrays
    # sumproduct(3,@a,@b,@c) where a,b, and c are equally sized arrays
    # would multiply $a[0]*$b[0]*$c[0] + $a[1]*$b[1]*$c[1]+...$a[n]*$b[n]*$c[n]
    my ($m,$n,$i,@a) = ($#_/$_[0],2,1);
    @a[1..$m] = @_[1..$#_/$_[0]];
    for $n (2..$_[0]){
      for $i (1..$m){
	$a[$i] *= $_[$i+($n-1)*$m]
    }
   }
sum (@a[1..$m]);
}

sub zipper {
    # takes a list of @x and @y separate pairs and
    # "zippers" them together (x1,y1,x2,y2,x3,y3,...xn,yn)
    my ($i,@x,@y,@out);
    @x = @_[0..(($#_-1)/2)];
    @y = @_[(($#_+1)/2)..$#_];
    for $i (0..$#x){
	push @out,($x[$i],$y[$i]);
    }
@out;
}


#####  M    M    AA   TTTTT  H  H
#####  MM  MM   A  A    T    HHHH
#####  M MM M  AAAAAA   T    H  H   Functions
#####  M    M AA    AA  T    H  H

# Combinations (n Choose r)
# on many calculators as nCr
# same as n!/[(n-r)!r!]

sub nCr {
 my ($n, $r) = @_;
 my $total = 1;
 my $i;
 return 0 if (($n < $r) || (int $n != $n) || (int $r != $r));
 return 1 if (($n < 2) or ($r == 0) or ($r == $n));
 @n = (1..$n);
 @nr = (1..$n-$r);
 @r = (1..$r);
 @nrr = sort @r,@nr;

 for $i (0..$n-1) {
  $total *= $n[$i]/$nrr[$i];
 }

# factorial($n)/factorial($n-$r)/factorial($r);    # this is the simpler one but can be suseptable to
                                                   # error when $n gets above 15 or so.

$total;
}


# Permutations (n List r)
# on many calculators as nPr
# same as n!/(n-r)!

sub nPr {
 my ($n, $r) = @_;
 return 0 if (($n < $r) or (int $n != $n) or (int $r != $r) or ($n < 0) or ($r < 0));
 return 1 if (($n < 2) or ($r == 0));
 return factorial($n) if ($n == $r);
 product($n-$r..$n);
}


# pretty self explanatory
# returns the factorial of argument

sub fact { factorial(@_) }
sub factorial {
 $_[0] = $_ if ($_[0] eq '');
 return 0 if (($_[0] < 0) || (int $_[0] != $_[0]));
 return 1 if ($_[0] == 0);
 product(2..$_[0]);
}

sub stdev {
 my ($i,$avg,$ss) = (0,&sum(@_)/($#_+1),0);
 return 0 if ($#_ < 1);
 for $i (0..$#_) {
   $ss += ($_[$i] - $avg)**2;
 }
 sqrt($ss/$#_);
}


sub addrow {
  my $n = ($#_+1)/2; # order size is half the length of the input
  my ($i, @array);
  for $i (0..$n-1){
    $array[$i] = $_[$i]+$_[$n+$i]; # add each value to it's counterpart
  }
  @array;
}
sub reducerow {
# reducing a row by a multiplier
  my $n = $#_/2; # order size is half the length of the input
  my $m = shift;
    my ($i, @array);
  for $i (0..$n-1){
    $array[$i] = $_[$i]-$m*$_[$n+$i]; # add each value to it's counterpart
  }
  @array;
}

# Matrix functions
# Since Matrices are multi-dimensional, and list context is only 1-dimensional
# the list must include the order of the Matrix so it can be passed and processed
#

sub matrixreduction {

# This next sub can be used for solving a system of equations in the form
#  A[0,0]*x[0] + A[0,1]*x[1] + ... A[0,N]*x[N] = b[0],
#  A[1,0]*x[0] + A[1,1]*x[1] + ... A[1,N]*x[N] = b[1],
#  A[2,0]*x[0] + A[2,1]*x[1] + ... A[2,N]*x[N] = b[2],
#  ...
#  A[N,0]*x[0] + A[N,1]*x[1] + ... A[N,N]*x[N] = b[N]
#  Where all A and b elements are known and all x elements are unknown.
#  Also in the form of:
#   a known (N x N) matrix "A" multiplied by
#   an unknown vector "x" (of length N) equaling
#   a known vector "b" (of length N)
#   [A]{x} = {b}
#
#  Matrix A and vector b must be combined as a list
#  of N lists (rows) each N+1 elements (columns) long
#  in the form @A = ( (A[0,0],A[0,1],A[0,2]..A[0,N],b[0]),
#                     (A[1,0],A[1,1],A[1,2]..A[1,N],b[1]),
#                 ... (A[N,0],A[N,1],A[N,2]..A[N,N],b[N]))

# you can make it as big as you want, but be careful, if N = 1000
# you'll be looking at 4MB of mem just to store the matrix, assuming
# 4 bytes/value


  # input is ($n,@row1[0..$n-1],@row2[0..$n-1],...@row_n[0..$n-1],@b[0..$n-1])
  # if you needed to process a 1000x1000 matrix, it would probably take about 800 seconds.

  my ($n,$i,$j,@x,@saferow) = ($_[0]);
  my @b = @_[($n*$n+1)..(($n+1)*$n)];  # Ax = b
  for $i (0..$n-1){
     @{"A_matrix".$i} = @_[($i*$n+1)..(($i+1)*$n)]; # builds the matrix used internally to the subroutine
     for $j (0..$n-1){
       if (${"A_matrix".$i}[$j]!=0){
        $saferow[$j]=$i;
       }
       # this maps out rows with non-zero values to add to other rows with potential zero diagonal values
       # if the last row is all non-zero it will be used for all $j values
     }
  }

# create a "safe matrix" with all non-zero diagonal values
  for $i (0..$n-1){
    if (${"A_matrix".$i}[$i] == 0) {
#    print "need to add row $i to row: $saferow[$i]\n";
      for $j (0..$n-1){
        ${"A_matrix".$i}[$j] += ${"A_matrix".$saferow[$i]}[$j];
      }
      $b[$i] += $b[$saferow[$i]];
    }
  }
# Next reduce to 
  for $j (0..$n-1){
    for $i (0..$n-1){
      next if $j == $i;
      next if ${"A_matrix".$i}[$j] == 0; # multiplier becomes 0 and nothing changes.
      (@{"A_matrix".$i}[0..$n-1],$b[$i]) = reducerow(${"A_matrix".$i}[$j]/${"A_matrix".$j}[$j], @{"A_matrix".$i}[0..$n-1],$b[$i],@{"A_matrix".$j}[0..$n-1],$b[$j]);
    }
  }

  for $i (0..$n-1) {
    $b[$i] /= ${"A_matrix".$i}[$i];
    ${"A_matrix".$i}[$i] /= ${"A_matrix".$i}[$i];
  }
  @b;


}

sub transposematrix {
    # takes rows and makes columns or vice/versa
    # only works on square matrices
    my ($i,$j,$k) = (0,0,0);
    my $order = (shift @_)-1;  # order is entered as 2 to N, but calcs are done with 1 to N-1
    my @A;
    return 0 if ($order < 1);
    for $i (0..$order){
	for $j (0..$order){
	    $A[$i][$j] = shift @_;
	}    
    }
    $_[$k] = $order+1;
    for $i (0..$order){
	for $j (0..$order){
	    $_[++$k] = $A[$j][$i];
	}    
    }
    @_;
}

sub determinant {
    # A random 10x10 matrix takes about 0.8ms on 2.4GHz quad-core i5 (only utilizing 1 core)
    # Calculate determinant of NxN matrix [A]
    # input is entered as the order (1 to N), then each of the COLUMNS separately
    # A[1,1],A[2,1]...A[N,1],A[1,2],...A[N,2]...A[N,1],A[N,2]...A[N,N]
    
    # Big matrices can have serious errors when adding and subtracting large amounts of products of numbers
    # breaking the 32-bit precision threshold.
    # this subroutine attempts to mitigate this potential by putting together all of values then adding in
    # the magnitude (as a power of 2) at the end, adding small values first then the larger
    
    my ($i,$j,$col,$row,$position,$determinantl,$determinanth,$M) = ();
    my (@A,@M,@productplus,@productminus,@Mplus,@Mminus,@determinantl,@determinanth) = ();
    my $order = (shift @_)-1;  # order is entered as 2 to N, but calcs are done with 1 to N-1
    return 0 if ($order < 1);
    for $col (0..$order){
	for $row (0..$order){
	    $A[$row][$col] = shift @_;
	    $M[$row][$col] = 0;
	    while (abs $A[$row][$col] > 256 and ($M[$row][$col] < 100)) {
		$M[$row][$col]++;
		$A[$row][$col] /= 2;
	    }
	    while (abs $A[$row][$col] < 0.00390625 and ($M[$row][$col] > -100)) {
		$M[$row][$col]--;
		$A[$row][$col] *= 2;
	    }
	}    
    }  

    for $position (0..$order){
	$Mplus[$position] = 0;
	$productplus[$position] = 1;
	for $row (0..$order){
	    $col = ($row+$position)%($order+1);
	    $productplus[$position] *= $A[$row][$col];
	    $Mplus[$position] += $M[$row][$col];
	} 
    }    
    for $position (0..$order){
	$Mminus[$position] = 0;
	$productminus[$position] = 1;
	for $row (0..$order){
	    $col = ($order-$row-$position)%($order+1);
	    $productminus[$position] *= $A[$row][$col];
	    $Mminus[$position] += $M[$row][$col];
	} 
    }
        
    for $M (0..64) {
	$determinanth[$M] = 0;
	for $position (0..$order) {
	    if ($Mplus[$position] == $M) {
		$determinanth[$M] += ($productplus[$position]);
	    }
	    if ($Mminus[$position] == $M) {
		$determinanth[$M] -= ($productminus[$position]);
	    }
	}
	$determinanth += ($determinanth[$M] * 2**$M);
	# using this method no big values will be added/subtracted
	# to small values
	
    }
    for $M (1..64) {
	$determinantl[$M] = 0;
	for $position (0..$order) {
	    if ($Mplus[$position] == (-$M)) {
		$determinantl[$M] += ($productplus[$position]);
	    }
	    if ($Mminus[$position] == (-$M)) {
		$determinantl[$M] -= ($productminus[$position]);
	    }
	}
	$determinantl += ($determinantl[$M] * 2**(-$M));
    }
    
   # If a value in the high magnitudes dominates, then it will be here, but if two high magnitude
   # values cancel each other out, the lower magnitude values won't be drowned out in the final 32-bit arithmetic

   $determinantl+$determinanth;
}

sub determinant_simple {
   # A random 10x10 matrix takes about 0.2ms on 2.4GHz quad-core i5 (only utilizing 1 core)
   # potential error exists for larger matrices, only use for 4x4 or smaller
    my ($i,$j,$col,$row,$position,$determinant) = ();
    my (@A,@M,@productplus,@productminus) = ();
    my $order = (shift @_)-1;  # order is entered as 2 to N, but calcs are done with 1 to N-1
    return 0 if ($order < 1);
    for $col (0..$order){
	for $row (0..$order){
	    $A[$row][$col] = shift @_;
	}    
    }  

   for $position (0..$order){
	$productplus[$position] = 1;
	for $row (0..$order){
	    $col = ($row+$position)%($order+1);
	    $productplus[$position] *= ($A[$row][$col]);
	} 
    }    
   for $position (0..$order){
	$productminus[$position] = 1;
	for $row (0..$order){
	    $col = ($order-$row-$position)%($order+1);
	    $productminus[$position] *= ($A[$row][$col]);
	}
	$determinant += ($productplus[$position]-$productminus[$position]);
	# print STDOUT $determinant."\n";
    }
    
   $determinant;
}

# This regression (linear) function is working
# call with linreg(x1,y1,x2,y2...xn,yn) 
sub regression {linreg(@_)}
sub linreg {
 my ($N,@x,@y,$i,$m,$b,$sx,$sxs,$sy,$sxy) = (int (($#_+1)/2));
 for $i (0..($N-1)) {
   ($x[$i], $y[$i]) = ($_[2*$i], $_[2*$i+1]);
   $sxy += $x[$i]*$y[$i];
   $sx  += $x[$i];
   $sy  += $y[$i];
   $sxs += $x[$i]**2;
 }

 $m = ($N*$sxy-$sx*$sy)/($N*$sxs-$sx**2);
 $b = ($sy-$m*$sx)/$N;
 $R = $m*stdev(@x)/stdev(@y);

 ($b,$m,$R);
}

sub nonlinreg {

 my ($N,@x,@y,$i,$k,@s,@t,@A) = ($_[0]+1);
 for $i (0..($#_/2-1)) {
  ($x[$i], $y[$i]) = ($_[2*$i+1], $_[2*($i+1)]);
 }
 for $k (0..2*$_[0]) {
   for $i (0..$#x) {
     $s[$k] += $x[$i]**$k;
     $t[$k] += $y[$i]*$x[$i]**$k;
   }
 }
 for $i (0..$_[0]) {
 push (@A, @s[$i..$i+$_[0]]);
 }
 matrixreduction($N,@A,@t);
}

sub quadreg   {nonlinreg(2,@_)}   # quadratic regression
sub cubicreg  {nonlinreg(3,@_)}   # cubic   (3rd order) regression
sub quartreg  {nonlinreg(4,@_)}   # quartic (4th order) regression
sub quintreg  {nonlinreg(5,@_)}   # quintic (5th order) regression

# these all return a list of the polynomial coefficients from 0th to the Nth order
# if the quintic regression of a series of x,y points is
# ax^4+bx^3+cx^2+dx+e
# it will return the list (e,d,c,b,a) which can then be used in any of the other
# subs that handle polynomial coefficients



# Next four are for calculating the derivative or integral of a particular function
# if you have a polynomial it makes it much easier
# although it can take any function that perl can handle or that you can make yourself
# from Perl's builtin functions

sub derivative {
return &derivative_poly(@_) if ($#_ > 1);

 my ($h, $i, @yp, @y, @x) = (2**-5, 0);
 my ($x0, $func) = @_;

 unless ($func =~ /\$x/) {
   $func =~ s/x/\$x/g;
   $func =~ s/\$\$x/\$x/g;
   $func =~ s/(\w)\$x/$1x/g;
   $func =~ s/\$(x\w)/$1/g;
 }

#    for $i (0..16) {
#      $x = $x[$i] = $x0 + ($i-8)*$h;
#      $xy[2*$i+1] = $y[$i] = (eval $func);
#      $xy[2*$i]   = $x[$i];
#    }
#    $deriv = derivative_poly($x0, &cubicreg(@xy));


 for $j (1,2) {
   for $i (0..4) {
     $x = $x[$i] = $x0 + ($i-2)*$h/$j;
     $y[$i] = (eval $func);
   }
   $yp[$j] = (1/(10*$h/$j))*(-2*$y[0] - $y[1] + $y[3] + 2*$y[4]);
 }

 (4*$yp[2] - $yp[1])/3;
}


sub derivative_poly {
 my ($x, @coeff) = @_;
 my ($total, @new);

 if ($x =~ /coeff/) {
    for $i (1..$#coeff) {
      $new[$i-1] = ($i * $coeff[$i]);
    }
 return @new;
 }
 else  {
   for $i (1..$#coeff) {
    $total += ($i * $coeff[$i] * $x ** ($i-1));
   }
 }

$total;

}

sub integral {
integrate(@_)
}

sub integrate {
 return integrate_poly(@_) unless ($#_ <= 2);
 return integrate_coeff(@_[1..$#_]) if ($_[0] =~ /coeff/);
 integrate_hp(@_,0);
}

sub integrate_hp {
 my (@total) = ('', $next, $last);
 my ($x0, $x1, $func, $precision) = @_;

 unless ($func =~ /\$x/) {
   $func =~ s/x/\$x/g;
   $func =~ s/\$\$x/\$x/g;
   $func =~ s/(\w)\$x/$1x/g;
   $func =~ s/\$(x\w)/$1/g;
 }

 for $i (1,2,3) {
  $x = $x0;
  $dx = ($x1-$x)/2**($precision + 7 + $i);
  $last = eval $func;
  if ($x > $x1){
    for ($x += $dx; $x >= $x1; $x += $dx) {
      $next = eval $func;
      $total[$i] += ($last+$next);
      $last = $next;
    }
  }
  else {
    for ($x += $dx; $x <= $x1; $x += $dx) {
      $next = eval $func;
      $total[$i] += ($last+$next);
      $last = $next;
    }
  }
  $total[$i] *= $dx;
 }
(16*(4*$total[3]-$total[2])/6 - (4*$total[2]-$total[1])/6)/15;

}


sub integrate_poly {
return &integrate_coeff(@_[1..$#_]) if ($_[0] =~ /coeff/);

 my ($total, $i) = '0';
 my ($x0, $x1, @coeff) = @_;

 for $i (0..$#coeff) {
   $total += ($coeff[$i]/($i+1) * ( $x1 ** ($i+1) - $x0 ** ($i+1) ));
 }
$total;
}

sub integrate_coeff {
my (@new) = 0;
my $i;
 for $i (0..$#_) {
   $new[$i+1] = $_[$i]/($i+1);
 }
 @new;
}


# will give the value of the standard normal curve
sub bellcurve {  # 0.6 usec per iteration
  (0.39894228040143267793994605993438)*exp((-$_[0]**2/2))
}

# this will return the probability of an event happening
# between two z-values in the standard normal curve, about 1.4ms per iteration

sub probability {
    my ($z0,$z1) = @_;
    my ($x,$dx,@y,$i,$s3,$s2,$s1,$s0)= ($z0,($z1-$z0)/2**10);
    $y[0] = 0.39894228040143267793994605993438*exp((-$z0**2/2));
    for $i (1..2**10) {
	$x += $dx;
	$y[$i] = 0.39894228040143267793994605993438*exp((-$x**2/2));
	$s3 += .5*($y[$i]+$y[$i-1])*$dx;
    }
    for $i (1..2**9) {
	$s2 += ($y[2*$i]+$y[2*$i-2])*$dx;
    }
    for $i (1..2**8) {
	$s1 += ($y[4*$i]+$y[4*$i-4])*$dx*2;
    }
    for $i (1..2**7) {
	$s0 += ($y[8*$i]+$y[8*$i-8])*$dx*4;
    }    
(64*(16*(4*$s3-$s2)/3 - (4*$s2-$s1)/3)/15 - (16*(4*$s2-$s1)/3 - (4*$s1-$s0)/3)/15)/63;
}


# convert radians to degrees or vice-versa
# depending on input

sub raddeg {
    if ($_[1] =~ /deg/) {
      my $deg = ($_[0]*180/&pi);
      if ($_[2] =~ /red/){
        while ($deg >= 360){
         $deg -= (360);
       }
    }
	   return $deg;
	}
    if ($_[1] =~ /rad/) {
      my $rad = ($_[0]/180*&pi);
      if ($_[2] =~ /red/){
        while ($rad >= (2 * &pi)){
         $rad -= (2 * &pi);
       }
    }
	   return $rad;
	}
}

# our two favorite irrational constants

sub pi {
3.14159265358979;
}

sub e {
2.718281828459045;
}

# calculate the logarithm (base anything) of a number, by default base 10;
# each are about 0.4usec per iteration

sub logx {
 my $base = ($_[1] or 10);
 (log $_[0]) / (log $base);
}
sub log2 {(log $_[0])/(log 2)}
sub log4 {(log $_[0])/(log 4)}
sub log8 {(log $_[0])/(log 8)}
sub log10 {(log $_[0])/(log 10)}
sub log16 {(log $_[0])/(log 16)}

# calculates the value of one number (base something) as another (base something else)
# 31 (base 10) is 11111 (base 2).
# iterations depend highly on the value and base, larger the value and smaller the base, the more calculations are needed
# 1 to 100,000 (base 10) converted to base 2 averages 13usec per iteration
# while converting to base 8 takes about 5usec per iteration

sub base {
my ($base, $num, $baseFrom, $i, $temp, @new) = @_;
return 0 unless ($num);

 if ($baseFrom){
    for ($i=0; $num; $i++) {
      $temp += (chop $num)*$baseFrom**$i;
    }
 $num = $temp;
 }
 for ($i=1; $num; $i++){
  $new[$i-1] = $num%$base;
  $num = int($num/$base);
}

join '', reverse @new;
}


sub place {

return 0 unless $_[0];

# this supports string variables for infinite precision.



 my ($num, $x, $place, $exp) = @_;
 $num =~ s/^[\-\+]//;

 $num =~ /^(\d*)\.?(\d*)e?\+?(\-?\d*)$/i;
   $exp = $3;
   $num = "$1".'.'."$2";

 if ($exp > 0) {
   $num =~ s/(\.)(\d{$exp})/$2$1/;
 }
 if ($exp < 0) {
   $exp *= (-1);
   $num =~ s/(\d{$exp})(\.)/$2$1/;
 }

 $num =~ /(\d+)\.(\d+)/;
 $place = substr($1,-$_[1]-1,1) if ($_[1] >=0);
 $place = substr($2,-$_[1]-1,1) if ($_[1] < 0);
 return 0 unless ($place);

$place;
}

sub placevalue {
return 0 unless $_[0];

# BE CAREFUL!  Perl only uses 32-bit precision!!!
# this script is not good for heavy precision numbers
# takes about 1 usec per iteration

int(($_[0]/10**($_[1]+1) - int($_[0]/10**($_[1]+1)))*10);
}


sub arc {
  if ($_[0] =~/cos/i){
    return (atan2( sqrt(1 - $_[1]**2), $_[1]));
  }
  if ($_[0] =~/sin/i){
    return (atan2( $_[1], sqrt(1 - $_[1]**2)));
  }
}

# handy for for converting various types of units, without having to know
# the values.  Handles length, area, volume, mass, force, density, pressure,
# energy, enthalpy, entropy, heat capacity, power, and temperature
# takes about 35usec per iteration for normal units, 15usec for temperature
sub convert_units {
my ($n, $from, $to) = @_;
 $from = lc $from;
 $to   = lc $to;

 return &temperature($n, $from, $to) if ($to =~ /^c$|^f$|^k$|^r$/);

my %convert = (
# length (meters, inches, feet, miles, and light years)
 'm' => 1,
 'cm'=> 100,           # centimeters
 'mm'=> 1000,          # milimeters
 'km'=> .001,          # kilometers
 'in'=> 39.369999696,
 'ft'=> 3.280833308,
 'mi'=> 1/1609.3472,
 'ly'=> 1/(9.4629*10**15),

# area   (square meters, square inches, square feet, square miles, and acres)
 'sqm'  => 1,
 'sqin' => 1549.9969,
 'sqft' => 10.7638672,
 'sqyd' => 1.19598524,
 'sqmi' => 1609.3472**(-2),
 'm^2'  => 1,
 'in^2' => 1549.9969,
 'ft^2' => 10.7638672,
 'yd^2' => 1.19598524,
 'mi^2' => 1609.3472**(-2),
 'acres'=> 1/4046.8564224,

# volume (liters, cubic meters, cubic inches, cubic feet, and gallons)
 'l'    => 1000,
 'm^3'  => 1,
 'in^3' => 61023.744,
 'ft^3' => 35.3146667,
 'cc' => 1000000,
 'cuin' => 61023.744,
 'cuft'   => 35.3146667,
 'cf'   => 35.3146667,
 'ccf'  => .353146667,      # hundred cubic feet
 'mcf'  => .0353146667,     # thousand cubic feet
 'mscf' => .0353146667,     # thousand "standard" cubic feet
 'kcf'  => .0353146667,     # thousand cubic feet
 'mmcf' => .0000353146667,  # million cubic feet
 'gal'  => 264.17064155,
 'oz'   => 33813.84212,

# mass (kilograms, pounds, slugs, and atomic mass units)
 'kg'  => 0.4535932,
 'lbm' => 1,
 'sl'  => 1/32.173984,
 'amu' => 2.7316005E26,

# Force (Newtons, pounds)
 'n'   => 4.448444,
 'kn'  => .0048444,  # Kilonewtons
 'lbf' => 1,
# generic uses of pound(s)
 
# Force and Mass
 'lb' => 1,
 'lbs' => 1,
 'pounds' => 1,
 'kip' => .001,    # thousand pounds
 'mip' => .000001, # million pounds

# density & specific volume (kg per cubic meter, pounds per cubic inch,
# pounds per cubic foot, slugs per cubic foot)
 'kg/m^3'  => 515.31061,
 'g/cm^3'  => .51531061,
 'lb/in^3' => 0.018619204,
 'lb/ft^3' => 32.173984,
 'lb/cf'   => 32.173984,
 'sl/ft^3' => 1,
 'm^3/kg'  => 1/515.31061,
 'ft^3/lb' => 1/32.173984,
 'cf/lb'   => 1/32.173984,

# Pressure/stress
 'bar'=> 1.01325,
 'mbar'=> 1013.25,     # milibar
 'kpa'=> 101.325,      # kilopascals
 'hpa'=> 1013.25,      # hectopascals
 'pa' => 101325,       # pascals
 'mpa'=> .101325,      # megapascals
 'gpa'=> .000101325,   # gigapascals
 'psi'=> 14.6966,      # pounds per square inch
 'psia'=> 14.6966,
 'ksi'=> .0146966,     # thousand lbs per sq in.
 'msi'=> .0000146966,  # million lbs per sq in
 'psf'=> 2116.31,      # pounds per square foot
 'atm'=> 1,            # sea level standard atmospheric pressure
 'inhg'=> 29.92,       # inches of Mercury
 'mmhg'=> 760,         # mm of Mercury

# velocity (meters per second, miles per hour, and feet per second)
 'm/s'=> 1,
 'mph'=> 2.2369318,
 'fps'=> 3.280833308,
 'ft/s'=> 3.280833308,
 # kinematic viscosity
 'st' => 1,
 'm^2/s' => 0.0001,
 'ft^2/s' => 0.00108,

 # dynamic viscosity
 'pas' => 0.001,
 'p' => .01,
 'cp' => 1,
 'lb-s/ft^2' => 2.09E-5,
 'lbf-s/ft^2' => 2.09E-5,
 'lb/ft-s' => 6.72E-4,
 
# Energy and Torque (Joules or Newton-meters, calories, kilowatt hours,
# Btu's, foot*pounds or pound*feet, and electron volts)
 'j'    => 3600000,
 'kj'   => 3600,          # kilojoules
 'nm'   => 3600000,
 'cal'  => 860420.65,
 'kwh'  => 1,
 'btu'  => 3413,
 'mbtu' => 3.413,         # thousand BTU
 'mmbtu'=> .003413,       # million BTU
 'ftlb' => 2655085.668,
 'lbft' => 2655085.668,
 'lbin' => 221257.139,     # pound-inches
 'ev'   => 2.246942291E25, # electron volts
 'therm'=> .03413,
 'dekatherm' => .003413,

# Enthapy (kilojoules per kilogram, BTU's per pound, calories or Joules per gram)
 'kj/kg'  => 4.1868,
 'j/g'    => 4.1868,
 'cal/g'  => 1,
 'btu/lb' => 1.8,
 'kbtu/lb' => 0.0018,

# Heat capacity or Entropy (kilojoules per kilogram degree Kelvin, BTU's per pound degree
# Fahrenheit, calories or Joules per gram degree Kelvin)

 'kj/kgk'  => 4.1868,
 'j/gk'    => 4.1868,
 'cal/gk'  => 1,
 'btu/lbf' => 1,
 'kj/kgc'  => 4.1868,
 'j/gc'    => 4.1868,
 'cal/gc'  => 1,

# Power and heat transfer (watts, horsepower, BTU's per hour)
 'w'       => 745.7,
 'kw'      => .7457,          # kilowatts
 'mw'      => .0007457,       # megawatts
 'gw'      => .0000007457,    # gigawatts  "One point twenty-one Gigawatts!?!?"
 'tw'      => .0000000007457, # terawatts
 'hp'      => 1,
 'btu/h'   => 2545,
 'mbtu/h'  => 2.545,          # thousand BTU/hr
 'mmbtu/h' => .002545,        # million BTU/hr

);


$n * ($convert{$to} / $convert{$from}) if ($convert{$to} and $convert{$from});

}

sub convertlist {
   # Setup to provide conversions of several values all from one unit to another unit
   #  
    my ($from,$to,@from) = @_;
    my @to;
    for (@from) {
	$to[$i] = convert_units($from,$to,$_);
    }
    @to;
}

sub temperature {
  my ($temp,$from,$to) = @_;
  $from =~ s/(.).*/$1/;
  $to   =~ s/(.).*/$1/;
  $from = lc $from;
  $to   = lc $to;

  %temp = (
    c => {
      c  => $temp,
      k  => $temp+273.15,
      r  => ($temp+273.15)*9/5,
      f  => $temp*9/5+32,
    },
    k => {
      c  => $temp-273.15,
      k  => $temp,
      r  => $temp*9/5,
      f  => $temp*9/5-459.67,
    },
    r => {
      c  => $temp*5/9-273.15,
      k  => $temp*5/9,
      r  => $temp,
      f  => $temp-459.67,
    },
    f => {
      c  => ($temp-32)*5/9,
      k  => ($temp+459.67)*5/9,
      r  => $temp+459.67,
      f  => $temp,
    }
  );

  $temp{$from}{$to};
}


sub round {
 return 0 unless ($_[0]);
 my ($num) = ($_[0]/10**($_[1]));
  $num -= .4999999999*($num/abs($num)) if ($_[2] =~ /d/);
  $num += .4999999999*($num/abs($num)) if ($_[2] =~ /u/);

(int($num)+int(($num-int($num))*2))*10**$_[1];
}

# significant digits rounder
# If you're not sure the scale of the variable, and want to round it appropriately
# or if the calculated value requires no better than a certain precision
# about 3usec per iteration

sub sigdig {
 return 0 unless ($_[0]);
 my ($adder) = 1 if (abs $_[0] < 1);
 round($_[0], 1+int(log10(abs $_[0]))-$_[1]-$adder);
}

sub sigdiglist {
  for my $i (1..$#_) {
    $_[$i] = sigdig($_[$i],$_[0]);
  }
  @_[1..$#_];
}

sub roundlist {
  for my $i (1..$#_) {
    $_[$i] = round($_[$i],$_[0]);
  }
  @_[1..$#_];
}


sub interpolate {
# call with $y = &interpolate(x1,y1,x2,y2,x)
   my ($x1,$y1, $x2, $y2, $x) = @_;
   return ($y1+$y2)/2 unless ($x1-$x2);    # in a vertical line, return the midpoint
   ($y2-$y1)/($x2-$x1)*($x-$x1)+$y1        # y = ((y2-y1)/(x2-x1)*(x1-x) + y1
}

sub interpolate2d {
# call with $z = &interpolate(x1,y1,x2,y2,z(x1y1),z(x1y2),z(x2y1),z(x2y2),x,y)
#
  my ($x1,$y1,$x2,$y2,$z11,$z12,$z21,$z22, $x,$y) = @_;
  $zx1 = interpolate($x1,$z11,$x2,$z21,$x);
  $zx2 = interpolate($x1,$z12,$x2,$z22,$x);
  $z1y = interpolate($y1,$z11,$y2,$z12,$y);
  $z2y = interpolate($y1,$z21,$y2,$z22,$y);
# printll($zx1,$zx2,$z1y,$z2y);
 (interpolate($x1,$z1y, $x2,$z2y, $x) + interpolate($y1,$zx1, $y2,$zx2,$y))/2;
}

sub seriessum {
    # similar to the Excel function, takes a value ($x), starting exponent ($i0), step value ($s), and array of coeffiecients (@c)
    # call as: seriessum($x,0,1,@coefficients)
    my ($i,$ss);
    my ($x,$i0,$s,@c) = @_;
    for $i (0..$#c) {
        $ss += $c[$i]*$x**($i0+$s*$i)
    }
    $ss;
}

# Psychrometric functions
# dealing with moist air properties

sub sathumidityratio {
# provides the humidity ratio at saturation (100% relative humidity)
# for a given dry bulb temperature (F)
# assumes barometric pressure of 1013 milibar unless provided in $_[2] (milibar units)
my $pstat = ($_[2] or 1013);
0.622*satpressure($_[0])/($pstat-satpressure($_[0]));
}

sub humidityratio {
# provides the humidity ratio lb moisture per lb of dry air
# for a given dry bulb temperature (F) and relative humidity
# assumes barometric pressure of 1013 milibar unless provided in $_[2] (milibar units)
my $pstat = ($_[2] or 1013);
my $p = satpressure($_[0])*$_[1]/100;
0.622*$p/($pstat-$p);
}

sub dewpointC {
# calculates dewpoint (deg C) from drybulb (deg C) and relative humidity
my ($T, $rh) = @_;
my ($b,$c) = (17.368, 238.88);
   ($b,$c) = (17.966, 247.15) if ($T < 0);
my ($gamma) = log($rh/100) + ($b*$T)/($c + $T);
($c*$gamma)/($b - $gamma);
}

sub dewpoint {
# calculates dewpoint (deg F) from drybulb (deg F) and relative humidity
    9/5*dewpointC(($_[0]-32)*5/9,$_[1])+32;
}


sub satpressure {
# provides the saturation pressure (in milibar)
# for a given dry bulb temperature in F
# for other pressure units add what you want in the second argument $_[1]
# example: convert_units(satpressure($dry_bulb_tempF,'mbar','psia');


satpressureC(($_[0]-32)*5/9,$_[1]);
}

sub satpressureC {
# provides the saturation pressure (in milibar)
# for a given dry bulb temperature in C
# for other pressure units add what you want in the second argument $_[1]
# example: convert_units(satpressureC($dry_bulb_tempC),'mbar','psia');

    my ($T,$units) = @_;
    $units = 'mbar' unless ($units);
    convert_units(6.112 * exp((18.678-$T/234.5)*($T/($T+257.14))),'mbar',$units)
}

sub wbenthalpy {
# for estimated enthalpy of air based on wet-bulb (0 BTU/lb at 0F)
# accuracy range is 10F to 95F

return (0.0109*$_[0]**2-0.6386*$_[0]+25.325) if ($_[0] >= 50);
return (0.0033*$_[0]**2+0.2042*$_[0]+1.8789) if ($_[0] < 50);
}

sub enthalpywb {
# for estimated wetbulb of air based on enthalpy (0 BTU/lb at 0F)
# accuracy range is 10F to 95F

return (-0.0116*$_[0]**2+1.9882*$_[0]+15.549) if ($_[0] >= 23);
return (-0.0387*$_[0]**2+3.3986*$_[0]-2.8721) if ($_[0] < 23);
}

sub airenthalpyC {
# Temperature in C, relative humidity 0-100, and pressure in milibar (default of 1013 - sea level)
# 0 degrees C equals 0 kJ/kg enthalpy

  my ($T,$rh,$pstat,$es,$e,$x) = @_;
  $pstat = 1013 unless ($pstat);
  $es = 6.112 * exp((18.678-$T/234.5)*($T/($T+257.14)));
  $e = $rh/100*$es;
  $x = .62198 * $e/($pstat-$e);
  (1.006 * $T)+$x*(1.84*$T + 2501)
}
sub airenthalpy {
# IP equivalent of above sub, at 0F is 0 BTU/lb enthalpy
(airenthalpyC(temperature($_[0],'f','c'),$_[1],$_[2])+17.884444444)/2.326
}

sub airdensityC {
 # inputs Db (C), RH (0-100), barometric pressure (mbar)
 my($T,$RH,$p) = @_;
 $p = 1013 unless $p;
 my $pv = satpressureC($T)*$RH/100;
 my $pd = $p-$pv;

 # outputs in kg/m^3, convert pressures to Pa (multply mbar by 100)
 ($pd*100/287.058+$pv*100/461.495)/($T+273.15)
}

sub ISDfile {
    my ($prevtemp,$prevdp,$prevpstat,$prevgmtstamp,$prevwindspd,$prevwinddir) = '';
    my @var = ('length','USAFMasterStationCatalog','WBAN','year','mon','day','hr','min','type','elev','call','winddir','windspd','temp','dewpt','pstat');
    @offset{@var} = (0,4,10,15,19,21,23,25,41,46,51,60,65,87,93,99);
    @length{@var} = (4,6,5,4,2,2,2,2,5,5,5,3,4,5,5,5);
    
    for (@_) {
        for $var (@var){
            substr($_,$offset{$var},$length{$var})
        }
    }
}

sub ISD {
    my ($prevtemp,$prevdp,$prevpstat,$prevgmtstamp,$prevwindspd,$prevwinddir) = @_[1,2,3,4,5,6];
    my @var = ('length','USAFMasterStationCatalog','WBAN','year','mon','day','hr','min','type','elev','call','winddir','windspd','temp','dewpt','pstat');
    my ($var,%value,%start,%end,$length,$USAFMasterStationCatalog,$WBAN,$year,$mon,$day,$hr,$min,$type,$temp,$dewpt,$pstat);
    @start{@var} = (1,5,11,16,20,22,24,26,42,47,52,61,66,88,94,100);
    @offset{@var} = (0,4,10,15,19,21,23,25,41,46,51,60,65,87,93,99);
    @length{@var} = (4,6,5,4,2,2,2,2,5,5,5,3,4,5,5,5);
    @end{@var} =   (4,10,15,19,21,23,25,27,46,51,56,63,69,92,98,104);
    # $_ = $_[0];
    # length USAFMSC WBAN   16-23:date 24-27:time 42-46:type 47-51:elev 52-56:call  88-92:db 94-98:dp 100-104:pstat
    @ISD = split //, $_[0];
   # print join ":", @ISD;
    for $var (@var){
	$value{$var} = join '',@ISD[($start{$var}-1)..($end{$var}-1)];
	# print STDOUT join '',@ISD[($start{$var}-1)..($end{$var}-1)]," ";
    }
    
    # return '' unless ($type =~ /FM/); # if the measurement type is not a facility measurement, skip everything
    # returns all values in metric units (C,m/s,mbar) except enthalpy (BTU/lb, where 0F = 0 BTU/lb)
    $value{'temp'} =~ s/\+//;
    $value{'dewpt'} =~ s/\+//;
    $value{'temp'} /= 10;
    $value{'dewpt'} /= 10;
    $value{'pstat'} /= 10;
    $value{'windspd'} /= 10;
    $value{'temp'} = $prevtemp if ($value{'temp'} >= 200);
    $value{'dewpt'} = $prevdp if ($value{'dewpt'} >= 200);
    $value{'pstat'} = $prevpstat if ($value{'pstat'} >= 2000);
    $value{'windspd'} = $prevwindspd if $value{'windspd'} > 900;
    $value{'winddir'} = $prevwinddir if $value{'winddir'} > 900;
    @value{'Wb','rh'} = wetbulbDPC(@value{'temp','dewpt','pstat'});
    $value{'h'} = airenthalpyC(@value{'temp','rh','pstat'});
    $value{'den'} = airdensityC(@value{'temp','rh','pstat'});    
    # $pstat = $pstat/1013.25*2992;  # converts from milibar to hundreths of in Hg for use in other functions
    # print STDOUT join " ",($WBAN,$USAFMasterStationCatalog,$year,$mon,$day,$hr,$min,$temp,$dewpt,$pstat,$rh,$Wb,$h,$windspd/10,$winddir),"\n";
    
   @value{'WBAN','USAFMasterStationCatalog','year','mon','day','hr','min','temp','dewpt','pstat','rh','Wb','h','windspd','winddir','den'};
}



sub noaadata {
    $_ = $_[0];
    # s/M/-/;
    /(.....)(....)(....)(\d{4})(\d{2})(\d{2}).+(\d\d:\d\d):\d\d.+5-MIN.+ (M?\d\d)\/(M?\d\d) A(\d{4}) -?\d+ (\d+)/;
    my ($WBAN,$icaocallsign,$stationcallsign,$year,$mon,$day,$localtime,$temp,$dewpt,$pstat,$rh) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11);
     $temp =~ s/M/-/;
     $dewpt =~ s/M/-/;
    
    # temp and dewpoint are in degrees C, pstat in hundredths of inches of Hg (3015 => 30.15" Hg)
    ($WBAN,$icaocallsign,$stationcallsign,$year,$mon,$day,$localtime,$temp,$dewpt,$pstat,$rh);
}

sub wetbulb {
    # inputs in F for Db, 0-100 integer for RH%, and in Hg for pressure
    # pipes it to a formula using C and mbar units.
    # takes about 0.04ms per iteration (2.4GHz i5)
    9/5*wetbulbC(($_[0]-32)*5/9,$_[1],convert_units($_[2],'inhg','mbar'))+32;
}

sub wetbulbDP {
    # inputs in F for Db and dewpoint, and in Hg for pressure
    # pipes it to a formula using C and mbar units.
    9/5*wetbulbDPC(($_[0]-32)*5/9,($_[1]-32)*5/9,convert_units($_[2],'inhg','mbar'))+32;
}

sub wetbulbC {
# this calculates the Wetbulb iteratively.  You provide a temp and relative humidity (and pressure)
# and the iteration attempts to calculate the same RH with the given dry bulb and a varying wetbulb.
# when the two relative humidities are the same, the wetbulb value is returned.
# I have checked several points on a psychrometric chart and several online calculators
# and it looks very good for temps between -25C and 100C

  my ($T,$rhin,$pstat,$Tdin) = @_; # temps need to be Celsius, pstat in milibar, humidity between 0-100
  my ($Td,$Tw,$rh,$ew,$es,$e,$count);
  return $T if ($T > 100 or $T < -25 or $rhin < 0 or $rhin >= 100); # range is -25 to 100C, 0-100% relative humidity.
  $rh = 100; # start here so the iteration goes atleast once
  $pstat = 1013 unless ($pstat);
  my ($mult) = 1;
  $mult = 1 - 9*($T/25) if $T < 0;  # makes each iteration more precise at lower temps, but requires more iterations

  $Tw = $T-(100-$rhin)/100*(.0055*$T**2+.02738*$T+5.6393);
  # initial Wetbulb guesstimate, pretty good to within a couple degrees,
  # helps limit the number of iterations

    while (abs($rh-$rhin) > 0.2 and $count<100){
     $es = 6.112 * exp((18.678-$T/234.5)*($T/($T+257.14)));
     $ew = 6.112 * exp((18.678-$Tw/234.5)*($Tw/($Tw+257.14)));
     $e = $ew-$pstat*($T-$Tw)*0.00066*(1+(0.00115*$Tw));
     if ($e < -100){$e = -100;}
     if ($e > $es) {$e = $es;}
     $rh = 100*$e/$es;
  #   $Td = (243.5 * log($e/6.112))/(17.67-log($e/6.112)); # could use dewpoint as a check if you have it
     $Tw -=.1*($rh-$rhin)/$mult;  # adjust Wb guess, 10% of the difference in calculated rh and provided rh
  #   print $Tw."\n";
     $count++; # keeps it from running away (no more than 100 iterations, generally only takes 3 to 10)
    }
  #  print "count: ".$count."  ";  # for troubleshooting/benchmarking
    ($Tw,$rh);
}

sub wetbulbDPC {
# this calculates the Wetbulb and Relative Humidity iteratively using drybulb, dewpoint, pressure
# and the iteration attempts to calculate the same dewpoint with the given dry bulb and a varying wetbulb.
# when the two dewpoints are the same, the wetbulb value is returned.
# I have checked several points on a psychrometric chart and several online calculators
# and it looks very good for temps between -25C and 100C

  my ($T,$Tdin,$pstat,) = @_; # temps need to be Celsius, pstat in milibar, humidity between 0-100
  my ($Td,$Tw,$rh,$ew,$es,$e,$count);
  return $T if ($T > 100 or $T < -25 or $rhin < 0 or $rhin > 100); # range is -25 to 100C, 0-100% relative humidity.
  $Td = 1000; # start here so the iteration goes atleast once
  $pstat = 1013 unless ($pstat);
  my ($mult) = 1;
  $mult = 10 if $T < 0;  # makes each iteration more precise at lower temps, but requires more iterations

  $Tw = $Tdin;
  # initial Wetbulb guesstimate, pretty good to within a couple degrees,
  # as dewpoint and wetbulb are generally pretty close

    while (abs($Td-$Tdin) > 0.1 and $count<1000){
     $es = 6.112 * exp((18.678-$T/234.5)*($T/($T+257.14)));
     $ew = 6.112 * exp((18.678-$Tw/234.5)*($Tw/($Tw+257.14)));
     $e = $ew-$pstat*($T-$Tw)*0.00066*(1+(0.00115*$Tw));
     if ($e <= 0){$e = 0.01;}
     if ($e > $es) {$e = $es;}
      $rh = 100*$e/$es;
     $Td = (243.5 * log($e/6.112))/(17.67-log($e/6.112));
     $Tw -= 0.1*($Td-$Tdin)/$mult;  # adjust Wb guess, 10% of the difference in calculated dewpoint and provided dewpoint
  #   print $Tw."\n";
     $count++; # keeps it from running away
    }
  #  print "count: ".$count."  ";  # for troubleshooting/benchmarking
    ($Tw,$rh);
}

sub psychrometrics {
	my ($T,$rh,$pstat,$Tdin) = @_; # temps need to be Celsius, pstat in milibar, humidity between 0-100
	my ($Td,$Tw,$x,$h);
	unless ($pstat > 800) {$pstat = 1013;}
	if ($Tdin ne ''){
		($Tw,$rh) = wetbulbDPC($T,$Tdin,$pstat);
		$Td = $Tdin;
	}
	else {
		$Tw = wetbulbC($T,$rh,$pstat);
		$Td = dewpointC($T,$rh);
	}
	$h = airenthalpyC($T,$rh,$pstat);
	($T,$Tw,$rh,$h,$Td,$pstat);
}

sub psychrometrics_IP {
    my ($T,$Tw,$rh,$h,$Td,$pstat) = psychrometrics(temperature($_[0],'f','c'),$_[1],$_[2],temperature($_[3],'f','c'));
    (temperature($T,'c','f'),temperature($Tw,'c','f'),$rh,convert_units($h,'kj/kg','btu/lb'),temperature($Td,'c','f'),$pstat);
}

sub getrefrigerantproperties {

    unless ($getrefrigerantproperties){ # if its already done, don't do it again.
      open(REF, "refproperties.txt");   # this file is about 5MB and is slurped into memory.
       my $i = 0;
       while (<REF>){
	  my @array = split;
	  ($j,$GRref[$i],$GRTref[$i],$GRPref[$i],$GRpf[$i],$GRvf[$i],$GRuf[$i],$GRhf[$i],$GRsf[$i],$GRcvf[$i],$GRcpf[$i],$GRvsf[$i],$GRJTf[$i],$GRmuf[$i],$GRkf[$i],$GRSTf[$i],$GRpg[$i],$GRvg[$i],$GRug[$i],$GRhg[$i],$GRsg[$i],$GRcvg[$i],$GRcpg[$i],$GRvsg[$i],$GRJTg[$i],$GRmug[$i],$GRkg[$i]) = @array ;
	  unless ($GRref[$i] eq $GRref[$i-1]) {
	    $GRindexStart{$GRref[$i]} = $i;
	    $GRindexEnd{$GRref[$i-1]} = $i-1;
	  }
	  $i++;
       }
       $GRindexEnd{$GRref[$i]} = $i;
       $getrefrigerantproperties = 1;    # set flag so no need to repeat
      close REF;
    }

}

sub refrigerantproperties {
    # created 11/15/2011 by Steve Driver, PE, CEM
    # uses data from NIST website (about 5MB of data is brought into memory)
    # accurate from -100F to +300F, or the critical temp.
    # Does not interpolate between values but does round to nearest
    # amazingly this subroutine ran accurately on the first test and no compile errors
    
    getrefrigerantproperties();
     my ($ref,$val,$TorP) = @_;
     my ($i,$j) = ($GRindexStart{$ref},$GRindexEnd{$ref});
     if ($TorP =~ /P/i) {
       while ($GRPref[$i] < $val){$i++}
       $i-- if (abs($GRPref[$i]-$val) > abs($GRPref[$i-1]-$val));
       return ($GRref[$i],$GRTref[$i],$GRPref[$i],$GRpf[$i],$GRvf[$i],$GRuf[$i],$GRhf[$i],$GRsf[$i],
       $GRcvf[$i],$GRcpf[$i],$GRvsf[$i],$GRJTf[$i],$GRmuf[$i],$GRkf[$i],$GRSTf[$i],$GRpg[$i],$GRvg[$i],
       $GRug[$i],$GRhg[$i],$GRsg[$i],$GRcvg[$i],$GRcpg[$i],$GRvsg[$i],$GRJTg[$i],$GRmug[$i],$GRkg[$i]);
     }
     else {$i = $GRindexStart{$ref}+round(($val+100)*10,0); }
    
     ($GRref[$i],$GRTref[$i],$GRPref[$i],$GRpf[$i],$GRvf[$i],$GRuf[$i],$GRhf[$i],$GRsf[$i],
       $GRcvf[$i],$GRcpf[$i],$GRvsf[$i],$GRJTf[$i],$GRmuf[$i],$GRkf[$i],$GRSTf[$i],$GRpg[$i],$GRvg[$i],
       $GRug[$i],$GRhg[$i],$GRsg[$i],$GRcvg[$i],$GRcpg[$i],$GRvsg[$i],$GRJTg[$i],$GRmug[$i],$GRkg[$i]);
}


sub refrigerantproperties_sh {  # inputs are refrigerant, saturation temp and amount of superheat
  getsuperheatedrefrigerantproperties() unless ($gotshrefproperties);
  my ($ref,$sattempup,$superheatup,$sattempdn,$superheatdn) = ($_[0],round($_[1],0,'up'),round($_[2],0,'up'),round($_[1],0,'d'),round($_[2],0,'d'));
  my $h = interpolate2d($sattempdn,$superheatdn,$sattempup,$superheatup,${GRSHh.$ref}[$sattempdn][$superheatdn],${GRSHh.$ref}[$sattempdn][$superheatup],${GRSHh.$ref}[$sattempup][$superheatdn],${GRSHh.$ref}[$sattempup][$superheatup],$_[1],$_[2]);
  my $s = interpolate2d($sattempdn,$superheatdn,$sattempup,$superheatup,${GRSHs.$ref}[$sattempdn][$superheatdn],${GRSHs.$ref}[$sattempdn][$superheatup],${GRSHs.$ref}[$sattempup][$superheatdn],${GRSHs.$ref}[$sattempup][$superheatup],$_[1],$_[2]);
  my $p = interpolate2d($sattempdn,$superheatdn,$sattempup,$superheatup,${GRSHp.$ref}[$sattempdn][$superheatdn],${GRSHp.$ref}[$sattempdn][$superheatup],${GRSHp.$ref}[$sattempup][$superheatdn],${GRSHp.$ref}[$sattempup][$superheatup],$_[1],$_[2]);
  my $u = interpolate2d($sattempdn,$superheatdn,$sattempup,$superheatup,${GRSHu.$ref}[$sattempdn][$superheatdn],${GRSHu.$ref}[$sattempdn][$superheatup],${GRSHu.$ref}[$sattempup][$superheatdn],${GRSHu.$ref}[$sattempup][$superheatup],$_[1],$_[2]);
  my $P = interpolate2d($sattempdn,$superheatdn,$sattempup,$superheatup,${GRSHP.$ref}[$sattempdn][$superheatdn],${GRSHP.$ref}[$sattempdn][$superheatup],${GRSHP.$ref}[$sattempup][$superheatdn],${GRSHP.$ref}[$sattempup][$superheatup],$_[1],$_[2]);
  my $v = interpolate2d($sattempdn,$superheatdn,$sattempup,$superheatup,${GRSHv.$ref}[$sattempdn][$superheatdn],${GRSHv.$ref}[$sattempdn][$superheatup],${GRSHv.$ref}[$sattempup][$superheatdn],${GRSHv.$ref}[$sattempup][$superheatup],$_[1],$_[2]);

  ($ref,$_[1]+$_[2],$P,$p,$v,$u,$h,$s);
}


sub getsuperheatedrefrigerantproperties {
  unless ($gotshrefproperties) {
    open (REF, 'superheatedrefrigerantproperties.txt') or print "cant open super heat ref properties".$!;
    <REF>;
    while (<REF>){
	my @array = split;
	my ($ref,$T,$P,$pg,$vg,$ug,$hg,$sg,$Cvg,$Cpg,$vsg,$JTg,$mug,$kg,$sattemp,$superheat) = @array;
	${GRSHh.$ref}[$sattemp][$superheat]  = $hg;
	${GRSHs.$ref}[$sattemp][$superheat]  = $sg;
	${GRSHp.$ref}[$sattemp][$superheat]  = $pg;
	${GRSHu.$ref}[$sattemp][$superheat]  = $ug;
	${GRSHP.$ref}[$sattemp][$superheat]  = $P;
	${GRSHCp.$ref}[$sattemp][$superheat] = $Cpg;
	${GRSHCv.$ref}[$sattemp][$superheat] = $Cvg;
    }
   close REF;
   $gotshrefproperties = 1;  # set flag so no need to repeat
  }
}

sub refproperties_Th {    # gets refrigerant properties from known sattemp and enthalpy
   my ($ref,$Tsat,$P,$pf,$vf,$uf,$hf,$sf,$cvf,$cpf,$vsf,$JTf,$muf,$kf,$STf,$pg,$vg,$ug,$hg,$sg,$cvg,$cpg,$vsg,$JTg,$mug,$kg) = refrigerantproperties($_[0],$_[1],'T');

   if ($_[2] > $hg) { # superheated zone
    refrigerantproperties_sh($_[0],$Tsat,($_[2] - $hg)/$cpg);
   }
   if ($_[2] < $hf){ # subcooled zone
    $T = $Tsat - ($hf - $_[2])/$cpf;
   }
}

sub refproperties_Ph {    # gets refrigerant properties from known satpress and enthalpy
   my ($ref,$Tsat,$P,$pf,$vf,$uf,$hf,$sf,$cvf,$cpf,$vsf,$JTf,$muf,$kf,$STf,$pg,$vg,$ug,$hg,$sg,$cvg,$cpg,$vsg,$JTg,$mug,$kg) = refrigerantproperties($_[0],$_[1],'P');

   if ($_[2] > $hg) { # superheated zone
   return refrigerantproperties_sh($_[0],$Tsat,($_[2] - $hg)/$cpg); # need saturation temp and amount of superheat
   }
   elsif ($_[2] < $hf){ # subcooled zone
    my $T = $Tsat - ($hf - $_[2])/$cpf;
    return ($_[0],$_[1],$T,$pf,$vf,$uf+($ug-$uf)*$x,$_[2],$sf+($sg-$sf)*$x);
   }
   else { # saturation zone
    my $x = ($h-$hf)/($hg-$hf);
    return ($_[0],$_[1],$Tsat,$pf+($pg-$pf)*$x,$vf+($vg-$vf)*$x,$uf+($ug-$uf)*$x,$_[2],$sf+($sg-$sf)*$x);
   }
}

sub refrigerantcompressor {   # takes input of suction refrigerant properties, discharge pressure, and compressor efficiency


 1;
}

sub steamproperties {
    steamproperties_SI($_[0],$_[1],$_[2],$_[3],$_[4],'psia','F','btu/lb','btu/lbf','lb/ft^3','ft/s')
}

 # provides superheated steam properties for known Pressure and entropy
 # if you want wet steam properties, calculate the quality from the entropy and use the main steamproperties sub
 
sub steamproperties_Ps {
    steamproperties_SI($_[0],0,0,$_[1],"",'psia','F','btu/lb','btu/lbf','lb/ft^3','ft/s')
}

sub steamproperties_Ph {
    steamproperties_SI($_[0],0,$_[1],0,"",'psia','F','btu/lb','btu/lbf','lb/ft^3','ft/s')
}

sub satliquid {
# input pressure in psia
steamproperties($_[0],'sat',0,0,0);
}

sub satgas {
# input pressure in psia
steamproperties($_[0],'sat',0,0,1);
}

sub wetsteam {
# input pressure in psia and quality between 0 and 1
  my $n;
  my ($P,$x) = @_;
    return satliquid($_[0]) unless ($x>0);
    return satgas($_[0]) unless ($x<1);
  my (@f) = satliquid($_[0]);
  my (@g) = satgas($_[0]);

  for $n (0..$#f) {
    $wetsteam[$n] = $f[$n]*$x+$g[$n]*(1-$x);
    #$wetsteam[$n] = interpolate(0,$f[$n],1,$g[$n],$x);
  }
@wetsteam;
}

sub satpress {
convert_units((satsteam_IAPWS97_R4_T(convert_units($_[0],'f','k')))[0],'mpa','psi');
}

# call as extractionturbine($P1,$t1,$p2ext,$p2,$efficiency.extstage,$efficiency.condensing.stage,$ext.steam.flow,$total.kWoutput)
#  A large unit using 600psig steam at 500F, 20psig extraction, 0.5psia vacuum, 70% eff 1st stage, 65% eff final stage, 20000lb/hr extraction, 3500kW shaft output
#  extractionturbine(615,500,35,0.5,0.70,0.65,20000,3500)
# it returns ($total.steam.flow, $ext.steam.flow, $enthaply.steam.entering, $enthaply.steam.extraction, $enthaply.condensate.extraction
#             $enthaply.steam.condenser, $enthaply.condensate.condenser, $enthaply.condensate.combined, $kW.from.extraction.steamflow)
# if the provided extraction flow provides more kW than the kWoutput value, the returned extraction flow is modified down.
# this can be used to model a full condensing turbine by setting the extraction flow to zero
# or to model a back-pressure turbine by increasing the input extraction value to well above
# takes about 7.5ms per iteration on 2.5 GHz i5
sub extractionturbine {

  my ($P1,$T1,$P2ext,$P2,$eff1ststage,$effcondstage,$esf,$totalkWload) = @_;
  my ($powerfromextraction,$tsf,$condenserstmflow);
  my ($h1,$s1,$u1,$p1,$v1);
  my ($h2pext,$s2pext,$x2pext,$T2ext,$dhext,$h3ext);
  my ($h2p,$s2p,$x2p,$t2,$dh,$h3);
  
  ($P1,$T1,$h1,$s1,$u1,$p1,$v1) = steamproperties_IP($P1,$T1,0,0,1);
  ($h2pext,$s2pext,$x2pext,$T2ext,$dhext,$h3ext) = turbineout($P1,$T1,$P2ext,$eff1ststage/100);   # properties of extraction steam
  ($h2p,$s2p,$x2p,$T2,$dh,$h3) = turbineout($P1,$T1,$P2,$effcondstage/100);                       # properties of condenser steam
  

    $powerfromextraction = $esf*$dhext/3412;      # kW from extraction flow only
    if ($powerfromextraction >= $totalkWload) {
      $esf = $totalkWload*3412/$dhext;
      $powerfromextraction = $totalkWload;
    }
      # steam flow to condenser = (total kW load - kW from first stage)*3412BTU/kWh divided by steam enthalpy delta
      # total steam flow = above steam flow to condenser + extraction steam flow
      $condenserstmflow = ($totalkWload-$powerfromextraction)*3412/$dh;
      $tsf = $condenserstmflow+$esf;
      $h4 = ($esf*$h3ext + $condenserstmflow*$h3)/$tsf;
      # h4 equals the combined enthalpy of the steam turbine surface condenser output and condensed steam (at the extraction pressure) that
      # will go back to the boiler
      
     # return total mass steam flow (lb/hr), enthalpy inlet, extraction, condenser inlet, condenser, and mixed back to boiler
  ($tsf,$esf,$condenserstmflow,$h1,$h2pext,$h3ext,$h2p,$dh,$h3,$h4,$powerfromextraction);
} 

# determines discharge enthalpy, entropy, quality, and delta h' of a turbine with a given
# inlet pressure (p1) and temp (t1), discharge pressure (p2) and efficiency
# about 2.5ms per iteration (2.4GHz i5)
sub turbineout { 
  my ($h1,$s1,$u1,$p1,$v1);
  my ($hf2,$sf2,$uf2,$pf2,$vf2);
  my ($T2,$hg2,$sg2,$ug2,$pg2,$vg2);
  my ($P1,$T1,$P2,$eff) = @_;
  my ($h2p,$s2p,$u2p,$p2p,$v2p,$t2,$x2p);

  ($P1,$T1,$h1,$s1,$u1,$p1,$v1) = steamproperties_IP($P1,$T1,0,0,1);
  ($P2,$T2,$hf2,$sf2,$uf2,$pf2,$vf2) = steamproperties_IP($P2,'sat',0,0,0);
  ($P2,$T2,$hg2,$sg2,$ug2,$pg2,$vg2) = steamproperties_IP($P2,'sat',0,0,1);

  # Determine isentropic discharge properties for wet or sat steam
  my $x2 = ($s1-$sf2)/($sg2-$sf2);

  if ($x2 > 1) { # check if isentropic discharge is superheated
    $x2 = 1;
    ($P2,$T2,$hg2,$sg2,$ug2,$pg2,$vg2) = steamproperties_IP($P2,0,0,$s1); # determine isentropic discharge steam properties
  }

  my ($h2,$s2) = ($hf2+($hg2-$hf2)*$x2,$s1); # works if wet, saturated or superheated

  # From turbine's efficiency (typically 65% to 85%) determine real discharge properties
  $h2p = $h1 - ($h1-$h2)*$eff;
  $x2p = ($h2p-$hf2)/($hg2-$hf2);
  $s2p = $sf2 + ($sg2-$sf2)*$x2p;

  if ($x2p > 1) { # check if actual discharge is superheated
    $x2p = 1;
    ($P2,$T2,$h2p,$s2p,$u2p,$p2p,$v2p) = steamproperties_IP($P2,0,$h2p); # determine actual discharge steam properties
  }

  # h2',s2',x2',T2,delta h', h3
  ($h2p,$s2p,$x2p,$T2,$h1-$h2p,$hf2);

}

sub LMTD {  # determines the log-mean temperature difference of a parallel flow heat exchanger
  my ($T1,$T2,$t1,$t2) = @_;
  my $adder = 0;
  # in order: T1/T2 are temp in/out of heating fluid, t1/t2 are temp in/out of heated fluid
  # for a cross-flow HX, swap t1 and t2.
  if (($T2-$t2)/($T1-$t1) == 1){$adder = .01;}
(($T2-$t2)-($T1-$t1))/log(($T2-$t2)/($T1-$t1+$adder));
}

# water-to-water, HX
sub WWHX {
    my ($T1,$T2,$t1,$t2,$U,$A,$M,$m,$C,$c) = @_;
    $C = 1 unless $C;
    $c = 1 unless $c;
    
}


#  totals subroutines are good for numerical integrations.  if you know x,y values
#  it will sum the area under the curve created by the x/y values.
#  it will also sort the x values if not sorted already
#  will use a straight line from each y value, not produce a curve
#  y-values with identical x values will be averaged together before totaling
#  there's no real limit to the number of pairs other than your computer's memory.
#  The area under the curve will be from the lowest x value to the highest x value

sub totalsxy { # call as: totalsxy(@xy) or totalsxy(%y), values are inline x1, y1, x2, y2, x3, y3...
  my (@x,$dx,$dy,$i,%y,%count);
  for $i (0..($#_+1)/2){
    $y{$_[$i*2]} += $_[$i*2+1];  # creates or adds values to y(x) 
    $count{$_[$i*2]}++;          # keeps track of how many y values occur for same x value, to be used to average
  }
  @x = sort keys %y;             # sort, so initial sorting is not required in @_
  for $i (0..$#x-1) {
    $dx = $x[$i+1]-$x[$i];
    $dy += (($y{$x[$i+1]}/$count{$x[$i+1]})-($y{$x[$i]}/$count{$x[$i]}))*$dx;
  }
$dy;
}

sub totals { # call as: totals(@x,@y), values are grouped x1,x2,x3...y1,y2,y3...
  my (@x,$dx,$dy,$i,%y,$pairs,%count);
  $pairs = ($#_+1)/2;
  for $i (0..($#_-1)/2){
    $y{$_[$i]} += $_[$i+$pairs];  # creates or adds values to each y(x) 
    $count{$_[$i]}++;             # keeps track of how many y values occur for same x value, to be used to average
  }
  @x = sort keys %y;             # sort, so initial sorting is not required in @_
  for $i (0..$#x-1) {
    $dx = $x[$i+1]-$x[$i];
    $dy += (($y{$x[$i+1]}/$count{$x[$i+1]})-($y{$x[$i]}/$count{$x[$i]}))*$dx;
  }
$dy;
}


sub properties { # returns refrigerant selected property (pressure, enthalpy of liquid or gas)
    # about 30 usec per iteration
# Since R134a is many times referred to as R134, you can use either designation (134 or 134a)

# new method uses a 4th order polynomial to calculate values. Only oefficients are stored in this function, instead of the actual values
# 10 refrigerants are here, including the original 5 and 5 lesser used refrigerants

# This method uses the refrigerant properties values from NIST and created 4th order regression coefficients below
# These coeficients were created with data between 0 and 150F, and are most accurate between 10F and 120F.
# the enthalpies of the most common refrigerants (134,123,22,11,12) are within 0.01% of the NIST values
# pressures at low temp begin to lose regression on low pressure refrigerants (11 and 123) drifting as far as 0.119% and 0.154% at 0F.
# but at 10F, the errors are 0.042%/0.33% and only go down as temps increase to 150F
# Other error limits are:
# R-125 pressure/enth: 0.436%/1.70% within 0-150F, 0.136%/0.162% within 10-120F
# R-32 pressure/enth: 0.144%/0.107% within 0-150F, 0.045%/0.037% within 10-120F
# R-152a pressure/enth: 0.016%/0.007% within 0-150F, 0.006%/0.006% within 10-120F
# R-500 pressure/enth: 0.018%/0.007% within 0-150F, 0.007%/0.006% within 10-120F
# R-410a pressure/enth: 0.276%/0.746% within 0-150F, 0.086%/0.087% within 10-120F

# newly added, entropy (s), differential entropy (ds/dT), Cv, and Cp in the vapor range
# for R-11, 12, 22, 123, and 134

my ($ref,$T,$parameter) = @_;
$ref =~ s/^R?-?(\d+)a?/$1/;  # take out any R- at the beginning, only use numerical digits

local @s11 = (0.407896,-0.000104024,3.88616E-7,0,0);
local @sg11 = (0.407896,-0.000104024,3.88616E-7,0,0);
local @cv11 = (0.116833658536585,1.41548780487805E-4,0,0,0);
local @cp11 = (0.131451219512195,1.86390243902439E-4,0,0,0);
local @dsdt11 = (2.83011E-4,-2.50089E-7,5.26221E-10,0,0);

local @s123 = (0.398778,-4.62082E-5,3.67264E-7,0,0);
local @sg123 = (0.398778,-4.62082E-5,0.000000367264,0,0);
local @cv123 = (0.134685296167247,0.000200506968641115,0,0,0);
local @cp123 = (0.147071289198606,0.000250358885017422,0,0,0);
local @dsdt123 = (0.000319894,-2.25029E-7,6.59297E-10,0,0);

local @s134 = (0.414027142857143,-4.91106271777004E-05,0,0,0);
local @sg134 = (0.414027142857143,-4.91106271777004E-05,0,0,0);
local @cv134 = (0.167498675958188,0.000425132404181185,0,0,0);
local @cp134 = (0.206769,0.000138852,4.88065E-6,0,0);
local @dsdt134 = (0.000429334,-2.51163E-7,5.59875E-9,0,0);

local @s12 = (0.373690557491289,-3.93240418118467E-05,0,0,0);
local @sg12 = (0.373690557491289,-3.93240418118467E-05,0,0,0);
local @cv12 = (0.119303972125436,0.000213700348432056,0,0,0);
local @cp12 = (0.132077421602787,0.000475605400696864,0,0,0);
local @dsdt12 = (0.000306539,-2.54381E-7,2.91108E-9,0,0);

local @s22 = (0.423617909407666,-0.000170309233449477,0,0,0);
local @sg22 = (0.423617909407666,-0.000170309233449477,0,0,0);
local @cv22 = (0.124861324041812,0.000344306620209059,0,0,0);
local @cp22 = (0.174427,-6.26943E-5,6.51969E-6,0,0);
local @dsdt22 = (0.000355318,-3.35327E-7,7.28989E-9,0,0);
# (2.75411724E-01,1.41599339E-04,1.24080130E-06,-9.27259831E-09,3.20224799E-11x)
# (1.74932394E-01,2.14920081E-04, 1.81540683E-06,-1.30704192E-08, 4.31889259E-11)
# going to add the new refrigerant R-1233zd
local @p1233zd = (3.02917357059123, 0.0815147989978275, 0.00107150423041361, 5.96096308954789E-06, 1.28023134445871E-08);
local @hl1233zd = (77.1077282600437, 0.271711758635383, 0.000173868904896192, -5.76705799073827E-07, 1.80193353437025E-09);
local @hv1233zd = (168.14106500591, 0.171661573770214, -9.73638521036255E-05, 7.22480095132269E-07, -2.55711709784147E-09);

local @p134 = (21.1815057384655, 0.496050189152638, 0.00465575675092315, 1.87263988402871E-05, 2.77520380008598E-08);
local @hl134 = (75.9454767344438, 0.309671037171334, 0.000188143040936357, -3.19246336772546E-07, 4.109875884696E-09);
local @hv134 = (166.880701045623, 0.148696999399191, -0.000159781938995049, 4.94653212773549E-07, -6.21240809969188E-09);
local @p123 = (1.95997543440465, 0.0591380088663119, 0.000693348421246907, 4.92728926989778E-06, 1.07100703657277E-08);
local @hl123 = (78.5418738729897, 0.231973752974497, 0.000075051365736326, 4.05860790823342E-09, 1.85949493395813E-10);
local @hv123 = (159.5345633601, 0.141442546010348, 4.33425795886886E-05, -2.05182466901052E-07, -1.39655419823132E-10);
local @p22 = (38.7473489473276, 0.809530699204126, 0.00668241097597789, 2.13712921365257E-05, 2.70357485130374E-08);
local @hl22 = (77.2537601135899, 0.268346255356999, 0.00020983535738034, -6.47243824970046E-07, 5.92726898454291E-09);
local @hv22 = (171.214707522032, 0.102744449275518, -0.000257324840761906, 8.45795065852955E-07, -8.45332541614628E-09);
local @p11 = (2.55077339450189, 0.0718332339735294, 0.000785965547177277, 5.08372373505965E-06, 9.0483999831864E-09);
local @hl11 = (79.5186511722145, 0.20233694743762, 4.52240889910598E-05, 7.20375447455814E-08, 1.32439094739602E-10);
local @hv11 = (163.765853400275, 0.121672304295004, 3.02352740969062E-05, -1.81317359109194E-07, -2.52397640358505E-10);
local @p12 = (23.8164260463422, 0.504333434361695, 0.00414304610529854, 1.46793410326685E-05, 1.25869609228492E-08);
local @hl12 = (79.0003659442976, 0.21614495220294, 0.000123300357861394, -1.01659210597529E-07, 1.84463654000989E-09);
local @hv12 = (148.28641684517, 0.112035873262209, -8.65978782113442E-05, 4.60673263463025E-08, -2.73671263051068E-09);
local @p125 = (53.3513615744123, 1.0409216496534, 0.00996622697197418, 6.25753434766245E-06, 1.25998246351455E-07);
local @hl125 = (76.9392913514647, 0.243028915591781, 0.00178430697951555, -1.99335387932829E-05, 8.82140448741388E-08);
local @hv125 = (139.09831588291, 0.190983073680365, -0.00257566432841058, 3.01654141598538E-05, -1.3377305250675E-07);
local @p152 = (19.2286114557468, 0.446330688052983, 0.00408822361372919, 1.73292356832699E-05, 2.15224399884829E-08);
local @hl152 = (73.2621865135426, 0.39223421755858, 0.000222232350138465, -9.03857714715568E-08, 3.24404245982653E-09);
local @hv152 = (212.758275682487, 0.17479716476755, -0.000180301691924783, 1.30365959251077E-07, -4.84810867043653E-09);
local @p32 = (64.038882439078, 1.29864886985753, 0.0110878888102209, 2.66048126039344E-05, 8.93747409161238E-08);
local @hl32 = (73.0507177387897, 0.38768329670426, 0.000712004196591174, -5.87196894413429E-06, 3.4801365881981E-08);
local @hv32 = (219.615239593084, 0.0951030844100599, -0.00115127190695329, 8.56869275194039E-06, -5.18923186065865E-08);
local @p500 = (22.6144186236063, 0.489136714828815, 0.00412868261250733, 1.53736134311264E-05, 1.49280564380451E-08);
local @hl500 = (77.4969629334397, 0.262280339726118, 0.000149220539837968, -9.87055695463398E-08, 2.21128089100134E-09);
local @hv500 = (165.178043860547, 0.128479331636607, -0.000111148277404251, 6.81535681672813E-08, -3.28989839297125E-09);
local @p410 = (58.6951220067451, 1.16978525975546, 0.0105270578910978, 1.64311734757961E-05, 1.07686493633796E-07);
local @hl410 = (74.9950045451274, 0.315356106148021, 0.00124815558805335, -1.29027538687085E-05, 6.15077053780595E-08);
local @hv410 = (179.356777737997, 0.143043079045212, -0.00186346811768194, 1.93670534558972E-05, -9.28326855566684E-08);

return '' unless (${$_[2].$ref}[0]); # check input parameters

my $sum = 0;
for $i (0..4){ $sum +=  ${$_[2].$ref}[$i] * $T**$i;}

$sum;
}



# sub refrigerantproperties { properties(@_) }
sub refproperties { properties(@_) }


sub CoP {

my ($ref,$chws,$chwr,$cws,$cwr,$chwapp,$cwapp,$vfdload) = @_;
unless ($vfdload) {$vfdload = 1;}
# if Chiller has VFD, the given load (1-100%) will vary the discharge temp rise from 5 to 30 deg F
# if no VFD, leave blank or enter 1 in arguments.
my $dtemprise = 5+$vfdload*25;
  my $evapsatt = $chws-$chwapp;
  my $evapsatp = &properties($ref,$evapsatt,'p');
  my $superheath = &properties($ref,$evapsatt,'hv');
  my $condsatt = $cwr+$cwapp;
  my $condsatp = &properties($ref,$condsatt,'p');
  my $subcoolh = &properties($ref,$condsatt,'hl');
  my $refeff = $superheath - $subcoolh;
  my $dtemph = &properties($ref,$condsatt+$dtemprise,'hv');
  my $hoc = $dtemph-$superheath;
# if issues arrise, use these displays to troubleshoot
#print "ref= ".$ref."\n";
#print "evapsatp= ".$evapsatp."\n";
#print "condsatt= ".$condsatt."\n";
#print "superheath= ".$superheath."\n";
#print "subcool= ".$subcoolh."\n";
#print "dtemph= ".$dtemph."\n";
#print "refeff= ".$refeff."\n";
#print "COP= ".$refeff/$hoc."\n";
#print "hoc= ".$hoc."\n";
  $refeff/$hoc;
}


sub DFkwton {
  my ($ref,$dchws,$dchwr,$dcws,$dcwr,$chwapp,$cwapp,$dkwton,$chws,$chwr,$cws,$cwr,$vfdload) = @_;
  $dkwton * CoP($ref,$dchws,$dchwr,$dcws,$dcwr,$chwapp,$cwapp,$vfdload)/CoP($ref,$chws,$chwr,$cws,$cwr,$chwapp,$cwapp,$vfdload)
}


# Calculates the heat transfer from a U-value, Area, and fluid temps in/out
# inputs can be in any units the user prefers, as long as they are consistent
sub hxheat {
  my ($U,$A,$T1,$T2,$t1,$t2) = @_;
  ($A*$U*LMTD($T1,$T2,$t1,$t2));
}



sub CAP_FT {
  my ($chws,$cws) = @_;
  my ($a,$b,$c,$d,$e,$f) = (-0.29861976, 0.02996076, -0.00080125, 0.01736268, -0.00032606, 0.00063139);
  $a+$b*$chws+$c*$chws**2+$d*$cws+$e*$cws**2+$f*$chws*$cws;
}

sub ChillerkW {
# $ratedkw is at rated tonnage at temperatures: 44/54/85/95
  my ($chws,$cws,$ton,$ratedkw,$ratedton) = @_;
  my ($PLR,$EIR_FPLR,$EIR_FT,$Qavail);
  my ($a,$b,$c,$d,$e,$f) = (0.51777196, -0.00400363, 0.00002028, 0.00698793, 0.00008290, -0.00015467);
  my ($a1,$b1,$c1) = (0.17149273, 0.58820208, 0.23737257);
  my $CAP_FT = CAP_FT($chws,$cws);

  $PLR = $ton/($CAP_FT * $ratedton);
  $EIR_FPLR = $a1 + $b1*$PLR + $c1*$PLR**2;
  $EIR_FT = $a + $b*$chws + $c*$chws**2 + $d*$cws + $e*$cws**2 + $f*$chws*$cws;
  $ratedkw * $EIR_FPLR * $EIR_FT * $CAP_FT;
}

sub CAP_FTm {
   my ($chws,$chwr,$cws,$cwr) = @_;
   my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k) = (25.52905319,-0.355506103,-0.000156991,0.219511762,-0.002053336,-0.249516044,1.68086E-05,-0.560489951,0.002116063,0.004411357,0.003581958);
   $a+$b*$chws+$c*$chws**2+$d*$cwr+$e*$cwr**2+$f*$chwr+$g*$chwr**2+$h*$cws+$i*$cws**2+$j*$chws*$cwr+$k*$chwr*$cws;
}

sub EIR_FTm {
   my ($chws,$chwr,$cws,$cwr) = @_;
   my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k) = (-250.7632813,9.146526388,-0.013106297,4.605143989,-0.003255954,-4.443594025,0.079299252,-0.40512046,0.018047904,-0.099828456,-0.045022093);
   $a+$b*$chws+$c*$chws**2+$d*$cwr+$e*$cwr**2+$f*$chwr+$g*$chwr**2+$h*$cws+$i*$cws**2+$j*$chws*$cwr+$k*$chwr*$cws;
}

sub ChillerkWm {
   my ($a,$b,$c,$d,$e,$f,$g) = (-11.58633522,0.350618409,-0.000859351,-10.28752541,24.81191931,-7.236270235,-0.204446258);
   my ($chws,$chwr,$cws,$cwr,$chwfl,$ratedkw,$ratedton) = @_;
   my $EIR_FT = EIR_FTm($chws,$chwr,$cws,$cwr);
   my $CAP_FT = CAP_FTm($chws,$chwr,$cws,$cwr);
   my $PLR = (($chwr-$chws)*$chwfl/24)/($ratedton*$CAP_FT);
   my $EIR_FPLR = $a+$b*$cwr+$c*$cwr**2+$d*$cwr*$PLR+$e*$PLR+$f*$PLR**2+$g*$PLR**3;

# return ($ratedkw * $EIR_FPLR * $EIR_FT * $CAP_FT,$CAP_FT,$EIR_FT,$EIR_FPLR);  # use this line to trouble shoot equations

   $ratedkw * $EIR_FPLR * $EIR_FT * $CAP_FT;
}



# This following subroutines are for the cooling tower simulation using the DOE-2 formulas to mathematically model tower kW usage
# FRA and FRB are internal variables
# Qavail returns the ratio (to AHRI rated) of capacity at the operating temps, 100% rated flow and full fan speed.
# the towerkW calc uses a ratio of the actual Q to the Qavail.  If greater than 1, you need to have an error check to
# make sure it doesn't use it, since the cooling tower likely won't perform at those input conditions.
# Qrated is in tons


sub FRA {
  my %FRA;
  @FRA{'a','b','c','d','e','f'} =  (-2.22888899, 0.16679543, -0.01410247, 0.03222333, 0.18560214, 0.24251871);
  my ($tr,$ta) = @_;
  my ($a,$b,$c,$d,$e,$f) = @FRA{'a','b','c','d','e','f'};
  (-$d-$f*$tr+sqrt(($d+$f*$tr)**2-4*$e*($a+$b*$tr+$c*$tr**2-$ta)))/(2*$e);
}

sub FRB {
  my %FRB;
  @FRB{'a','b','c','d','e','f'} =  (0.60531402, -0.03554536, 0.00804083, -0.02860259, 0.00024972, 0.00490857);
  my ($tr,$ta,$wb) = @_;
  my ($a,$b,$c,$d,$e,$f) = @FRB{'a','b','c','d','e','f'};
  $FRA = FRA($tr,$ta);
  $a+$b*$FRA+$c*$FRA**2+$d*$wb+$e*$wb**2+$f*$FRA*$wb;
}

sub Qavail {
  my ($cws,$cwr,$wb,$Qrated) = @_;
  my ($tr, $ta) = (($cwr-$cws), ($cws-$wb));
  $FRB = FRB($tr,$ta,$wb);
  $Qrated*$FRB*($tr/10);
}

sub TowerkW {
    # This is the main function to use
    # inputs: ($cws,$cwr,$wb,$gpm,$Qrated,$hp) = Cond Water Supply/Ret in deg F, wetbulb in deg F, actual/estimated flow in GPM
    #         $Qrated is rated tonnage of tower at 85/95/78/rated flow - AHRI conditions.  $hp is brake horsepower of fan motor at full speed
    # The correlation coefficients are different for every tower, but you can calibrate the function if you have empricial basline data
    # and adjust the rated Q value until the actual kW matches the modeled.  Then use that value for predicting future operation.
  my %TF;
  my %TFlow;
  @TF{'a','b','c','d'} = (0.33162901, -0.88567609, 0.60556507, 0.9484823);
  @TFlow{'a','b','c','d'} = (0.00077628, 0.653702, -1.65544702, 2.00508264);

  my ($a,$b,$c,$d) = @TF{'a','b','c','d'};
  my ($cws,$cwr,$wb,$gpm,$Qrated,$hp) = @_;
  my $Q = ($cwr-$cws)*$gpm*8.33*60/1000;
  my ($PLR) = $Q/&Qavail($cws,$cwr,$wb,$Qrated);
  if ($PLR < 0.4){
    ($a,$b,$c,$d) = @TFlow{'a','b','c','d'};
  }
  my ($TFPL) = $a + $b*$PLR + $c*$PLR**2 + $d*$PLR**3;
  $TFPL*$hp*.746;
}

sub TowerkWpct { # work in progress
# rated Q for the the tower is 1.00
# flow is a percent of AHRI conditions rated flow
# power as a % of motor hp
# allows one to use this for various situations and help select the best tower for all conditions
# not just design AHRI conditions
  my %TF;
  my %TFlow;

  @TF{'a','b','c','d'} = (0.33162901, -0.88567609, 0.60556507, 0.9484823);
  # TF coefficients are the default ones used by DOE-2, but below 30% Part Load Ratio (PLR)
  # the polynomial begins to go up, crossing the y-axis at 0.33.  Using the same points created from 40% to 100%, I found
  # new polynomial coefficients that also go through (0,0), representing 0 load and 0 fan speed
  # these may or may not be that great, in fact they likely over-estimate at very low flows and PLR's, since
  # the tower becomes more and more similar to a natural draft tower.  All towers have some minimal
  # cooling capacity just from this natural draft (no fan running) and the movement of the water cascading
  # down through the fill.  Other potential issues occur at low PLR's such as dry spots in the fill, larger droplet sizes
  # and multitude of other theoretical items.
  @TFlow{'a','b','c','d'} = (0.00077628, 0.653702, -1.65544702, 2.00508264);

  my ($a,$b,$c,$d) = @TF{'a','b','c','d'};
  my ($wb,$approach,$range,$flowpct) = @_;
  my ($cws,$cwr) = ($wb+$approach,$wb+$approach+$range) ;
  my $Q = ($cwr-$cws)*$flowpct/10;
  my ($PLR) = $Q/&Qavail($cws,$cwr,$wb,1);
  if ($PLR < 0.4){
    ($a,$b,$c,$d) = @TFlow{'a','b','c','d'};
  }
  $a + $b*$PLR + $c*$PLR**2 + $d*$PLR**3;

}

# Custom parsing tools
# <FILEIN> = @FILE
# open $FH, ">file.txt"
# TrendIntervalPrint($FH,TrendIntervalParse(60,@FILE))
sub TDDRparse {
   my ($i, $rate, $pointorder, $date, $time, $value, @line, @lastline,$start,$end,$indextime,$pointqty,%indexkeys,$reportrate,$roundedexceltime);
    $start = -1;
    $end = 0;
    $rate = shift;
    $pointorder = shift;  # use a local filename with columns in first row, extra point names will be added to end, missing will be blank columns
    print STDOUT "default rate = $rate minute interval\n";
   $basetime = &exceldatevalue(0,0,0,1,1,(localtime)[5]+1900-4);
   $POINT[0] = "datestamp";
   for (@_) {
    $reportrate = $rate;
    chomp;
    s/;/,/g;  # replace semicolons with commas
    s/\"//g; # remove quotes
    if (/^Point Name:/){
       $POINT = (split /,/, $_)[1];
       next;
     }
    next unless (/^\d/);
    ($date,$time,$value) = split /,/, $_;
     $pointnames{$POINT} = 1;
     $exceldate = exceldatevalue($date." ".$time); # create numerical value of timestamp
     $roundedexceltime = round(1440/$reportrate*$exceldate,0)/(1440/$reportrate);  # round time value to the closest interval
     $indextime = round(1440/$reportrate*($roundedexceltime - $basetime),0);  # convert rounded time value to integer (index) value
     next unless ($indextime>=0);
     ${$POINT}[$indextime]=$value;
     $datestamp[$indextime] = timeconvert(exceldatevalue($roundedexceltime));
     $indexkeys{$indextime}=1;
   }
   ($start,$end) = (sort keys %indexkeys)[0,-1]; # find the earilest and latest timestamps
   @pointnames = sort keys %pointnames;
   print STDOUT $start."\t".$end."\t".($#pointnames+1)."\n";
   ($start,$end,@pointnames);
}
sub DesigoCCparse {
   my ($i, $rate, $pointorder, @line, @lastline,$start,$end,$indextime,$pointqty,%indexkeys,$reportrate,$roundedexceltime);
    $start = -1;
    $end = 0;
    $rate = shift;
    $pointorder = shift;  # use a local filename with columns in first row, extra point names will be added to end, missing will be blank columns
    print STDOUT "default rate = $rate minute interval\n";
   $basetime = &exceldatevalue(0,0,0,1,1,(localtime)[5]+1900-4);
   $POINT[0] = "datestamp";
   for (@_) {
    $reportrate = $rate;
    chomp;
    s/;/,/g;  # replace semicolons with commas
    s/^\"(.*)\"$/$1/; # if its been excelized take out leading and trailing quotes
    ($datetime,$POINT,$value) = split /,/, $_;
     # $displaynamepoint = (split /\./, $POINT)[-2];
     # $POINT =~ s/^.+\.Points\.(.+)\.Present Value$/$1/; # remove the ".Present Value" suffix and anything before the last "."
     $pointnames{$POINT} = 1;
     $exceldate = exceldatevalue($datetime); # create numerical value of timestamp
     $roundedexceltime = round(1440/$reportrate*$exceldate,0)/(1440/$reportrate);  # round time value to the closest interval
     $indextime = round(1440/$reportrate*($roundedexceltime - $basetime),0);  # convert rounded time value to integer (index) value
     next unless ($indextime>=0);
     ${$POINT}[$indextime]=$value;
     $datestamp[$indextime] = timeconvert(exceldatevalue($roundedexceltime));
     $indexkeys{$indextime}=1;
   }
   ($start,$end) = (sort keys %indexkeys)[0,-1]; # find the earilest and latest timestamps
   @pointnames = sort keys %pointnames;
   print STDOUT $start."\t".$end."\t".($#pointnames+1)."\n";
   ($start,$end,@pointnames);
}

sub combine_point_lists{
 # allows seamless grouping of old points from reports, with updated groupings.  Original group order is maintained, while new points are added at the end
 my ($original_list_file,@new_point_list) = @_;
 my ($n, $o, @original_pointlist, @return_point_list);
open POINTLIST, $original_list_file or return @new_point_list;
 <POINTLIST>;
 chomp;
 close POINTLIST;
 if($original_list_file =~ /\.csv$/i)  {@original_pointlist = split /,/}
 else { @original_pointlist = split /\t/}
 @return_point_list = @original_pointlist;
 o: for $o (@original_pointlist) {
  for $n (@new_point_list) {
   next o if ($n eq $o);
    push @return_point_list,($n);
  }
 }
}

sub TrendIntervalParse {
    my ($i, $rate, $pointorder, @line, @lastline,$start,$end,$indextime,$pointqty,%indexkeys,$reportrate,$roundedexceltime,$num,$units);
    $start = -1;
    $end = 0;
    $rate = shift;
    $pointorder = shift;  # 
    print STDOUT "default rate = $rate minute interval\nPoint order var: $pointorder\n";
    $basetime = &exceldatevalue(0,0,0,1,1,(localtime)[5]+1900-6);
    $POINT[0] = "datestamp";
    for (@_) {
        $reportrate = $rate;
        chomp;
        $_ =~ s/^\"(.*)\"$/$1/; # take out leading and trailing quotes
        if (/^Point_(\d+)/) {
            $num = $1;
            @line = split /\",\"/, $_;
            # $line[1] =~ s/https.+http...(.+)__;.+/$1/;
            $POINT[$num]=$line[1];
            ${$POINT[$num]}[0] = $line[1];
            $pointqty = $1;
            $pointnames{$line[1]} = 1;
 #           print STDOUT $$POINT[$1][0]."\n";
        }
        if (/^Time Interval:.+(\d+).([a-z]+)/i){
         $units = lc $2;
         @mult{'second','seconds','minute','minutes','hour','hours','day','days'} = (1,1,60,60,3600,3600,86400,86400);
         $reportrate = $1*$mult{$units}/60;
        }
        if (/^\d+/) {
            s/ON/1/g;
            s/OFF/0/g;
            s/OPEN/1/g;
            s/CLOSED/0/g;
            s/START/1/g;
            s/STOP/0/g;
            s/No Data//g;
            s/Data Loss//g;
            @line = split /\",\"/, $_;
            $exceldate = exceldatevalue($line[0].' '.$line[1]);
            $roundedexceltime = round(1440/$reportrate*$exceldate,0)/(1440/$reportrate);
            $indextime = round(1440/$reportrate*($roundedexceltime - $basetime),0);
             next if ($indextime < 0);
            # $start = $indextime if ($start < 0);
            for $i (2..$#line) {
                if ($line[$i] =~ /TIME/) { 
                    $line[$i] = $lastline[$i]; # Use previous value for BACnet clock issues
                }
                ${$POINT[$i-1]}[$indextime] = $line[$i] if ($line[$i] ne '');
            }
            $datestamp[$indextime] = timeconvert(exceldatevalue($roundedexceltime));
            $indexkeys{$indextime}=1;
            @lastline = @line;
        }
        # $end = $indextime;
    }
    ($start,$end) = (sort keys %indexkeys)[0,-1]; # find the earilest and latest timestamps
    if ($pointorder =~ /alpha/i) {
      @pointnames = sort keys %pointnames;
      $pointorder = "alphabetical Point Names";
      }
    else {
      @pointnames = @POINT[1..$#POINT];
      $pointorder = "Point Name order as found in last Interval Report"
    }
    print STDOUT $start."\t".$end."\t".($#pointnames+1)." total points. \n ".$pointorder."\n";
    ($start,$end,@pointnames);
}

sub TrendIntervalPrint {
    # call as TrendIntervalPrint($FH,)
    my ($fh,$start,$end,@pointnames) = @_;
    print $fh "timestamp";
    for $name (@pointnames){
        print $fh "\t",$name;
    }
    print $fh "\n";
        for $j ($start..$end){
            print $fh $datestamp[$j],"\t";
            for $name (@pointnames){
            print $fh ${$name}[$j],"\t";
        }   
        print $fh "\n";
    }
}

sub TIR_Point_index {
    my (@points) = ();
    # @points[0,1] = ("date","time");
        for (@_) {
            #  =~ s/^\"(.*)\"$/$1/; # take out leading and trailing quotes
            # @line = split /\",\"/, $_;
            if (/^\"Point_(\d+)/) {
                $points[$1-1] = (split /\",\"/)[1];
                next;
            }
            last if (/^\"Time/);
        }
    @points;
}

sub combine_files {
    # call as: &combine_files($searchterm,$outputfile,@files)
    my ($i,$p,$edv,$indextime,$basetime);
    my (@searchedfile,@all,@points,@file,@allpoints,@record,@index);
    my (%allpoints,%index);
    my ($searchterm,$outputfile,@files) = @_;
    @searchedfile =  grep (/$searchterm/i, @files);
    open (REWRITE, ">$outputfile") or die "can't rewrite the file, $outputfile, $!";
    
    for $file (@searchedfile){
          open (READ, $file) or print "can't open file ".$file."\n";
          while (<READ>) {
                s/ON/1/g;
                s/OFF/0/g;
                s/OPEN/1/g;
                s/CLOSED/0/g;
                s/START/1/g;
                s/STOP/0/g;
                s/ENABLE/1/g;
                s/DISABLE/0/g;
                s/TRUE/1/g;
                s/FALSE/0/g;
                s/No Data//g;
                s/Data Loss//g;

          print REWRITE $_;
          }
          close READ;
        }
     close REWRITE;
}


sub combine_OPC {
    # call as combine_OPC($searchterm,$startyear,$endyear,$startmonth,$endmonth,$mdy,$delimiter)

}


sub combine_files_grep {
    my ($i,$p,$edv,$indextime,$basetime);
    my (@searchedfile,@all,@points,@file,@allpoints,@record,@index);
    my (%allpoints,%index);
    my ($start,$rate,$searchterm,$outputfile,@files) = @_;
    # print STDOUT @files;
    $basetime = &exceldatevalue($start);
    @searchedfile =  grep (/$searchterm/i, @files);
    for $i (0..$#searchedfile) {
        open(FILE, $searchedfile[$i]) or print "cant open file $searchedfile[$i], $!";  # open each file matching search criteria
        @file = <FILE>;
        close FILE;
        # print STDOUT "opened: $searchedfile[$i], $#file lines\n";
        @_ = @file;
        for (@_) {
            if ($_ =~ /^\"\d+/) {  # look for meat of the file
                chomp;
                s/^\"(.*)\"$/$1/;  # take out leading and last quotes
                s/ON/1/g;
                s/OFF/0/g;
                s/OPEN/1/g;
                s/CLOSED/0/g;
                s/START/1/g;
                s/STOP/0/g;
                s/ENABLE/1/g;
                s/DISABLE/0/g;
                s/No Data//g;
                s/Data Loss//g;
                @record = (split /\",\"/);
                $edv = &exceldatevalue($record[0].' '.$record[1]);
                $indextime = round(1440/$rate*($edv-$basetime),0);
                next if ($indextime<0);
                $index[$indextime] = $edv;
                for $p (0..$#points) {    
                    ${$points[$p]}[$indextime] = $record[$p+2] if ($record[$p+2] ne '');
                }
                $lastline = shift @file;
                next;
            }
            if (/\"Key/) {
                @points = TIR_Point_index(@file[1..254]);
                if ($#points > -1) { @allpoints{@points} = @points;}
                $lastline = shift @file;
            }
            else {
                $lastline = shift @file;
            }
        }
    }
    open (REWRITE, ">",$outputfile) or die "cant write the file, $outputfile, $!";
    @allpoints = sort keys %allpoints;
        print REWRITE "date/time,";
    for $p (@allpoints) {
        print REWRITE $p,"," if $p;
    }
    print REWRITE "\n";
    for $i (0..$#index) {
        print REWRITE timeconvert(&exceldatevalue($basetime+$i/1440*$rate)),",";
        for $p (@allpoints) {
            print REWRITE ${$p}[$i],"," if $p;
        }
        print REWRITE "\n";
    }
}

sub TDRparse {
    my ($i,@keys,@values,@line);
    for (@_) {
        s/^\"(.*)\"$/$1/;  # take out leading and last quotes
        if (/../) {
            ($keys[$i],$values[$i]) = (split /\",\"/);
            $values{$keys[$i]} = $values[$i];
            $i++;
        }
     for $i (0..$#keys){
        
     }
        
    }
    
}


sub space2tab {
  while (@_){
  chomp;
    s/\s\s+/\t/g;
    $_ .= "\n";
  }
  @_;
}

sub space2csv {
  while (@_){
  chomp;
    s/\s\s+/,/g;
    $_ .= "\n";
  }
  @_;
}


# the following converts a string into a "safe" string that can be used
# in a URL or other uses where specific non-alphanumeric symbols are no-no's
sub asciisafe {
my %asciisafe = ("\ ","\%20","\!","\%21","\"","\%22","\#","\%23","\$","\%24","\%","\%25","\&","\%26","\'","\%27","\(","\%28","\)","\%29",
"\*","\%2A","\+","\%2B","\,","\%2C","\-","\%2D","\.","\%2E","\/","\%2F","\:","\%3A","\;","\%3B","\<","\%3C","\=","\%3D","\>","\%3E","\?","\%3F",
"\@","\%40","\[","\%5B","\\","\%5C","\]","\%5D","\^","\%5E","\_","\%5F","\`","\%60","\{","\%7B","\|","\%7C","\}","\%7D","\~","\%7E","\€","\%80",
"\‚","\%82","\ƒ","\%83","\„","\%84","\…","\%85","\†","\%86","\‡","\%87","\ˆ","\%88","\‰","\%89","\Š","\%8A","\‹","\%8B","\Œ","\%8C","\Ž","\%8E",
"\‘","\%91","\’","\%92","\“","\%93","\”","\%94","\•","\%95","\–","\%96","\—","\%97","\˜","\%98","\™","\%99","\š","\%9A","\›","\%9B","\œ","\%9C",
"\ž","\%9E","\Ÿ","\%9F","\¡","\%A1","\¢","\%A2","\£","\%A3","\¥","\%A5","\|","\%A6","\§","\%A7","\¨","\%A8","\©","\%A9","\ª","\%AA","\«","\%AB",
"\¬","\%AC","\¯","\%AD","\®","\%AE","\¯","\%AF","\°","\%B0","\±","\%B1");
my $out = '';
 for (split //,$_[0]){
  $out .= ($asciisafe{$_} or $_);
 }
$out;
}


# to time your scripts, call ($sec,$usec) = starttiming();
# then later $totaltime = endtiming($sec,$usec);
# units are in seconds and microseconds


sub starttiming {
    use Time::HiRes qw/ gettimeofday /;
    gettimeofday();
}

sub endtiming {
   my ($end,$endmicro) = gettimeofday();
   ($end-$_[0])+($endmicro-$_[1])/1000000;
}

sub siteinfoparse {
    my (@totalitems,@backgroundcolor,@graphic,@backgroundfile,@x,@y,@MonitorPt,@CommandPt,@CmdDisplayNamePt,@Target,@GraphicName,@totalissueswarnings);
    my ($i,$graphicnum,$item,$line);
    
    open(OUT, ">",$_[1]) or die "Cannot open output file:", $_[1],$!;
    ($graphicnum,$i) = (0,0);
    open(SITEINFO, $_[0]) or die "Cannot open input file:", $_[0],$!;;
    while (<SITEINFO>) {
	if (/    Trended Points:/) {
	    unless (/      Total Trend Defs:/){
		<SITEINFO>;
		if (/^      (\S+)/) {
		    $ptname = $1;
		}
		if (/^        by (.*\s)?(.+)/){
		    $ptname .= '.TREND'.$2;
		}
		if (/rollover after (\d+)/){
		    ${$ptname}{'days'} = $1;
		}		
		if (/sample interval=(\d+)/){
		    ${$ptname}{'sampleinterval'} = $1;
		}
		if (/Panel Buffer Size=(\d+)/){
		    ${$ptname}{'panelsamples'} = $1;
		}
		if (/Num Data Records=(\d+)/){
		    ${$ptname}{'datarecords'} = $1;
		}
		if (/rollover after (\d+)/){
		    ${$ptname}{'days'} = $1;
		}
		if (/Enable PC Collection=(.+)/){
		    ${$ptname}{'collectionenabled'} = $1;
		}
		if (/Last Known Collection=(.+)/){
		    ${$ptname}{'lastcollect'} = $1;
		}
		if (/Time range of samples=(.+)  -  (.+)/){
		    ${$ptname}{'rangeofsampleslow'} = $1;
		    ${$ptname}{'rangeofsampleshigh'} = $2;		    
		}
		
	    }
	}
	if (/^Graphic System Name and User Name: (.+)$/){
	    $graphicnum++;
	    $graphic[$graphicnum] = $1;
        $totalissueswarnings[$graphicnum]=0;
	    #$block = 0;
	    #$assocpoint = 0;
	    #$link = 0;
	    $item = 0;
	    next;
	}
    if (/ISSUE:|WARNING:/) {
        $totalissueswarnings[$graphicnum]++;
        next;
    }
	if (/^Background color.*(\d+,\d+,\d+)/){
	    $backgroundcolor[$graphicnum] = $1;
	    next;
	}	
	if (/^\d Background*:\s+(.*)/){
	    $backgroundfile[$graphicnum] = $1;
	    next;
	}
	if (/^(\d+) controls/){
	    $totalitems[$graphicnum] = $1;
	    next;
	}	
	if (/(.*): \{x=(\d+), y=(\d+)\}/){
	    $item++;
	    $item[$graphicnum][$item] = $1;
	    ($x[$graphicnum][$item],$y[$graphicnum][$item]) = ($2,$3);
	    next;
	}
	if (/MonitorPt=\"(.*)\"/){
	    $MonitorPt[$graphicnum][$item] = $1;
	    next;
	}
	if (/CommandPt=\"(.*)\"/){
	    $CommandPt[$graphicnum][$item] = $1;
	    next;
	}
	if (/CmdDisplayName \"(.*)\"/){
	    $CmdDisplayNamePt[$graphicnum][$item] = $1;
	    next;
	}
	if (/Graphic Name=\"(.*)\"/){
	    $GraphicName[$graphicnum][$item] = $1;
	    next;
	}	
	if (/Target=\"(.*)\"/){
	    $Target[$graphicnum][$item] = $1;
	    next;
	}
    }
    close SITEINFO;
    for $i (1..$graphicnum) {
	# $line = "$i"."\t"."$graphic[$i]"."\t"."$backgroundcolor[$i]"."\t"."$backgroundfile[$i]"."\t"."$totalitems[$i]"."\n";
    $line = "$i"."\t"."$graphic[$i]"."\t"."$totalitems[$i]"."\t".$totalissueswarnings[$i]."\n";
	print OUT $line;
	$item = 1;
#	while ($x[$i][$item]){
#	    $line = join "\t", $item[$i][$item],$x[$i][$item],$y[$i][$item],$MonitorPt[$i][$item],$CommandPt[$i][$item],$CmdDisplayNamePt[$i][$item],$GraphicName[$i][$item],$Target[$i][$item];
#	    print OUT $line,"\n";
#	    $item++;
#	}
   }
}

#  Steam and liquid water properties calculations from the IAPWS 1997 formulations
#  http://www.iapws.org/relguide/IF97-Rev.pdf
#  subroutines cover regions 1,2(a)(b)&(c), 4, and 5
#  Inputs are P and T, but also allow P,h or P,s input for any region, and x along the saturation curve (Region 4).
#  units must be absolute SI (MPa, K, kJ/kg, and kJ/kg-K) for P, T, h and s.
#  Other subs that use these formulations may have conversions of the inputs and outputs, but the formulation calcs must use the above input units to work.
#  The saturation curve needs 2 known input s P or T as a value (the other as "sat"), then a value for h, s, or x
#  h and s inputs have been added but only for Region 1 and 2 (and 5 up to about 1300K), x cannot be in between 0 and 1.
#
#  Part of the subroutine is determining the proper region from the input data (no need to choose the right region when programming)
#  Region 1, Liquid: pressures 611Pa to 100MPa.  Temps 273.15K to 623K
#  Region 4, Saturation Line: Temp 273.15K (611Pa) to 647.096K (22.06MPa, critical point)
#  Region 2, superheated vapor:
#     sub-region 2a: Pressure: 0 to 4MPa (565 psig), Temperature: T(sat) to 1023.15K (1382F), 99% of what we deal with in engineering, and remains reasonable up to ~1600K (2400F)
#     sub-region 2b: Pressure: 4MPa to 100MPa, Temperature: where Entropy, s(p,T) >= 5.85kJ/kgK  to 1073.15K, and remains reasonable up to ~1600K
#			method to calculate T from P,s is part of sub
#			method to calculate s from P,h is part of sub
#     sub-region 2c: Pressure: ~6.5MPa (saturated) to 100MPa, where Entropy, s <= 5.85kJ/kgK  to 1073.15K
#  Region 5, highly superheated vapor (higher temps up to 2273K / 3600F), pressure to 50 MPa
#     if P and T are known, works well in the full range 1073K to 2273K, 0-50MPa
#     There's no backwards calc for Ph, Ps, or hs inputs so the Region 2 functions are used to generate P and T
#     If P is known, the Ps and Ph Region 2 calcs work OK up to around 1600K (2400F)
#     if only using h,s then temperatures up to 1200K (1700F) are reasonable, depending on P
#  Region 3, super-critical: areas above the critical pressure from T = 623K to s ~ 5.1 to 5.3 kJ/kgK
#     This region is NOT defined in the sub-routines, but it is rarely used in any process.  Anything at the pressures of this region (>2000psi)
#     generally use higher temperatures, which bump it into the 2b/2c regions.  The physical nature of water in this region is state
#     in between a liquid and gas; "compressible liquid" as some call it. Not very usable in any fluid machinery


sub satsteam_IAPWS97_R4_T {

    # use to get sat pressure from temperature input (K). Returns both saturation pressure and Temperature ($Ps,$T)
    # good up to the critical point(273.15K to 647.096K, 611Pa to 22.06MPa)
    # takes 0.005ms per iteration (2.4GHZ i5 520M - Arrandale)
    my ($T) = @_;
    my ($A,$B,$C,$D,$E,$F,$G,$v,$Ps);
    my @n =(0,1.1670521452767E+03,-7.2421316703206E+05,-1.7073846940092E+01,1.2020824702470E+04,-3.2325550322333E+06,1.4915108613530E+01,
	 -4.8232657361591E+03,4.0511340542057E+05,-2.3855557567849E-01,6.5017534844798E+02);
    $v = $T+$n[9]/($T-$n[10]);
    $A = $v**2+$n[1]*$v+$n[2];
    $B = $n[3]*$v**2+$n[4]*$v+$n[5];
    $C = $n[6]*$v**2+$n[7]*$v+$n[8];
    $Ps = (2*$C/(-$B+($B**2-4*$A*$C)**0.5))**4;
    ($Ps,$T);
}


sub satsteam_IAPWS97_R4_P {
    # use to get sat Temp (K) from Pressure input (MPa). Returns both Pressure and saturation temp ($P,$Ts)
    # good up to the critical point(273.15K to 647.096K, 0.000611MPa to 22.06MPa)
    # takes 0.005ms per iteration (2.4GHZ i5)
    my ($P) = @_;
    my ($A,$B,$C,$D,$E,$F,$G,$Ts);
    my @n =(0,1.1670521452767E+03,-7.2421316703206E+05,-1.7073846940092E+01,1.2020824702470E+04,-3.2325550322333E+06,1.4915108613530E+01,
	 -4.8232657361591E+03,4.0511340542057E+05,-2.3855557567849E-01,6.5017534844798E+02);
    $B = ($P)**.25;
    $E = $B**2+$n[3]*$B+$n[6];
    $F = $n[1]*$B**2+$n[4]*$B+$n[7];
    $G = $n[2]*$B**2+$n[5]*$B+$n[8];
    $D = (2*$G)/(-$F-($F**2-4*$E*$G)**0.5);
    $Ts = ($n[10]+$D-(($n[10]+$D)**2-4*($n[9]+$n[10]*$D))**0.5)/2;   
    ($P,$Ts);
}

sub steamproperties_IAPWS97_R1_PT {
    # Region 1, liquid phase
    # inputs can both be numbers saturated liquid properties (only need press or temp, other value is "sat")
    # units must be absolute SI (MPa,K)
    # takes about 0.2ms per iteration (2.4GHz i5)
    # satsteam_IAPWS97_R4_(P|T) calls only take an additional 0.01ms

    my ($P,$T) = @_;
    return (@_) if ($P < .00000611213 or $T < 273.15);
    
    if ($T =~ /s/) {
	($P,$T) = satsteam_IAPWS97_R4_P($P);
    }
    if ($P =~ /s/) {
	($P,$T) = satsteam_IAPWS97_R4_T($T);
    }
    
    my @I = (0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3,4,4,4,5,8,8,21,23,29,30,31,32);
    my @J = (-2,-1,0,1,2,3,4,5,-9,-7,-1,0,1,3,-3,0,1,3,17,-4,0,6,-5,-2,10,-8,-11,-6,-29,-31,-38,-39,-40,-41);
    my @n = (1.46329712131670E-01,-8.45481871691140E-01,-3.75636036720400E+00,3.38551691683850E+00,-9.57919633878720E-01,
	     1.57720385132280E-01,-1.66164171995010E-02,8.12146299835680E-04,2.83190801238040E-04,-6.07063015658740E-04,
	     -1.89900682184190E-02,-3.25297487705050E-02,-2.18417171754140E-02,-5.28383579699300E-05,-4.71843210732670E-04,
	     -3.00017807930260E-04,4.76613939069870E-05,-4.41418453308460E-06,-7.26949962975940E-16,-3.16796448450540E-05,
	     -2.82707979853120E-06,-8.52051281201030E-10,-2.24252819080000E-06,-6.51712228956010E-07,-1.43417299379240E-13,
	     -4.05169968601170E-07,-1.27343017416410E-09,-1.74248712306340E-10,-6.87621312955310E-19,1.44783078285210E-20,
	     2.63357816627950E-23,-1.19476226400710E-23,1.82280945814040E-24,-9.35370872924580E-26);
    my ($hf,$sf,$uf,$pf,$vf,$R,$RT,$pi,$tau,$g,$gp,$gpp,$gt,$gtt,$gpt,$i,$Cp,$Cv,$w) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
    $pi = $P/16.53;
    $tau = 1386/$T;
    $R = 0.461526;
    $RT = $R*$T;
    for $i (0..33){
	$g += $n[$i]*(7.1-$pi)**$I[$i]*($tau-1.222)**$J[$i];
	$gp += -$n[$i]*$I[$i]*(7.1-$pi)**($I[$i]-1)*($tau-1.222)**$J[$i];
	$gpp += $n[$i]*$I[$i]*($I[$i]-1)*(7.1-$pi)**($I[$i]-2)*($tau-1.222)**$J[$i];
	$gt += $n[$i]*$J[$i]*(7.1-$pi)**$I[$i]*($tau-1.222)**($J[$i]-1);
	$gtt += $n[$i]*$J[$i]*($J[$i]-1)*(7.1-$pi)**$I[$i]*($tau-1.222)**($J[$i]-2);
	$gpt += -$n[$i]*$I[$i]*$J[$i]*(7.1-$pi)**($I[$i]-1)*($tau-1.222)**($J[$i]-1);
    }
    
    $hf = $RT*$tau*$gt;
    $sf = $R*($tau*$gt-$g);
    $uf = $RT*($tau*$gt-$pi*$gp);
    $pf = $P/($RT*($pi*$gp))*1000;
    $vf = 1/$pf if ($pf>0);
    $Cp = -$tau**2*$R*($gtt); # isobaric heat capacity Cp
    $Cv = $R*((-$tau**2*$gtt)+(($gp-$tau*$pi*$gpt)**2/$gpp)); # isochoric heat capacity Cv
#    $w = sqrt(1000*$RT*($Cp/$Cv));  # speed of sound, w   
    $w = sqrt(1000*$RT*($gp**2/(($gp-$tau*$gpt)**2/($gtt*$tau**2)-$gpp)));  # speed of sound, w
    
    ($P,$T,$hf,$sf,$uf,$pf,$vf,$Cp,$Cv,$w)
}


sub steamproperties_IAPWS97_R1_Ph {
    # Region 1, liquid phase
    # units must be absolute SI (MPa,kJ/kg)
    my ($P,$h) = @_;
    my (@I,@J,@n,$i);
    my ($T,$eta,$pi) = (0,$h/2500,$P);

    @I = (0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,3,3,4,5,6);
    @J = (0,1,2,6,22,32,0,1,2,3,4,10,32,10,32,10,32,32,32,32);
    @n = (-2.3872489924521E+02,4.0421188637945E+02,1.1349746881718E+02,-5.8457616048039E+00,-1.5285482413140E-04,-1.0866707695377E-06,
	  -1.3391744872602E+01,4.3211039183559E+01,-5.4010067170506E+01,3.0535892203916E+01,-6.5964749423638E+00,9.3965400878363E-03,
	  1.1573647505340E-07,-2.5858641282073E-05,-4.0644363084799E-09,6.6456186191635E-08,8.0670734103027E-11,-9.3477771213947E-13,
	  5.8265442020601E-15,-1.5020185953503E-17);
    for $i (0..$#I) {
	$T += $n[$i]*$pi**$I[$i]*($eta+1)**$J[$i];
    }
steamproperties_IAPWS97_R1_PT($P,$T);
}


sub steamproperties_IAPWS97_R1_Ps {
    # Region 1, liquid phase
    # units must be absolute SI (MPa,kJ/kg-K)
    my ($P,$s) = @_;
    my (@I,@J,@n,$i);
    my ($T,$sigma,$pi) = (0,$s,$P);
    @I = (0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,4);
    @J = (0,1,2,3,11,31,0,1,2,3,12,31,0,1,2,9,31,10,32,32);
    @n = (1.74782680583070E+02,3.48069308928730E+01,6.52925849784550E+00,3.30399817754890E-01,-1.92813829231960E-07,-2.49091972445730E-23,
      -2.61076364893320E-01,2.25929659815860E-01,-6.42564633952260E-02,7.88762892705260E-03,3.56721106073660E-10,1.73324969948950E-24,
      5.66089006548370E-04,-3.26354831397170E-04,4.47782866906320E-05,-5.13221569085070E-10,-4.25226570422070E-26,2.64004413606890E-13,
      7.81246004597230E-29,-3.07321999036680E-31);
    for $i (0..$#I) {
	$T += $n[$i]*$pi**$I[$i]*($sigma+2)**$J[$i];
    }
    steamproperties_IAPWS97_R1_PT($P,$T);
}
sub steamproperties_IAPWS97_R1_hs {
    # Region 1, liquid phase
    # units must be absolute SI (kJ/kg,kJ/kg-K)
    my ($h,$s) = @_;
    my (@I,@J,@n,$i);
    my ($pi,$eta,$sigma,$pstar) = (0,$h/3400,$s/7.6,100);
    @I = (0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,4,4,5);
    @J = (0,1,2,4,5,6,8,14,0,1,4,6,0,1,10,4,1,4,0);
    @n = (-6.91997014660582E-01,-1.83612548787560E+01,-9.28332409297335E+00,6.59639569909906E+01,-1.62060388912024E+01,4.50620017338667E+02,
	  8.54680678224170E+02,6.07523214001161E+03,3.26487682621856E+01,-2.69408844582931E+01,-3.19947848334300E+02,-9.28354307043320E+02,
	  3.03634537455249E+01,-6.50540422444146E+01,-4.30991316516130E+03,-7.47512324096068E+02,7.30000345529245E+02,1.14284032569021E+03,
	  -4.36407041874559E+02);
    for $i (0..$#I) {
	$pi += $n[$i]*($eta+.05)**$I[$i]*($sigma+.05)**$J[$i];
    }
    steamproperties_IAPWS97_R1_Ps($pi*$pstar, $s);
}


sub steamproperties_IAPWS97_R2_PT {
    # Region 2, gas phase, also covers Region 5 (super-duper heated steam)
    # units must be absolute SI (MPa,K)
    # checked and working
    # takes about 0.27ms per iteration (2.4GHz i5 processor)
    my ($P,$T) = @_;
    return '' if ($T < 273.15);
    return '' if ($P < 0);
    return steamproperties_IAPWS97_R5_PT($P,$T) if ($P <= 50 and $T >= 1073.15 and $T);
    
    if ($T eq 'sat') {
	($P,$T) = satsteam_IAPWS97_R4_P($P);
    }
    my @J0=(0,1,-5,-4,-3,-2,-1,2,3);
    my @n0=(-9.69276865002170E+00,1.00866559680180E+01,-5.60879112830200E-03,7.14527380814550E-02,-4.07104982239280E-01,1.42408191714440E+00,
	    -4.38395113194500E+00,-2.84086324607720E-01,2.12684637533070E-02);
    my @I=(1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,5,6,6,6,7,7,7,8,8,9,10,10,10,16,16,18,20,20,20,21,22,23,24,24,24);
    my @J=(0,1,2,3,6,1,2,4,7,36,0,1,3,6,35,1,2,3,7,3,16,35,0,11,25,8,36,13,4,10,14,29,50,57,20,35,48,21,53,39,26,40,58);
    my @n=(-1.77317424732130E-03,-1.78348622923580E-02,-4.59960136963650E-02,-5.75812590834320E-02,-5.03252787279300E-02,-3.30326416702030E-05,
	 -1.89489875163150E-04,-3.93927772433550E-03,-4.37972956505730E-02,-2.66745479140870E-05,2.04817376923090E-08,4.38706672844350E-07,
	 -3.22776772385700E-05,-1.50339245421480E-03,-4.06682535626490E-02,-7.88473095593670E-10,1.27907178522850E-08,4.82253727185070E-07,
	 2.29220763376610E-06,-1.67147664510610E-11,-2.11714723213550E-03,-2.38957419341040E+01,-5.90595643242700E-18,-1.26218088991010E-06,
	 -3.89468424357390E-02,1.12562113604590E-11,-8.23113408979980E+00,1.98097128020880E-08,1.04069652101740E-19,-1.02347470959290E-13,
	 -1.00181793795110E-09,-8.08829086469850E-11,1.06930318794090E-01,-3.36622505741710E-01,8.91858453554210E-25,3.06293168762320E-13,
	 -4.20024676982080E-06,-5.90560296856390E-26,3.78269476134570E-06,-1.27686089346810E-15,7.30876105950610E-29,5.54147153507780E-17,
	 -9.43697072412100E-07);
    my ($pi,$tau,$R,$h,$s,$u,$p,$v,$RT,$i,$Cp,$Cv,$w) = ($P,540/$T,0.461526,0,0,0,0,0,0,0,0,0,0,0,0,0);
    my ($g0,$g0p,$g0pp,$g0t,$g0tt,$g0pt) = (log($pi),1/$pi,-1/$pi**2,0,0,0);
    my ($gr,$grp,$grpp,$grt,$grtt,$grpt) = (0,0,0,0,0,0,0,0,0,0,0,0,0);
    $RT = $R*$T;
    for $i (0..$#J0){
	$g0 += $n0[$i]*($tau)**$J0[$i];
	$g0t += $n0[$i]*$J0[$i]*$tau**($J0[$i]-1);
	$g0tt += $n0[$i]*$J0[$i]*($J0[$i]-1)*$tau**($J0[$i]-2);
	$g0pt = 0;
    }
    for $i (0..$#I){
	$gr += $n[$i]*($pi)**($I[$i])*($tau-0.5)**$J[$i];
	$grp += $n[$i]*$I[$i]*($pi)**($I[$i]-1)*($tau-0.5)**$J[$i];
	$grpp += $n[$i]*$I[$i]*($I[$i]-1)*($pi**($I[$i]-2))*($tau-0.5)**$J[$i];
	$grt += $n[$i]*($pi)**($I[$i])*$J[$i]*($tau-0.5)**($J[$i]-1);
	$grtt += $n[$i]*($pi**$I[$i])*$J[$i]*($J[$i]-1)*($tau-0.5)**($J[$i]-2);
	$grpt += $n[$i]*$I[$i]*($pi)**($I[$i]-1)*$J[$i]*($tau-0.5)**($J[$i]-1);
    }
    $h = $RT*$tau*($g0t+$grt);
    $s = $R*($tau*($g0t+$grt)-($g0+$gr));
    $u = $RT*($tau*($g0t+$grt)-$pi*($g0p+$grp));
    $p = $P/($RT*($pi*($g0p+$grp)))*1000;
    $v = 1/$p;
    $Cp = -$tau**2*$R*($g0tt+$grtt); # isobaric heat capacity Cp
    $Cv = $R*(-$tau**2*($g0tt+$grtt)-((1+$pi*$grp-$tau*$pi*$grpt)**2/(1-$pi**2*$grpp))); # isochoric heat capacity Cv
    # $w = sqrt(1000*$RT*(1+2*$pi*$grp+$pi**2*$grp**2)/((1-$pi**2*$grpp)+((1+$pi*$grpt-$tau*$pi*$grpt)**2)/($tau**2*($g0tt+$grtt))));  # speed of sound, w
    $w = sqrt($Cp/$Cv*$RT*1000);
    ($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w);
}

sub steamproperties_IAPWS97_R5_PT {
    # Region 5, gas phase (super-duper-heated)
    # units must be absolute SI (MPa,K)
    # checked and working
    # takes about 0.05ms per iteration (2.4GHz i5 processor)
    my ($P,$T) = @_;
    my @J0=(0,1,-3,-2,-1,2);
    my @n0=(-13.179983674201,6.8540841634434,-0.024805148933466,0.36901534980333,-3.11613182139250,-0.32961626538917);

    my @I=(1,1,1,2,2,3);
    my @J=(1,2,3,3,9,7);
    my @n=(1.5736404855259E-03,9.0153761673944E-04,-5.0270077677648E-03,2.2440037409485E-06,-4.1163275453471E-06,3.7919454822955E-08);

    my ($pi,$tau,$R,$h,$s,$u,$p,$v,$RT,$i,$Cp,$Cv,$w) = ($P,1000/$T,0.461526,0,0,0,0,0,0,0,0,0,0,0,0,0);
    my ($g0,$g0p,$g0pp,$g0t,$g0tt,$g0pt) = (log($pi),1/$pi,-1/$pi**2,0,0,0);
    my ($gr,$grp,$grpp,$grt,$grtt,$grpt) = (0,0,0,0,0,0,0,0,0,0,0,0,0);
    $RT = $R*$T;
    for $i (0..$#J0){
	$g0 += $n0[$i]*($tau)**$J0[$i];
	$g0t += $n0[$i]*$J0[$i]*$tau**($J0[$i]-1);
	$g0tt += $n0[$i]*$J0[$i]*($J0[$i]-1)*$tau**($J0[$i]-2);
	$g0pt = 0;
    }
    for $i (0..$#I){
	$gr += $n[$i]*($pi)**($I[$i])*($tau)**$J[$i];
	$grp += $n[$i]*$I[$i]*($pi)**($I[$i]-1)*($tau)**$J[$i];
	$grpp += $n[$i]*$I[$i]*($I[$i]-1)*($pi)**($I[$i]-2)*($tau)**$J[$i];
	$grt += $n[$i]*($pi)**($I[$i])*$J[$i]*($tau)**($J[$i]-1);
	$grtt += $n[$i]*($pi)**($I[$i])*$J[$i]*($J[$i]-1)*($tau)**($J[$i]-2);
	$grpt += $n[$i]*$I[$i]*($pi)**($I[$i]-1)*$J[$i]*($tau)**($J[$i]-1);
    }
    $h = $RT*$tau*($g0t+$grt);
    $s = $R*($tau*($g0t+$grt)-($g0+$gr));
    $u = $RT*($tau*($g0t+$grt)-$pi*($g0p+$grp));
    $p = $P/($RT*($pi*($g0p+$grp)))*1000;
    $v = 1/$p;
    $Cp = -$tau**2*$R*($g0tt+$grtt); # isobaric heat capacity Cp
    $Cv = $R*(-$tau**2*($g0tt+$grtt)-((1+$pi*$grp-$tau*$pi*$grpt)**2/(1-$pi**2*$grpp))); # isochoric heat capacity Cv
    $w = sqrt($Cp/$Cv*$RT);  # speed of sound, w
    
    ($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w);
}

sub steamproperties_IAPWS97_R2_Ph {
    # Region 2, gas phase, pressure/enthalpy
    # this is broken into 3 subregions (a,b,&c), a is anything below 4MPa (~580psi), vast majority of usage
    # sub-region b is above 4MPa and Entropy (s) below 5.85kJ/kg-K, c is above 4MPa and s above 5.85
    # units must be absolute SI (MPa,kJ/kg)
    # this sub takes about 0.05ms per iteration (2.4GHz i5 processor)
    # the steamproperties_IAPWS97_R2_PT sub that it calls at the end takes about 0.27ms per iteration (2.4GHz i5 processor)
    my ($P,$h) = @_;
    my (@I,@J,@n,$T,$subregion,$i);
    my ($eta,$pi) = ($h/2000, $P/1);
    
    # subregion a
    if ($P<=4){
	# subregion a
	$subregion = "a";
	$T = 0;
	@I = (0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,4,4,4,5,5,5,6,6,7);
	@J = (0,1,2,3,7,20,0,1,2,3,7,9,11,18,44,0,2,7,36,38,40,42,44,24,44,12,32,44,32,36,42,34,44,28);
	@n = (1.08989523182880E+03,8.49516544955350E+02,-1.07817480918260E+02,3.31536548012630E+01,-7.42320167902480E+00,
	      1.17650487243560E+01,1.84457493557900E+00,-4.17927005496240E+00,6.24781969358120E+00,-1.73445631081140E+01,
	      -2.00581768620960E+02,2.71960654737960E+02,-4.55113182858180E+02,3.09196886047550E+03,2.52266403578720E+05,
	      -6.17074228683390E-03,-3.10780466295830E-01,1.16708730771070E+01,1.28127984040460E+08,-9.85549096232760E+08,
	      2.82245469730020E+09,-3.59489714107030E+09,1.72273499131970E+09,-1.35513342407750E+04,1.28487346646500E+07,
	      1.38657242832260E+00,2.35988325565140E+05,-1.31052365450540E+07,7.39998354747660E+03,-5.51966970300600E+05,
	      3.71540859962330E+06,1.91277292396600E+04,-4.15351648356340E+05,-6.24598551925070E+01);
	for $i (0..$#I) {
	    $T += $n[$i]*($pi)**$I[$i]*($eta-2.1)**$J[$i];
	}
	return steamproperties_IAPWS97_R2_PT($P,$T);
    }

    my ($n1,$n2,$n3,$n4,$n5) = (0.90584278514723E3,-0.67955786399241,0.12809002730136E-3,0.26526571908428E4,0.45257578905948E1);
    my ($pi2b2c,$eta2b2c) = ($pi,$eta);
    my $P2b2c = $pi2b2c*($n1+$n2*$eta2b2c+$n3*$eta2b2c**2);
    
    if ($P > 4 and $P < $P2b2c) {
	$subregion = "b";
	$T = 0;
        @I = (0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,4,4,5,5,5,6,7,7,9,9);
	@J = (0,1,2,12,18,24,28,40,0,2,6,12,18,24,28,40,2,8,18,40,1,2,12,24,2,12,18,24,28,40,18,24,40,28,2,28,1,40);
	@n =(1.48950410795160E+03,7.43077983140340E+02,-9.77083187978370E+01,2.47424647056740E+00,-6.32813200160260E-01,1.13859521296580E+00,
	-4.78118636486250E-01,8.52081234315440E-03,9.37471473779320E-01,3.35931186049160E+00,3.38093556014540E+00,1.68445396719040E-01,
	7.38757452366950E-01,-4.71287374361860E-01,1.50202731397070E-01,-2.17641142197500E-03,-2.18107553247610E-02,-1.08297844036770E-01,
	-4.63333246358120E-02,7.12803519595510E-05,1.10328317899990E-04,1.89552483879020E-04,3.08915411605370E-03,1.35555045549490E-03,
	2.86402374774560E-07,-1.07798573575120E-05,-7.64627124548140E-05,1.40523928183160E-05,-3.10838143314340E-05,-1.03027382121030E-06,
	2.82172816350400E-07,1.27049022719450E-06,7.38033534682920E-08,-1.10301392389090E-08,-8.14563652078330E-14,-2.51805456829620E-11,
	-1.75652339694070E-18,8.69341563441630E-15);
	for $i (0..$#I) {
	    $T += $n[$i]*($pi-2)**$I[$i]*($eta-2.6)**$J[$i];
	}
    }
    
    if ($P > 4 and $P >= $P2b2c) {
	$subregion = "c";
	$T = 0;
        @I = (-7,-7,-6,-6,-5,-5,-2,-2,-1,-1,0,0,1,1,2,6,6,6,6,6,6,6,6);
	@J = (0,4,0,2,0,2,0,1,0,2,0,1,4,8,4,0,1,4,10,12,16,20,22);
	@n =(-3.2368398555242E+12,7.3263350902181E+12,3.5825089945447E+11,-5.8340131851590E+11,-1.0783068217470E+10,2.0825544563171E+10,
	     6.1074783564516E+05,8.5977722535580E+05,-2.5745723604170E+04,3.1081088422714E+04,1.2082315865936E+03,4.8219755109255E+02,
	     3.7966001272486E+00,-1.0842984880077E+01,-4.5364172676660E-02,1.4559115658698E-13,1.1261597407230E-12,-1.7804982240686E-11,
	     1.2324579690832E-07,-1.1606921130984E-06,2.7846367088554E-05,-5.9270038474176E-04,1.2918582991878E-03);
	for $i (0..$#I) {
	    $T += $n[$i]*($pi+25)**$I[$i]*($eta-1.8)**$J[$i];
	}
    }

 steamproperties_IAPWS97_R2_PT($P,$T);
}

sub steamproperties_IAPWS97_R2_Ps {
    # Region 2, gas phase
    # also works somewhat into Region 5 below 1600K.
    # units must be absolute SI (MPa,KJ/kg-K)
    # this sub takes about 0.05ms per iteration (2.4GHz i5 processor)
    # the steamproperties_IAPWS97_R2_PT sub that it calls at the end takes about 0.27ms per iteration (2.4GHz i5 processor)
    my ($P,$s) = @_;
    my (@I,@J,@n,$T,$subregion,$i);
    my ($sa,$sb,$sc,$pi) = ($s/2, $s/0.7853, $s/2.9251, $P);
    
    # subregion a
    if ($P<=4){
	# subregion a
	$subregion = "a";
	$T = 0;
	@I = (-1.5,-1.5,-1.5,-1.5,-1.5,-1.5,-1.25,-1.25,-1.25,-1,-1,-1,-1,-1,-1,-0.75,-0.75,-0.5,-0.5,-0.5,-0.5,-0.25,-0.25,-0.25,-0.25,0.25,0.25,0.25,0.25,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.75,0.75,0.75,0.75,1,1,1.25,1.25,1.5,1.5);
	@J = (-24,-23,-19,-13,-11,-10,-19,-15,-6,-26,-21,-17,-16,-9,-8,-15,-14,-26,-13,-9,-7,-27,-25,-11,-6,1,4,8,11,0,1,5,6,10,14,16,0,4,9,17,7,18,3,15,5,18);
	@n = (-3.92359838619840E+05,5.15265738272700E+05,4.04824431610480E+04,-3.21937909239020E+02,9.69614242186940E+01,
	      -2.28678463717730E+01,-4.49429141243570E+05,-5.01183360201660E+03,3.56844635600150E-01,4.42353358481900E+04,
	      -1.36733888117080E+04,4.21632602078640E+05,2.25169258374750E+04,4.74421448656460E+02,-1.49311307976470E+02,
	      -1.97811263204520E+05,-2.35543994707600E+04,-1.90706163020760E+04,5.53756698831640E+04,3.82936914373630E+03,
	      -6.03918605805670E+02,1.93631026203310E+03,4.26606436986100E+03,-5.97806388727180E+03,-7.04014639268620E+02,
	      3.38367841075530E+02,2.08627866351870E+01,3.38341726561960E-02,-4.31244284148930E-05,1.66537913564120E+02,
	      -1.39862920558980E+02,-7.88495479998720E-01,7.21324117538720E-02,-5.97548393982830E-03,-1.21413589539040E-05,
	      2.32270967338710E-07,-1.05384635661940E+01,2.07189254965020E+00,-7.21931552604270E-02,2.07498870811200E-07,
	      -1.83406579113790E-02,2.90362723486960E-07,2.10375278936190E-01,2.56812397299990E-04,-1.27990029337810E-02,
	      -8.21981026520180E-06);
	for $i (0..$#I) {
	    $T += $n[$i]*$pi**$I[$i]*($sa-2)**$J[$i];
	}
    }
    if ($s < 5.85 and $P > 4){
	$subregion = "c";
	$T = 0;
	@I = (-2,-2,-1,0,0,0,0,1,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,7,7,7,7,7);
	@J = (0,1,0,0,1,2,3,0,1,3,4,0,1,2,0,1,5,0,1,4,0,1,2,0,1,0,1,3,4,5);
	@n = (9.0968501005365E+02,2.4045667088420E+03,-5.9162326387130E+02,5.4145404128074E+02,-2.7098308411192E+02,9.7976525097926E+02,
	  -4.6966772959435E+02,1.4399274604723E+01,-1.9104204230429E+01,5.3299167111971E+00,-2.1252975375934E+01,-3.1147334413760E-01,
	  6.0334840894623E-01,-4.2764839702509E-02,5.8185597255259E-03,-1.4597008284753E-02,5.6631175631027E-03,-7.6155864584577E-05,
	  2.2440342919332E-04,-1.2561095013413E-05,6.3323132660934E-07,-2.0541989675375E-06,3.6405370390082E-08,-2.9759897789215E-09,
	  1.0136618529763E-08,5.9925719692351E-12,-2.0677870105164E-11,-2.0874278181886E-11,1.0162166825089E-10,-1.6429828281347E-10);
	for $i (0..$#I) {
	    $T += $n[$i]*$pi**$I[$i]*(2-$sc)**$J[$i];
	}	
    }   
    if ($s >= 5.85 and $P > 4) {
	$subregion = "b";
	$T = 0;
        @I = (-6,-6,-5,-5,-4,-4,-4,-3,-3,-3,-3,-2,-2,-2,-2,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,3,3,3,4,4,5,5,5);
	@J = (0,11,0,11,0,1,11,0,1,11,12,0,1,6,10,0,1,5,8,9,0,1,2,4,5,6,9,0,1,2,3,7,8,0,1,5,0,1,3,0,1,0,1,2);
	@n = (3.1687665083497E+05,2.0864175881858E+01,-3.9859399803599E+05,-2.1816058518877E+01,2.2369785194242E+05,-2.7841703445817E+03,
	  9.9207436071480E+00,-7.5197512299157E+04,2.9708605951158E+03,-3.4406878548526E+00,3.8815564249115E-01,1.7511295085750E+04,
	  -1.4237112854449E+03,1.0943803364167E+00,8.9971619308495E-01,-3.3759740098958E+03,4.7162885818355E+02,-1.9188241993679E+00,
	  4.1078580492196E-01,-3.3465378172097E-01,1.3870034777505E+03,-4.0663326195838E+02,4.1727347159610E+01,2.1932549434532E+00,
	  -1.0320050009077E+00,3.5882943516703E-01,5.2511453726066E-03,1.2838916450705E+01,-2.8642437219381E+00,5.6912683664855E-01,
	  -9.9962954584931E-02,-3.2632037778459E-03,2.3320922576723E-04,-1.5334809857450E-01,2.9072288239902E-02,3.7534702741167E-04,
	  1.7296691702411E-03,-3.8556050844504E-04,-3.5017712292608E-05,-1.4566393631492E-05,5.6420857267269E-06,4.1286150074605E-08,
	  -2.0684671118824E-08,1.6409393674725E-09);
	for $i (0..$#I) {
	    $T += $n[$i]*$pi**$I[$i]*(10-$sb)**$J[$i];
	}
    }      
 steamproperties_IAPWS97_R2_PT($P,$T);
}

sub steamproperties_IAPWS97_R2_hs {
    # Region 2, gas phase (and works into Region 5 a little bit)
    # as pressure and temp increase, extrapolation into region 5 breaks down
    # below 1200K its very good
    # units must be absolute SI (KJ/kg,KJ/kg-K)
    # this sub takes about 0.7ms per iteration (2.4GHz i5 processor), but could be lower/higher depending on the region
    # the steamproperties_IAPWS97_R2_Ps sub that it calls at the end takes about 0.27ms per iteration (2.4GHz i5 processor)
    my ($h,$s) = @_;
    my (@I,@J,@n,$i,$subregion,$P,$pi,$sigma,$eta,$pstar,$h2ab);
    @n = (0,-0.349898083432139E4,0.257560716905876E4,-0.421073558227969E3,0.276349063799944E2);
    $h2ab = $n[1]+$n[2]*$s+$n[3]*$s**2+$n[4]*$s**3;
    
    # subregion a/b/c
    if ($h<=$h2ab){
	($subregion,$sigma,$eta,$pstar,$pi) = ("a",$s/12,$h/4200,4,0);
	@I = (0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,2,2,2,3,3,3,3,3,4,5,5,6,7);
	@J = (1,3,6,16,20,22,0,1,2,3,5,6,10,16,20,22,3,16,20,0,2,3,6,16,16,3,16,3,1);
	@n = (-1.82575361923032E-02,-1.25229548799536E-01,5.92290437320145E-01,6.04769706185122E+00,2.38624965444474E+02,-2.98639090222922E+02,
	      5.12250813040750E-02,-4.37266515606486E-01,4.13336902999504E-01,-5.16468254574773E+00,-5.57014838445711E+00,1.28555037824478E+01,
	      1.14144108953290E+01,-1.19504225652714E+02,-2.84777985961560E+03,4.31757846408006E+03,1.12894040802650E+00,1.97409186206319E+03,
	      1.51612444706087E+03,1.41324451421235E-02,5.85501282219601E-01,-2.97258075863012E+00,5.94567314847319E+00,-6.23656565798905E+03,
	      9.65986235133332E+03,6.81500934948134E+00,-6.33207286824489E+03,-5.58919224465760E+00,4.00645798472063E-02);
	for $i (0..$#I) {
	    $pi += $n[$i]*($eta-0.5)**$I[$i]*($sigma-1.2)**$J[$i];
	}	
    }
    if ($h>$h2ab and $s>=5.85) {
	($subregion,$sigma,$eta,$pstar,$pi) = ("b",$s/7.9,$h/4100,100,$pi = 0);
        @I = (0,0,0,0,0,1,1,1,1,1,1,2,2,2,3,3,3,3,4,4,5,5,6,6,6,7,7,8,8,8,8,12,14);
	@J = (0,1,2,4,8,0,1,2,3,5,12,1,6,18,0,1,7,12,1,16,1,12,1,8,18,1,16,1,3,14,18,10,16);
	@n = (8.01496989929495E-02,-5.43862807146111E-01,3.37455597421283E-01,8.90555451157450E+00,3.13840736431485E+02,7.97367065977789E-01,
	      -1.21616973556240E+00,8.72803386937477E+00,-1.69769781757602E+01,-1.86552827328416E+02,9.51159274344237E+04,-1.89168510120494E+01,
	      -4.33407037194840E+03,5.43212633012715E+08,1.44793408386013E-01,1.28024559637516E+02,-6.72309534071268E+04,3.36972380095287E+07,
	      -5.86634196762720E+02,-2.21403224769889E+10,1.71606668708389E+03,-5.70817595806302E+08,-3.12109693178482E+03,-2.07841384633010E+06,
	      3.05605946157786E+12,3.22157004314333E+03,3.26810259797295E+11,-1.44104158934487E+03,4.10694867802691E+02,1.09077066873024E+11,
	      -2.47964654258893E+13,1.88801906865134E+09,-1.23651009018773E+14);
	for $i (0..$#I) {
	    $pi += $n[$i]*($eta-0.6)**$I[$i]*($sigma-1.01)**$J[$i];
	}
    }      
    if ($h>$h2ab and $s<5.85){
	# subregion c
	($subregion,$sigma,$eta,$pstar,$pi) = ("c",$s/5.9,$h/3500,100,0);
	@I = (0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,5,5,5,5,6,6,10,12,16);
	@J = (0,1,2,3,4,8,0,2,5,8,14,2,3,7,10,18,0,5,8,16,18,18,1,4,6,14,8,18,7,7,10);
	@n = (1.12225607199012E-01,-3.39005953606712E+00,-3.20503911730094E+01,-1.97597305104900E+02,-4.07693861553446E+02,1.32943775222331E+04,
	      1.70846839774007E+00,3.73694198142245E+01,3.58144365815434E+03,4.23014446424664E+05,-7.51071025760063E+08,5.23446127607898E+01,
	      -2.28351290812417E+02,-9.60652417056937E+05,-8.07059292526074E+07,1.62698017225669E+12,7.72465073604171E-01,4.63929973837746E+04,
	      -1.37317885134128E+07,1.70470392630512E+12,-2.51104628187308E+13,3.17748830835520E+13,5.38685623675312E+01,-5.53089094625169E+04,
	      -1.02861522421405E+06,2.04249418756234E+12,2.73918446626977E+08,-2.63963146312685E+15,-1.07890854108088E+09,-2.96492620980124E+10,
	      -1.11754907323424E+15);
	for $i (0..$#I) {
	    $pi += $n[$i]*($eta-0.7)**$I[$i]*($sigma-1.1)**$J[$i];
	}
    }
  $P = $pstar*$pi**4;
  
 # steamproperties_IAPWS97_R2_Ph($P,$h);
 steamproperties_IAPWS97_R2_Ps($P,$s);
}


sub steamproperties_IP {
    steamproperties_SI($_[0],$_[1],$_[2],$_[3],$_[4],'psia','F','btu/lb','btu/lbf','lb/ft^3','ft/s')
}

sub steamproperties_SI {
    # this is the main steam properties function
    # input and output units are default SI in MPa, K, kJ/kg, kJ/kg-K, m/s
    # unless defined differently by @_[5,6,7,8,9], and will be output in the same units
    # use units like BTU, kJ, J, cal, kg, K, C, R, kg/m^3, kPa, bar, inHg (look at the convert_units sub for options)
    # inputs are PT (regions 1,2,4,5), Ps (1,2,4,5), Ph (1,2,4,5), or hs (1, 2, and a little into 5 only)
    # @_[0,1,2,3,4] = Pressure (P), Temperature (T), Enthalpy (h), Entropy (s), Quality (x)
    # @_[5,6,7,8,9] = Pressure units, Temperature units, Enthalpy units, Entropy/Heat Coefficient units (s,Cp,Cv), sonic velocity units
    # regions it can render are:
    # Region 1 - liquid up to saturation
    # Region 2 - dry steam including sub regions
    # 2(a) - < 4 MPa (565psig) at any T or s above saturation
    # 2(b) - > 4 MPa and s > 5.85kJ/kgK (very high temp and high pressure, bordering Region 5)
    # 2(c) - > 4 MPa and s < 5.85kJ/kgK (near critical, approaching compressible liquid status, not commonly seen in use)
    # Region 3 not defined (this region is very uncommon, the "compressible liquid" range)
    # Region 4 - the saturation line from the triple point to the critical point at (611.213Pa to 22.064MPa and 273.15K to 647.096K)
    # and Region 5 - very high temp (1073K to 2273K at 0-50MPa), only pure undissociated water
    # enter "0" if not known for any variable, do not leave blank
    # enter 'sat' for P or T (for saturation properties)
    # if looking for wet steam properties, $_[4] is quality x (0-1)
    
    my ($P,$T,$h,$s,$x,$Pu,$Tu,$hu,$su,$pu,$wu) = @_;
    my ($p,$v,$u,$Ps,$Ts,$hg,$sg,$ug,$pg,$vg,$hf,$sf,$uf,$pf,$vf,$Cp,$Cv,$Cpf,$Cvf,$Cpg,$Cvg,$wf,$wg,$w,$region);

    ($T = convert_units($T,$Tu,'K')) if ($Tu and $T>0);
    ($P = convert_units($P,$Pu,'MPa')) if ($Pu and $P>0);
    ($s = convert_units($s,$su,'kj/kgk')) if ($su and $s>0);
    ($h = convert_units($h,$hu,'kj/kg')) if ($hu and $h>0);
    
    # dry saturated, saturated liquid, or wet steam
    # Temp or Pressure known.  Then h, s, or x is known
    # steamproperties($P,'sat',$h) returns the same as steamproperties($P,0,$h) if $h is within hf to hg for the given saturation pressure, $P
    if ((($P =~ /s/) and ($T >= 273.15)) or (($P > 0) and ($T =~ /s/))) { 
	($Ps,$Ts) = satsteam_IAPWS97_R4_T($T) if ($T >= 273.15);
	($Ps,$Ts) = satsteam_IAPWS97_R4_P($P) if ($P > 0);
	($Ps,$Ts,$hf,$sf,$uf,$pf,$vf,$Cpf,$Cvf,$w) = steamproperties_IAPWS97_R1_PT($Ps,$Ts);
	($Ps,$Ts,$hg,$sg,$ug,$pg,$vg,$Cpg,$Cvg,$w) = steamproperties_IAPWS97_R2_PT($Ps,$Ts);
	$x = ($h-$hf)/($hg-$hf) if ($h>$hf and $h<$hg); # if you enter a valid h value (between hf and hg) it will overwrite x
	$x = ($s-$sf)/($sg-$sf) if ($s>$sf and $s<$sg); # if you enter a valid s value (between sf and sg) it will overwrite x and h	
	($h,$s,$u,$p,$v,$P,$T) = ($hf*(1-$x)+$hg*$x,$sf*(1-$x)+$sg*$x,$uf*(1-$x)+$ug*$x,$pf*(1-$x)+$pg*$x,$vf*(1-$x)+$vg*$x,$Ps,$Ts);
	$region = 4;
    }
    # sub-cooled liquid or superheated steam
    # It's best not to enter a value for both P and T if you want saturated or wet steam properties
    # choose a temp or pressure then "sat" for the other term, then a value for x, h or s
    # rarely will you be able to pick the EXACT value that the saturation formula will provide so it's best not to try
    elsif (($P > 0) and ($T >= 273.15)) {
	#  Region 3 check
	#  if ($T >= 623.15 and $T <= 863.15 and $P >= 16.5292) {
	#    my ($pi,$theta) = ($P/1,$T/1);
	#    my @n = (0.34805185628969E3,-0.11671859879975E1, 0.10192970039326E-2, 0.57254459862746E3, 0.13918839778870E2);
	#    $pi = $n[0]+$n[1]*$theta+$n[2]*$theta**2;
	#    return steamproperties_IAPWS97_R3_PT($P,$T)
	#  }
	
	($Ps,$Ts) = satsteam_IAPWS97_R4_P($P);
	if ($Ts > $T){
	    (($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R1_PT($P,$T)); # liquid if saturation temp is > actual
	    $x = 0;
	    $region = 1;
	}
	if ($Ts < $T){
	    ($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R2_PT($P,$T); # superheated if saturation temp is < actual
	    $x = 1;
	    $region = 2;
	}
	if ($Ts == $T){ # if somehow they are equal, use h or s (if non-zero) or x to determine steam quality
	    ($P,$Ts,$hf,$sf,$uf,$pf,$vf,$Cpf,$Cvf,) = steamproperties_IAPWS97_R1_PT($Ps,$Ts);
	    ($P,$Ts,$hg,$sg,$ug,$pg,$vg,$Cpg,$Cvg,) = steamproperties_IAPWS97_R2_PT($Ps,$Ts);
	    $x = ($h-$hf)/($hg-$hf) if ($h>$hf and $h<$hg); # if you enter a valid h value it will overwrite x
	    $x = ($s-$sf)/($sg-$sf) if ($s>$sf and $s<$sg); # if you enter a valid s value it will overwrite x and h	
	    ($h,$s,$u,$p,$v) = ($hf*(1-$x)+$hg*$x,$sf*(1-$x)+$sg*$x,$uf*(1-$x)+$ug*$x,$pf*(1-$x)+$pg*$x,$vf*(1-$x)+$vg*$x);
	    $region = 4;
	}
    }
    # for pressure/enthalpy (liquid, gas, or wet)
    # if you also entered a value for s or x they are ignored
    elsif ($P > 0 and $h > 0) {
	($Ps,$Ts) = satsteam_IAPWS97_R4_P($P);
	($Ps,$Ts,$hf,$sf,$uf,$pf,$vf,$Cpf,$Cvf,$wf) = steamproperties_IAPWS97_R1_PT($Ps,$Ts);
	($Ps,$Ts,$hg,$sg,$ug,$pg,$vg,$Cpg,$Cvg,$wg) = steamproperties_IAPWS97_R2_PT($Ps,$Ts);
	$x = ($h-$hf)/($hg-$hf);
	($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R2_Ph($P,$h) if ($x>1); # superheated
	($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R1_Ph($P,$h) if ($x<0); # liquid
	($P,$T,$h,$s,$u,$p,$v) = ($P,$Ts,$hf*(1-$x)+$hg*$x,$sf*(1-$x)+$sg*$x,$uf*(1-$x)+$ug*$x,$pf*(1-$x)+$pg*$x,$vf*(1-$x)+$vg*$x) if ($x>=0 and $x<=1); #wet
    }
    # for pressure/entropy (liquid, gas, or wet)
    # if you also entered a value for x it is ignored
    elsif ($P > 0 and $s > 0) {
	($P,$Ts) = satsteam_IAPWS97_R4_P($P);
	($P,$Ts,$hf,$sf,$uf,$pf,$vf,$Cpf,$Cvf,$wf) = steamproperties_IAPWS97_R1_PT($P,$Ts);
	($P,$Ts,$hg,$sg,$ug,$pg,$vg,$Cpg,$Cvg,$wg) = steamproperties_IAPWS97_R2_PT($P,$Ts);
	$x = ($s-$sf)/($sg-$sf);
	($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R2_Ps($P,$s) if ($x>1); # superheated
	($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R1_Ps($P,$s) if ($x<0); # liquid
	($P,$T,$h,$s,$u,$p,$v) = ($P,$Ts,$hf*(1-$x)+$hg*$x,$sf*(1-$x)+$sg*$x,$uf*(1-$x)+$ug*$x,$pf*(1-$x)+$pg*$x,$vf*(1-$x)+$vg*$x) if ($x>=0 and $x<=1); #wet
    }
    # for enthalpy/entropy for liquid, gas, but not wet (0 < x < 1)
    # requires x >= 1 _OR_ x <= 0
    # otherwise returns blank values for u, p, v, P, and T
    elsif ($h > 0 and $s > 0) {  
	($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R2_hs($h,$s) if ($x>=1); # superheated	($P,$Ts) = satsteam_IAPWS97_R4_P($P);
	($P,$T,$h,$s,$u,$p,$v,$Cp,$Cv,$w) = steamproperties_IAPWS97_R1_hs($h,$s) if ($x<=0); # liquid	($hf,$sf,$uf,$pf,$vf,$P,$Ts) = steamproperties_IAPWS97_R1_PT($P,$Ts);
    }
    
    
    $T = convert_units($T,'k',$Tu) if ($Tu);
    $Ts = convert_units($Ts,'k',$Tu) if ($Tu);
    $P = convert_units($P,'mpa',$Pu) if ($Pu); 
    $s = convert_units($s,'kj/kgk',$su) if ($su);
    $h = convert_units($h,'kj/kg',$hu) if ($hu);
    $u = convert_units($u,'kj/kg',$hu) if ($hu);    
    $p = convert_units($p,'kg/m^3',$pu) if ($pu);

    $Cp = convert_units($Cp,'kj/kgk',$su) if ($su);
    $Cv = convert_units($Cv,'kj/kgk',$su) if ($su);
    $w = convert_units($w,'m/s',$wu) if ($wu);
    $v = 1/$p if ($p>0);

    my @Cpvw = ($Cp,$Cv,$w);
    @Cpvw = ($Cpf,$Cvf,$wf,$Cpg,$Cvg,$wg) if ($x>0 and $x<1);

 ($P,$T,$h,$s,$x,$u,$p,$v,@Cpvw);
}

sub pressuredrop {
    # uses Hazen-Williams method for calculating pressure drop
    # default units, flow: gpm, diamter: inches, distance: ft
    # returns Pressure drop in psi
    my ($flow,$dia,$C,$length) = @_;
    $C = (120 or $C); # default C, ranges from 100 (very smooth) to 140 (very rough)
    $length = (100 or $length); # if no length is provided, drop per 100ft is returned
    4.52*$length*$flow**1.85/$C**1.85/$dia**4.87;
}

sub hydraulicdiam {
    my ($w,$h,$type) = @_;
    if ($type =~ /r/) {
	4*$w*$h/2/($w+$h);
    }
    else {
	
    }
  
}

sub DarcyPD {
    # Darcy-Weisbach pressure drop method
    # uses Serghides's solution for fD
    # pd in psi
    # d = hydraulic diameter (inches), l = length, ft
    # v = velocity (ft/s), rho = density lb/cuft, mu = viscosity lbm/ft-s
    my ($d,$v,$l,$rho,$mu,$e,$dunits,$vunits,$lunits,$rhounits,$muunits,$eunits) = @_;
    $dunits = 'in' unless $dunits;
    $vunits = 'fps' unless $vunits;
    $lunits = 'ft' unless $lunits;
    $rhounits = 'lb/cuft' unless $rhounits;
    $muunits = 'lbm/ft-s' unless $muunits;
    $eunits = 'in' unless $eunits;
    
    my ($Re,$fD,$pd,$A,$B,$C);
    $Re = $rho*$v*$d/$mu;
    if ($Re > 10000) {
	$A = -2*log10($e/3.7/$d + 12/$Re);
	$B = -2*log10($e/3.7/$d + 2.51*$A/$Re);
	$C = -2*log10($e/3.7/$d + 2.51*$B/$Re);
	$fD = ($A-(($B-$A)**2)/($C-2*$B+$A))**-2;
    }
    else {$fD = 64/$Re}
print join "\t", 're,fD: ',int $Re,$fD,"\n";
    $fD*$l/($d/12)*$rho*$v**2/2/32.2/144;
}

sub gaspd {
    # uses Darcy-Weisbach formula with natural gas
    # gaspd($p1,$d,$vf,$l,$e,$t)
    # inputs: inlet pressure (psig), diameter (inches), standard vol flow (CF/hr), length, temperature (F), roughness (in)
    # figures out velocity, density, viscosity, and uses them in the DarcyPD function
    # to convert in w.c. to psig divide by 27.684
    # if roughness is not entered, assumes 0.0018" (steel pipe)
    # if temp is not entered assumes 60F
    my ($p1,$d,$vf,$l,$e,$t,$rho,$mflow,$v,$mu) = @_;
    $l = 100 unless ($l > 0); # if length is not provided, provides for pd per 100ft
    $e = 1.8E-3 if ($e eq ''); # e of steel pipe is default
    $t = 60 if ($t eq '');  # temp of 60F is default
    $mu  = 1.22825E-08*$t + 6.57011E-06 + 8.18772E-10*($p1); # corrects for temperature, and slightly for pressure
    $rho = ($p1+14.696)*144/79.1/(459+$t); # density of pressurized flow lb/cuft
    $mflow = 0.0447*$vf; # mass flow lb/hr
    $v = $vf/(&pi()*($d/12)**2/4)/3600*0.0447/$rho;
    print join "\t",'d,v,l,rho,mu,e:',$d,$v,$l,$rho,$mu,$e,"\n";
DarcyPD($d,$v,$l,$rho,$mu,$e);

}

sub polynomial {
    # y = ax^n + bx^(n-1)...+dx + e
    # call as $y = polynomial($x,$e,$d,$c,$b,$a)
    # no limit to number of coefficients, just order them from 0 to highest.
    my ($i,$y) = (0,0);
    for $i (1..$#_){
	$y += $_[$i]*$_[0]**($i-1);
    }
    $y;
}

sub intersect {
    my ($interations) = 0;
    my (@eq1,@eq2);
    my ($guess,$order1,$order2) = @_[0,1,2];
     @eq1 = @_[3..(3+$order1)];
     @eq2 = @_[(4+$order1)..(4+$order1+$order2)];
}


sub viscosity {
   # returns dynamic viscosity, (mu) of different fluids
   # good for Re calcs, Re = (rho)vD/(mu)
   my $fluid = lc $_[0];
   my $temp = ($_[1] or 60); # temp in F
   @C{'air','nh3','co2','co','h2','n2','o2','so2'} = (120,370,240,118,72,111,127,416);
   @T0{'air','nh3','co2','co','h2','n2','o2','so2'} = (524.07,527.67,527.67,518.67,528.93,540.99,526.05,528.57);
   @mu0{'air','nh3','co2','co','h2','n2','o2','so2'} = (3.81843E-07,2.05238E-07,3.0932E-07,3.5948E-07,1.83084E-07,3.72229E-07,4.21762E-07,2.62086E-07);

if ($fluid =~ /^air$|^nh3$|^co2$|^co$|^h2$|^n2$|^o2$|^so2$/) {$mu = $mu0{$fluid}*((0.555*$T0{$fluid}+$C{$fluid})/(0.555*($temp+459.15)+$C{$fluid})*(($temp+459.15)/$T0{$fluid})**1.5)};
    my %visc = ('water' => polynomial($temp,6.53498,-1.15941E-01,9.93654E-04,-4.12278E-06,6.56853E-09),
	        'natgas' => 3.444E-10*$temp+2.110E-07);
}

sub PPCLreportparse {
    # Input is @_ = lines of Insight PPCL Report
    my (@new);
    for (@_) {
        chomp;
        push @new, ("\n\n",$_) if /^Panel System Name:/;
        push @new, ("\n",$_) if /^Program Name:/;
        push @new, ("\n",$_) if /^Priority for Writing:/;
        if (s/^            (\S.+)/$1/){push @new, ($_) }
        push @new, ("\n",$_) if /^E/;
        push @new, ("\n",$_) if /^D/;
    }
@new;
}

sub testerprogram {
    # my ($i,$Ps,$Ts,$P,$T,$h,$s);
    # ($Ps,$Ts) = satsteam_IAPWS97_R4_P(4);
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R2_PT($Ps,$Ts+100); 
    # for $i (0..10000) {
    # @d = exceldatevalue($i);
    # timeshift($i,0,2,1,1914,0,0,0,$i);
    # $d = leapyear($i);
    # ($Ps,$Ts) = satsteam_IAPWS97_R4_T(274+3*$i/1000); # 0.002ms
    # ($Ps,$Ts) = satsteam_IAPWS97_R4_P($i/1000+.01); # 0.0022ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R1_PT(2*$Ps,$Ts); #0.097ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R1_Ph($Ps,$h); #0.107 ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R1_Ps($P,$s); #0.11ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R1_hs($h,$s); #0.12ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R2_PT($P,$T+$i/100); #0.11ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R5_PT(4+$i/2000,1000+$i/1000); #0.024ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R2_Ph($Ps,$h); #0.13ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R2_Ps($Ps,$s); #0.14ms
    # ($P,$T,$h,$s) = steamproperties_IAPWS97_R2_hs($h,$s); #0.17ms
    #  ($P,$T,$h,$s) = steamproperties_IP(300,'sat',0,0,0.5); # R4: 0.477ms, R1/R2: 0.375ms, R5: 0.278ms
    # convert_units(273,"f","k");
    # $z++;
   # }
# $z;
}

# ($sec,$usec) = starttiming();
# $z = testerprogram();
# $totaltime = endtiming($sec,$usec);
# print STDOUT $totaltime/$z," sec per iteration";

1;