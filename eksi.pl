package EksiWeekly;
our $VERSION='2.24';

use warnings;
use strict;

use WWW::Eksi 0.24;
use DateTime;
use File::Slurp;
use Getopt::Long;
use MIME::Lite;

=head1 NAME

EksiWeekly - Deliver Eksisozluk GHEBE

=head1 DESCRIPTION

Download, merge & deliver last week's top 20 posts from eksisozluk.com.

Saves merged file at `/tmp/{year}-{week_of_year}.html`.

=head1 SYNOPSIS

    perl eksi.pl --send-email --sleep 10 --from=your@email.com --to=one@subscriber.com --to=two@subscriber.com

 - Add `FROM:` and `TO:` addresses with command line arguments. You can add more than one receivers.
 - If you want to deliver emails, make sure to use `--send-email` (otherwise it will not send).
 - Adjust politeness delay (for web crawl) with `--sleep`. It's set to 5 seconds by default.

=cut

my @to_email;
my $from_email;
my $politeness_delay = 5;
my $send_email       = 0;

GetOptions(
  "to=s@"      => \@to_email,
  "from=s"     => \$from_email,
  "sleep=i"    => \$politeness_delay,
  "send-email" => \$send_email,
);

my $e        = WWW::Eksi->new;
my @ghebe    = $e->ghebe($politeness_delay);

my $dow      = DateTime->now->day_of_week;
my $monday   = DateTime->now->subtract(days=>($dow-1));
my $year     = $monday->year;
my $week     = $monday->week_number;
$week        = "0$week" if $week=~/^\d$/;
my $filename = "$year-$week";
my $filepath = "/tmp/$filename.html";


#Start writing to html.
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
<h2>eksiweekly ${year}-${week}</h2>
<br><hr>\n\n\n";


# Write entries to html
my $i=scalar(@ghebe)+1;
foreach my $entry (reverse @ghebe){
  $i--;
  $out.=  "
  <h3>$i. <a href=\"$entry->{topic_url}\" target=\"blank\" style=\"text-decoration:none; color:black\">
  $entry->{topic_title}</a></h3><p class=\"big\" style=\"text-align:justify;\">$entry->{body_processed}
  </p><h5><div align=\"right\">
  (<a href=\"$entry->{author_url}\" target=\"blank\" style=\"text-decoration:none; color:black\">$entry->{author_name}</a>, <a href=\"$entry->{entry_url}\" target=\"blank\" style=\"text-decoration:none; color:black\">$entry->{time_as_seen}, $entry->{fav_count}&#9734;</a>)</div></h5>\n\n<hr>\n\n";
}


# Finish up html & write out
$out.="</body>";
write_file($filepath,$out);


# Send to email subscribers.
if( $send_email ){
  foreach my $subscriber (@to_email){
    my $msg_mail = MIME::Lite->new(
      From    => $from_email,
      To      => $subscriber,
      Subject => "eksiweekly $filename",
      Type    => 'multipart/mixed',
    );

    $msg_mail->attach(
      Type     => 'application/html',
      Path     => "$filepath",
      Filename => "$filename.html",
    );

    $msg_mail->send or next "Error on sending email to $subscriber";
  }
}
