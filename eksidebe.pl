#TODO: download images.
#TODO: make use of calibre command line tools.
#TODO: check if the entry is deleted.
  #if($numberintopic==""){$numberintopic="?";$datetoprint="?";$body="<i>bu entry silinmis.</i>";}
#TODO: read mail addresses from the database, do not hardcode them.

use DateTime; 
use MIME::Lite;     #Mail
use HTML::Entities;     #To decode html-encoded things like &#252;
use open qw/:std :utf8/;  #To get rid of Turkish character problems
#use warnings;


#Define some variables.

$folder_temp="./";
$file_in_list="$folder_temp"."inlist";
$file_out_html="$folder_temp"."out.html";
$link_stats="https://eksisozluk.com/istatistik/dunun-en-begenilen-entryleri";
$link_entry="https://eksisozluk.com/entry/";
$link_topic="https://eksisozluk.com/";

#Write some receivers before running.
#Remember to escape @ with \@.
#Sender to kindle must be approved at amazon.com
$sender_address=""; #will be unique for kindle receivers
$sender_replyto="";
$receivers_mail="";
$receivers_kindle=""; #will be replaced by arrays when database is used


$dt   = DateTime->now; 
$searchdate = DateTime->now->subtract(days=>1)->ymd;
$filedate   = DateTime->now->subtract(days=>1)->dmy;
$todaydate  = DateTime->now->dmy;
$datecontrolled="ok";
$searchstring = "\\?a=search\\&searchform.when.from=$searchdate";
$wget="wget --no-check-certificate -q -O";
print "### $dt ###\n"; #LOG



#Download, open then delete the debe list.

system("$wget $file_in_list $link_stats");
open FILE, "$file_in_list" or die;
@lines = <FILE>;
close FILE or die;
print "Started, "; #LOG



#Use regex to load debe entry details into arrays.
#ith entry of array will show ith entry of debe.

for($i=1,$pointer=0 ; $i<51 && $pointer<@lines ; $pointer++){
  if($lines[$pointer]=~/<span class="caption">(.*)\/#(\d+)<\/span>/){
    $entries_topic[$i]=$1;
    $entries_topic[$i]=decode_entities($entries_topic[$i]);
    $entries_id[$i]=$2;
    $i++;
  }
}

#Now to collect entries and create the html.
#We have several arrays about entries starting with "entries_". They are:
#id, topic, numberintopic, datepublished, datemodified, datetoprint, author, body.
#..and more arrays added for reference entry stuff. All the same as above except topic:
#entries_ref_id, entries_ref_numberintopic etc. Topic's the same, hence no entries_ref_topic.

$out="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n".
"<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"tr\"><head>\n".
"<meta http-equiv=\"Content-type\" content=\"text/html; charset=utf-8\" />\n".
"<meta http-equiv=\"Content-language\" content=\"tr\" />\n".
"<style>p.big {line-height:150%;text-align:justify;}</style>".
"<style>p.bigref {line-height:150%;margin-left:0.5cm;text-align:justify;}</style>".
"</head><body>\n\n\n".
"<h2>$filedate'&#252;n en be&#287;enilen entryleri</h2>".
"<br><hr>\n\n\n";

for($i=50;$i>0;$i--){
  system("$wget $folder_temp.entry$i $link_entry$entries_id[$i]");
  open FILE, "$folder_temp.entry$i" or die;
  @lines = <FILE>;
  close FILE or die;

  for($j=0;$j<@lines;$j++){
    if($lines[$j]=~/<a href="\/(.*)" itemprop="url">.*<\/a>[^<]/){$entries_topic4link[$i]=$1;} 
    $lines[$j]=~s/<sup class=\"ab\"><([^<]*)(data-query=\")([^>]*)\">\*<\/a><\/sup>/<$1$2$3\">\(* $3\)<\/a>/g;
    $lines[$j]=~s/href="\//target="_blank" href="https:\/\/www.eksisozluk.com\//g;
    $lines[$j]=~s/href="/style="text-decoration:none; color:black" href="/g;
    if($lines[$j]=~/<li id=".*" value="(\d+)">/){$entries_numberintopic[$i]=$1;}
    if($lines[$j]=~/"datePublished">(\d\d)\.(\d\d)\.(\d\d\d\d)(\s\d\d\:\d\d)/){$entries_datepublished[$i]=$1.".".$2.".".$3.$4;
    $datecontrol=$1."-".$2."-".$3; if($datecontrol ne $filedate && $datecontrol ne $todaydate){ $datecontrolled="fail";}
    if($lines[$j]=~/"son g.ncelleme zaman.">(.*)<\/time>/){$entries_datemodified[$i]=$1;}}
    if($lines[$j]=~/data-author="(.*)" data-flags/){$entries_author[$i]=$1;}
    if($lines[$j]=~/articleBody text">(.*)<\/div>/){$entries_body[$i]=$1;}
  }
  $entries_datetoprint[$i]=$entries_datepublished[$i];
  if($entries_datemodified[$i]){$entries_datetoprint[$i].=" ~ ".$entries_datemodified[$i];}

  $out.=  "<h3>$i. <a href=\"$link_topic$entries_topic4link[$i]\" target=\"blank\" style=\"text-decoration:none; color:black\">$entries_topic[$i]</a></h3><p class=\"big\"><b>$entries_numberintopic[$i]. </b> $entries_body[$i]"
  ."</p><h5><div align=\"right\">(<a href=\"https://www.eksisozluk.com/biri/$entries_author[$i]\" target=\"blank\" style=\"text-decoration:none; color:black\">$entries_author[$i]</a>, <a href=\"https://www.eksisozluk.com/entry/$entries_id[$i]\" "
  ."target=\"blank\" style=\"text-decoration:none; color:black\">$entries_datetoprint[$i]</a>)</div></h5>\n\n";  



  #Find first entry of that day and add a reference to it

  if($entries_numberintopic[$i]!=1){
    system("$wget $folder_temp.temptopic $link_topic$entries_topic4link[$i]$searchstring");
    open FILE2, "$folder_temp.temptopic" or die;
    @lines2 = <FILE2>;
    close FILE2 or die;
    
    for($j2=0;$j2<@lines2&&!$entries_ref_id[$i];$j2++){
      if($lines2[$j2]=~/<li id="li(.*)" value="(\d+)">/){$entries_ref_id[$i]=$1;$entries_ref_numberintopic[$i]=$2;
        if($entries_ref_id[$i]!=$entries_id[$i]){#if debe entry is NOT the first entry of that day
          for($j3=$j2;$j3<$j2+10;$j3++){#get the ref entry details
            $lines2[$j3]=~s/<sup class=\"ab\"><([^<]*)(data-query=\")([^>]*)\">\*<\/a><\/sup>/<$1$2$3\">\(* $3\)<\/a>/g;
            $lines2[$j3]=~s/href="\//target="_blank" href="https:\/\/www.eksisozluk.com\//g;
            $lines2[$j3]=~s/href="/style="text-decoration:none; color:black" href="/g;
            if($lines2[$j3]=~/"datePublished">(\d\d\.\d\d\.\d\d\d\d)(\s\d\d\:\d\d)/){$entries_ref_datepublished[$i]=$1.$2;
            if($lines2[$j3]=~/"son g.ncelleme zaman.">(.*)<\/time>/){$entries_ref_datemodified[$i]=$1;}}
            if($lines2[$j3]=~/data-author="(.*)" data-flags/){$entries_ref_author[$i]=$1;}
            if($lines2[$j3]=~/articleBody text">(.*)<\/div>/){$entries_ref_body[$i]=$1;}  
            $entries_ref_datetoprint[$i]=$entries_ref_datepublished[$i];  
          }
          if($entries_ref_datemodified[$i]){$entries_ref_datetoprint[$i].=" ~ ".$entries_ref_datemodified[$i];}
          
          $out.=  "<p class=\"bigref\"><b>>>$entries_ref_numberintopic[$i]. </b> $entries_ref_body[$i]</p><h5><div align=\"right\">(<a href=\"https://www.eksisozluk.com/biri/$entries_ref_author[$i]\" "
          ."target=\"blank\" style=\"text-decoration:none; color:black\">$entries_ref_author[$i]</a>, <a href=\"https://www.eksisozluk.com/entry/$entries_ref_id[$i]\" target=\"blank\" style=\"text-decoration:none; "
          ."color:black\">$entries_ref_datetoprint[$i]</a>)</div></h5>\n\n";  
  }}}}    $out.="<hr>\n\n";
} 

#Delete temporary files.
system("mv $file_in_list $folder_temp.entry* $folder_temp.temptopic /tmp");

$out.="<h3>fin.</h3></body>";
open OUT, ">$file_out_html" or die; print OUT $out; close OUT;
print "merged, ";#LOG


if($datecontrolled eq "ok"){ #Send only if list is updated

  #Send to kindle readers.

my $msg = MIME::Lite->new(
     From    => "$sender_address",
     To      => "$receivers_kindle",
     'Reply-to' => "$sender_replyto",
     Subject => "$filedate",
     Type    => 'multipart/mixed',
 );

 $msg->attach(
     Type     => 'application/html',
     Path     => "$file_out_html",
     Filename => "$filedate".".html",
     Disposition => 'attachment'

 );

 $msg->send or die;



#Send the created html file to email readers.

my $msg = MIME::Lite->new(
    From    => "$sender_address",
    Bcc      => "$receivers_mail",
    Subject => "$filedate",
    Type    => 'multipart/mixed',
);

$msg->attach(
    Type     => "application/html",
    Path     => "$file_out_html",
    Filename => "$filedate".".html",

);

$msg->send or die;
  print "delivered.\n\n" #log

}else{
  
  print "error! 50:$entries_id[50] ok:$datecontrolled\n\n"

}

system("mv $file_out_html /tmp");
