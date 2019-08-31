eksi-mail
========
Download, merge & deliver lists of entries from eksisozluk.com

# Install Dependencies

    cpanm WWW::Eksi DateTime File::Slurp Getopt::Long MIME::Lite

# Sample Run

    perl ./eksi-mail --list=weekly --send-email --sleep 10 --from=your@email.com --to=one@subscriber.com --to=two@subscriber.com


# Arguments

## list

  - `weekly`: Top 20 posts from last week, published by eksisozluk.com. Output is saved at `/tmp/{year}-{week_of_year}.html`.
  - `daily`: Most popular entries from yesterday, published by eksisozluk.com. Output is saved at `/tmp/{ymd}.html`.

## send-email

  - Does not send any email until this flag is set

## sleep

  - Seconds to sleep between each download. This is passed to [WWW::Eksi](https://github.com/kyzn/WWW-Eksi) as politeness delay argument. Defaults to 5 if not provided.

## from

  - Email address that email will be sent from

## to

  - Email address to send email to. This argument can be used more than once (see sample above)
