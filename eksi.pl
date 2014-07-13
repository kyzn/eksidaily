#   eksidebe: first run on 05-Dec-2012

#   TODO
#   1: Download images, convert to base64, embed them to html and .mobi files.
#   2: Create .mobi files by using kindlegen and/or calibre's ebook-convert.
#   3: Read mail addresses from a database, not a file.
#   4: Replace wget by LWP::UserAgent, and check shorthened URLs
#   5: Embed tweets

use DateTime; 
use MIME::Lite;
use HTML::Entities;
use open qw/:std :utf8/;
use Modern::Perl;
#use diagnostics;

#You can call dev mode by passing argument d.
#This is useful if you want to test the program by 
#sending the result to different set of mail addresses.

my $dev=0;
foreach(@ARGV){
  if(lc($_) eq ("d")){$dev=1;}
  print "d ";
}


#Date related stuff here.
my $dt   = DateTime->now; 
my $searchdate = DateTime->now->subtract(days=>1)->ymd;
my $filedate   = DateTime->now->subtract(days=>1)->dmy;
my $todaydate  = DateTime->now->dmy;


#You should provide your working folder.
#You can specify a different path for dev mode.
my $folder_temp="/home/kyzn/eksi/";
#$folder_temp="/Users/kyzn/git/eksidebe/"; #local dev.
#if ($dev){ $folder_temp="/home/kyzn/eksi/"; }

#You can change these files, as they're called by their variable names.
my $file_in_list="$folder_temp"."inlist";
my $file_out_html="$folder_temp"."out.html";
my $file_log="$folder_temp"."log";

#These links better stay as they are, as long as eksisozluk doesn't change them.
my $link_stats="https://eksisozluk.com/istatistik/dunun-en-begenilen-entryleri";
my $link_entry="https://eksisozluk.com/entry/";
my $link_topic="https://eksisozluk.com/";
my $searchstring = "?a=search&searchform.when.from=$searchdate";

#Wget will be replaced very soon.
my $wget="wget --no-check-certificate -q -O";

#This is the addresses to be included. Emails are stored in this file.
#Please check address_sample.pm for an example.
use address;
#This hash will store mail addresses.
my %adr=getAddress();

#Recipients are chosen differently depending on whether you're on dev mode or not.
my $to_email;
if($dev){ 
   $to_email= $adr{to_email_dev};
}else{
  $to_email= $adr{to_email_all};
}
#If there is no recipient, then die.
if($to_email eq ""){
  die "No email recipient found";
}

# #Kindle sending is disabled temporarily.
# my $to_kindle;
# if($dev){ 
#   $to_kindle= $adr{to_kindle_dev};
# }else{
#   $to_kindle= $adr{to_kindle_all};
# }

# #If there is no recipient, then die.
# if($to_kindle eq ""){
#   die "No kindle recipient found";
# }


my $log = "### $dt ###\n\n";



#Get the last debe list.
system("$wget $file_in_list $link_stats");
open FILE, "$file_in_list" or die;
my @lines = <FILE>;
close FILE or die;



#Skip partial lists on the debe page.
my $pointer=0;
while($pointer < @lines && $lines[$pointer]!~/"topic-list/){
  $pointer++;
}
#if($dev){ print "Pointer at line $pointer.\n";}

#Declare arrays where entry details to be stored.
my @entries_topic;
my @entries_id;
my @entries_topic4link;
my @entries_datepublished;
my @entries_datetoprint;
my @entries_datemodified;
my @entries_numberintopic;
my @entries_author;
my @entries_body;
my @entries_favcount;

#Details of reference entry.
#A reference entry is the first entry of the topic that is written
#on the particular day. It is not downloaded seperately if the debe
#entry is already the first entry of the day.
my @entries_ref_id;
my @entries_ref_datepublished;
my @entries_ref_datetoprint;
my @entries_ref_datemodified;
my @entries_ref_numberintopic;
my @entries_ref_author;
my @entries_ref_body;
my @entries_ref_ref_topic;
my @entries_ref_favcount;


#Fill the entries_id and entries_topic from the list.
#ith entry of array will show ith entry of debe.
my $i=1;
while($pointer<@lines){
  if($lines[$pointer]=~/<span class="caption">(.*)<\/span>/){
    $entries_topic[$i]=$1;
    $entries_topic[$i]=decode_entities($entries_topic[$i]);
    
    if($lines[$pointer-1]=~/%23(\d+)">/){
      $entries_id[$i]=$1;
    }else{
      die "Couldn't get id at line $pointer";
    }

    $i++;
  }
  $pointer++;
}

#Fixes the problem of getting 60 entries instead of 50
#caused by the partial list.

while(@entries_id>51){
  splice @entries_id,1,1;
  splice @entries_topic,1,1;
  $i--;
}

#It's now possible to get less than 50 entries in debe. Check for that
my $debe_count = $i-1;
my $eid_count  = scalar(@entries_id) -1;
my $etp_count  = scalar(@entries_topic) -1;

#Make sure @entries_id and @entries_topic has the same number of elements with debe_count.
if($eid_count!=$debe_count){
  die "There are $eid_count ids for $debe_count entries";
}
if($etp_count!=$debe_count){
  die "There are $etp_count topics for $debe_count entries";
}


#If did not get entry ids, then die.
for(my $i=$debe_count;$i>0;$i--){
  if(!defined($entries_id[$i])){
    die "Entry $i has no id";
  }
  if(!defined($entries_topic[$i])){
    die "Entry $i nas no topic";
  }
}

#If half of the entries are missing, assuming there's a problem.
if($debe_count<26){
  die "Only $debe_count entries found";
}

#Start creating the html file.
my $out="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"tr\"><head>\n
<meta http-equiv=\"Content-type\" content=\"text/html; charset=utf-8\" />\n
<meta http-equiv=\"Content-language\" content=\"tr\" />\n
<style>
p.big {
  line-height:150%;
  text-align:justify;
  margin-left: 0.5cm;
  margin-right: 0.5cm;
}
p.bigref {
  line-height:150%;
  text-align:justify;
  margin-left: 0.5cm;
  margin-right: 0.5cm;
}
img{
  width:90%;
  max-width:200px;
  overflow:hidden;
}
body{    
  font: 9pt Verdana, sans-serif;
    background-color: #cccccc;
    color: black;
    height: 100%;
}
a {
    color: #000080;
    text-decoration: none;
}
a:hover {
    background-color: #c0c0c0;
}
</style>
</head><body>\n\n\n
<h2>$filedate'&#252;n en be&#287;enilen entryleri</h2>
<br><hr>\n\n\n";

#Get 50 entries, and their references if exists.
for(my $i=$debe_count;$i>0;$i--){

  my $entrydeleted=0;

  system("$wget ${folder_temp}.entry$i $link_entry$entries_id[$i]");
  open FILE, "${folder_temp}.entry$i" or die;
  my @lines = <FILE>;
  close FILE or die;
 
# # This part redownloads a file until the file comes with more than 0 lines.
# # But a deleted entry can also be empty.. So that's a risk to uncomment this.  
#  while(scalar(@lines==0)){
#    print "File of entry $i is empty. Sleeping for 15 secs.\n";
#    sleep(15);
#    print "Woke up. Trying a redownload.\n";
#    system("$wget ${folder_temp}.entry$i $link_entry$entries_id[$i]");
#    open FILE, "${folder_temp}.entry$i" or die;
#    my @lines = <FILE>;
#    close FILE or die;
#  }

  #Show a specific message for deleted entries accordingly.
  if (scalar(@lines)==0){ 
    $entries_datepublished[$i]="?";
    $entries_datetoprint[$i]="?";
    $entries_datemodified[$i]="";
    $entries_numberintopic[$i]="?";
    $entries_author[$i]="?";
    $entries_favcount[$i]="?";
    $entries_body[$i]="<i>bu entry silinmi&#351;.</i>";
    $entrydeleted=1;
  }

  for(my $j=0;$j<@lines && !$entrydeleted;$j++){

    #goo.gl opener
    while($lines[$j]=~/href="(http:\/\/goo.gl[^"]*)"/){
      my $temp=&longgoogl($1);
      $lines[$j]=~s/href="(http:\/\/goo.gl[^"]*)"/href="$temp"/;
    }

    #Get the link of the topic.
    if($lines[$j]=~/<a href="\/(.*)" itemprop="url">.*<\/a>[^<]/){$entries_topic4link[$i]=$1;} 
    
    #This is to open up hidden references (akıllı bkz, yıldız)
    $lines[$j]=~s/<sup class=\"ab\"><([^<]*)(data-query=\")([^>]*)\">\*<\/a><\/sup>/<$1$2$3\">\(* $3\)<\/a>/g;
    
    #Fix links for eksisozluk.com so that they can work when you're outside eksisozluk.com as well.
    #Also open links in new tabs (_blank).
    $lines[$j]=~s/href="\//target="_blank" href="https:\/\/eksisozluk.com\//g;
    
    #Without this fix you'll see underlines in gmail delivery, which is not intended.
    $lines[$j]=~s/href="/style="text-decoration:none;" href="/g;
    
    #Add img src to display images that are of jpg jpeg png gif formats.
    #Max-width added once more so that gmail recognizes it too.
    $lines[$j]=~s/(href="([^"]*\.(jpe?g|png|gif)(:large)?)"[^<]*<\/a>)/$1<br><br><img src="$2" style="max-width:200px;"><br><br>/g;
    
    #Add a northwest arrow, and domain name in parantheses.
    $lines[$j]=~s/(https?:\/\/(?!eksisozluk.com)([^\/<]*\.[^\/<]*)[^<]*<\/a>)/$1 \($2 &#8599;\)/g;


    #Get entries_numberintopic.
    if($lines[$j]=~/<li id=".*" value="(\d+)"/){$entries_numberintopic[$i]=$1;}

    #Get entries_datepublished.
    if($lines[$j]=~/"commentTime">(\d\d)\.(\d\d)\.(\d\d\d\d)(\s\d\d\:\d\d)/){
      $entries_datepublished[$i]=$1.".".$2.".".$3.$4;
      #Control the date. If the entry is not of the today or yesterday, die immediately.
      my $datecontrol=$1."-".$2."-".$3; 
      if($datecontrol ne $filedate && $datecontrol ne $todaydate){
        die "Date control failed\n".
        "Entry has $datecontrol.\n".
        "Checked for $filedate and $todaydate with no match.\n".
        "Debe list might not be updated yet.";
        #This leaves downloaded file with no move to /tmp, so you can go check what is going on.
      }
      #Get entries_datemodified.
      if($lines[$j]=~/"son g.ncelleme zaman.">(.*)<\/time>/){$entries_datemodified[$i]=$1;}
    }

    #Get entries_author.
    if($lines[$j]=~/data-author="(.*)" data-flags/){$entries_author[$i]=$1;}

    #Get entries_body.
    if($lines[$j]=~/commentText">(.*)<\/div>/){$entries_body[$i]=$1;}

    #Get entries_favcount.
    if($lines[$j]=~/data-favorite-count="(\d+)"/){$entries_favcount[$i]=$1;}
  }

  #Set date to print, aka entries_datetoprint.
  $entries_datetoprint[$i]=$entries_datepublished[$i];
  if($entries_datemodified[$i]){
    $entries_datetoprint[$i].=" ~ ".$entries_datemodified[$i];
  }
  
  #If entry has no date up to this point, die immediately.
  #This used to be called "entries_exist", and has been changed.
  if ($entries_datepublished[$i] eq ""){ 
    die "Entry $i does not have a date" 
    #This leaves downloaded file with no move to /tmp, so you can go check what is going on.
  }
  
  #Log the entry id, display the debe number.  
  $log.= "i:$i\tid:$entries_id[$i]";
  print "$i ";
  
  # #Display more details if dev.
   # if($dev){
   #   print "\n\n";
   #   print "entries_topic:\n$entries_topic[$i]\n\n";
   #   print "topic4link:\n$entries_topic4link[$i]\n\n";
   #   print "numberintopic:\n$entries_numberintopic[$i]\n\n";
   #   print "datepublished:\n$entries_datepublished[$i]\n\n";
   #   print "datemodified:\n$entries_datemodified[$i]\n\n";
   #   print "datetoprint:\n$entries_datetoprint[$i]\n\n";
   #   print "author:\n$entries_author[$i]\n\n";
   #   print "body:\n$entries_body[$i]\n\n";
   #   print "fav:\n$entries_favcount[$i]\n\n";
   # }

  
  #Add entry to html.
  if(!$entrydeleted){
    $out.=  "
    <h3>$i. <a href=\"$link_topic$entries_topic4link[$i]\" target=\"blank\" style=\"text-decoration:none; color:black\">
    $entries_topic[$i]</a></h3><p class=\"big\"><b>$entries_numberintopic[$i]. </b> $entries_body[$i]
    </p><h5><div align=\"right\">
    (<a href=\"https://eksisozluk.com/biri/$entries_author[$i]\" target=\"blank\" style=\"text-decoration:none; color:black\">$entries_author[$i]</a>, <a href=\"https://eksisozluk.com/entry/$entries_id[$i]\" target=\"blank\" style=\"text-decoration:none; color:black\">$entries_datetoprint[$i], $entries_favcount[$i]&#9734;</a>)</div></h5>\n\n
    ";

  }else{
    $out.=  "
    <h3>$i. <a href=\"$link_topic$entries_topic4link[$i]\" target=\"blank\" style=\"text-decoration:none; color:black\">
    $entries_topic[$i]</a></h3><p class=\"big\"><b>$entries_numberintopic[$i]. </b> $entries_body[$i]
    </p><h5><div align=\"right\">
    (?, ?, ?&#9734;)</div></h5>\n\n
    ";
  }


  #Search for a reference entry in a similar way.
  #If the entry is the first entry of the topic, no need to search.
  if(!$entrydeleted && $entries_numberintopic[$i]!=1){ 
    #Make a search for the topic for the specific date.
    system("$wget $folder_temp.temptopic \"$link_topic$entries_topic4link[$i]$searchstring\"");
    open FILE2, "$folder_temp.temptopic" or die;
    my @lines2 = <FILE2>;close FILE2 or die;
    
    for(my $j2=0;$j2<@lines2&&!$entries_ref_id[$i];$j2++){
      #Get the first entry of the day, put it to entries_ref_id.
      #Also get the entries_ref_numberintopic.
      if($lines2[$j2]=~/<li id="li(.*)" value="(\d+)"/){
        
        $entries_ref_id[$i]=$1;
        $entries_ref_numberintopic[$i]=$2;
        
        #If debe entry IS the first entry of the day, do NOT proceed.
        if($entries_ref_id[$i]!=$entries_id[$i]){
          for(my $j3=$j2;$j3<$j2+10;$j3++){
           
            #goo.gl opener
            while($lines2[$j3]=~/href="(http:\/\/goo.gl[^"]*)"/){
              my $temp=&longgoogl($1);
              $lines2[$j3]=~s/href="(http:\/\/goo.gl[^"]*)"/href="$temp"/;
            }

            #This is to open up hidden references (akıllı bkz, yıldız)
            $lines2[$j3]=~s/<sup class=\"ab\"><([^<]*)(data-query=\")([^>]*)\">\*<\/a><\/sup>/<$1$2$3\">\(* $3\)<\/a>/g;
            
            #Fix links for eksisozluk.com so that they can work when you're outside eksisozluk.com as well.
            #Also open links in new tabs (_blank).
            $lines2[$j3]=~s/href="\//target="_blank" href="https:\/\/eksisozluk.com\//g;
        
            #Without this fix you'll see underlines in gmail delivery, which is not intended.
            $lines2[$j3]=~s/href="/style="text-decoration:none;" href="/g;
        
            #Add img src to display images that are of jpg jpeg png gif formats.
            #Max-width added once more so that gmail recognizes it too.
            $lines2[$j3]=~s/(href="([^"]*\.(jpe?g|png|gif)(:large)?)"[^<]*<\/a>)/$1<br><br><img src="$2" style="max-width:200px;"><br><br>/g;
        
            #Add a northwest arrow, and domain name in parantheses.
            $lines2[$j3]=~s/(https?:\/\/(?!eksisozluk.com)([^\/<]*\.[^\/<]*)[^<]*<\/a>)/$1 \($2 &#8599;\)/g;

            #Get entries_ref_datepublished.
            if($lines2[$j3]=~/"commentTime">(\d\d)\.(\d\d)\.(\d\d\d\d)(\s\d\d\:\d\d)/){
              $entries_ref_datepublished[$i]=$1.".".$2.".".$3.$4;
              #Get entries_ref_modified, if any.
              if($lines2[$j3]=~/"son g.ncelleme zaman.">(.*)<\/time>/){
                $entries_ref_datemodified[$i]=$1;
              }
            }
            
            #Get entries_ref_author.
            if($lines2[$j3]=~/data-author="(.*)" data-flags/){$entries_ref_author[$i]=$1;}
            
            #Get entries_ref_body.
            if($lines2[$j3]=~/commentText">(.*)<\/div>/){$entries_ref_body[$i]=$1;}

            #Get entries_favcount.
            if($lines2[$j3]=~/data-favorite-count="(\d+)"/){$entries_ref_favcount[$i]=$1;}  
          }

          #Set date to print, aka entries_ref_datetoprint.
          $entries_ref_datetoprint[$i]=$entries_ref_datepublished[$i];
          if($entries_ref_datemodified[$i]){
            $entries_ref_datetoprint[$i].=" ~ ".$entries_ref_datemodified[$i];
          }
          
          #Log the ref_entry id.
          $log.= "\trid:$entries_ref_id[$i]"; 

          #Add entry to html.
          $out.=  "<h3>g&uuml;n&uuml;n ilk entrysi:</h3><p class=\"bigref\"><b>$entries_ref_numberintopic[$i]. </b> $entries_ref_body[$i]</p><h5><div align=\"right\">(<a href=\"https://eksisozluk.com/biri/$entries_ref_author[$i]\" "
          ."target=\"blank\" style=\"text-decoration:none; color:black\">$entries_ref_author[$i]</a>, <a href=\"https://eksisozluk.com/entry/$entries_ref_id[$i]\" target=\"blank\" style=\"text-decoration:none; "
          ."color:black\">$entries_ref_datetoprint[$i], $entries_ref_favcount[$i]&#9734;</a>)</div></h5>\n\n";  

        }
      }
    }
  }
  $out.="<hr>\n\n";
  $log.="\n";
}

#Move downloaded files to /tmp.
system("mv -f $file_in_list $folder_temp.entry* $folder_temp.temptopic /tmp");

#Finish the html and write out.
$out.="<h3>fin.</h3></body>";
open OUT, ">$file_out_html" or die; print OUT $out; close OUT;


# # Sending to kindles will be disabled temporarily.

# my $msg = MIME::Lite->new(
#   From    => "$adr{from}",
#   To      => "$to_kindle",
#   'Reply-to' => "$adr{reply_to}",
#   Subject => "$filedate",
#   Type    => 'multipart/mixed',
# );

# $msg->attach(
#   Type     => 'application/html',
#   Path     => "$file_out_html",
#   Filename => "$filedate".".html",
#   Disposition => 'attachment'
# );

# $msg->send or die "Error on sending to kindles.";


# Send to email readers.

my $msg = MIME::Lite->new(
  From    => "$adr{from}",
  Bcc     => "$to_email",
  Subject => "$filedate",
  Type    => 'multipart/mixed',
);

$msg->attach(
  Type     => 'application/html',
  Path     => "$file_out_html",
  Filename => "$filedate".".html",
);

$msg->send or die "Error on sending to emails.";

#Write out the log file.
$log.= "\n# DONE #\n\n\n";
open LOG, ">>$file_log" or die; 
print LOG $log; 
close LOG;

#Move the html file to archive.
system("mv -f $file_out_html ${folder_temp}archive/$filedate");
print "\n";

sub longgoogl{
  my $googl = $_[0];
  my $long = `curl -s $1 |grep HREF`;
  if($long =~/"(http[^"]*)"/){
    $long = $1;
  }
  return $long;
}