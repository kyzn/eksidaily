eksiweekly
========
Download, merge & deliver last week's top 20 posts from eksisozluk.com


Saves merged file at `/tmp/{year}-{week_of_year}.html`.


    perl eksi.pl --send-email --sleep 10 --from=your@email.com --to=one@subscriber.com --to=two@subscriber.com

 - Add `FROM:` and `TO:` addresses with command line arguments. You can add more than one receivers.
 - If you want to deliver emails, make sure to use `--send-email` (otherwise it will not send).
 - Adjust politeness delay (for web crawl) with `--sleep`. It's set to 5 seconds by default.