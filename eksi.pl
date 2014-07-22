#   eksidebe: first run on 05-Dec-2012

#   TODO
#   1: Download images, convert to base64, embed them to html and .mobi files.
#   2: Create .mobi files by using kindlegen and/or calibre's ebook-convert.
#   3: Read mail addresses from a database, not a file.
#   5: Embed tweets

use DateTime; 
use MIME::Lite;
#use HTML::Entities;
#use open qw/:std :utf8/;
use Modern::Perl;
use WWW::Eksisozluk; #Yay!
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
my $filedate   = DateTime->now->subtract(days=>1)->dmy;


#You should provide your working folder.
#You can specify a different path for dev mode.
my $folder_temp="/home/kyzn/eksi/";
#$folder_temp="/Users/kyzn/git/eksidebe/"; #local dev.
#if ($dev){ $folder_temp="/home/kyzn/eksi/"; }

#You can change these files, as they're called by their variable names.
my $file_out_html="$folder_temp"."out.html";
my $file_log="$folder_temp"."log";
my $log="";

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


my $eksi = WWW::Eksisozluk->new();
my @debe = $eksi->debe_ids();

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
  max-width:250px;
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
for(my $i=scalar(@debe);$i>0;$i--){

  my %entry = $eksi->entry($debe[$i-1]);
  $log.="$i $entry{'id'} $entry{'id_ref'}";
  #Show a specific message for deleted entries accordingly.
  if ($entry{'is_found'}==0){ 
    $entry{'date_print'}="?";
    $entry{'number_in_topic'}="?";
    $entry{'author'}="?";
    $entry{'fav_count'}="?";
    $entry{'body'}="<i>bu entry silinmi&#351;.</i>";
  }

   #Different fav-star for ssg. Surprise.
   my $favchar = "&#9734;";
   if ($entry{'author'} eq "ssg"){ $favchar = "&#10017;";}

   #Shorten very long entries. This is to get rid of "Message clipped. Click to view entire message" thing in gmail.
   #Is not working properly since it may cut before a >. There will be related regexp.
   #if (length($entries_body[$i])>2050){
   #  $entries_body[$i] = substr $entries_body[$i],0,2000;
   #  $entries_body[$i].= "<a href=\"https://eksisozluk.com/entry/$entries_id[$i]\" target=\"blank\" style=\"text-decoration:none;\">  <i>devam&#305;</i></a>";
   #}

  #Add entry to html.
  if($entry{'is_found'}==1){
    $out.=  "
    <h3>$i. <a href=\"$entry{'topic_link'}\" target=\"blank\" style=\"text-decoration:none; color:black\">
    $entry{'topic'}</a></h3><p class=\"big\" style=\"text-align:justify;\"><b>$entry{'number_in_topic'}. </b> $entry{'body'}
    </p><h5><div align=\"right\">
    (<a href=\"https://eksisozluk.com/biri/$entry{'author'}\" target=\"blank\" style=\"text-decoration:none; color:black\">$entry{'author'}</a>, <a href=\"$entry{'id_link'}\" target=\"blank\" style=\"text-decoration:none; color:black\">$entry{'date_print'}, $entry{'fav_count'}$favchar</a>)</div></h5>\n\n
    ";

  }else{
    $out.=  "
    <h3>$i. <a href=\"$entry{'topic_link'}\" target=\"blank\" style=\"text-decoration:none; color:black\">
    $entry{'topic'}</a></h3><p class=\"big\" style=\"text-align:justify;\"><b>$entry{'number_in_topic'}. </b> $entry{'body'}
    </p><h5><div align=\"right\">
    (?, ?, ?$favchar)</div></h5>\n\n
    ";
  }


  
  if($entry{'id_ref'}!=$entry{'id'} && $entry{'id_ref'}>0){

    my %ref_entry=$eksi->entry($entry{'id_ref'});
    if ($ref_entry{'author'} eq "ssg"){ $favchar = "&#10017;";}
    #Add ref entry to html.
    $out.=  "<h3>g&uuml;n&uuml;n ilk entrysi:</h3><p class=\"bigref\" style=\"text-align:justify;\"><b>$ref_entry{'number_in_topic'}. </b> $ref_entry{'body'}</p><h5><div align=\"right\">(<a href=\"https://eksisozluk.com/biri/$ref_entry{'author'}\" "
    ."target=\"blank\" style=\"text-decoration:none; color:black\">$ref_entry{'author'}</a>, <a href=\"$ref_entry{'id_link'}\" target=\"blank\" style=\"text-decoration:none; "
    ."color:black\">$ref_entry{'date_print'}, $ref_entry{'fav_count'}$favchar</a>)</div></h5>\n\n";  

  }

  $out.="<hr>\n\n";
  $log.="\n";
}

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