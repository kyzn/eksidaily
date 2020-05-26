# NAME

eksimail - Deliver list of eksisozluk entries

# DESCRIPTION

Download, merge & deliver lists of entries from eksisozluk.com

Install dependencies as follows:

    sudo apt-get install sendmail
    cpanm WWW::Eksi DateTime File::Slurp Getopt::Long MIME::Lite

# SYNOPSIS

    perl ./eksimail --list=daily --send-email --from=you@a.com --to=one@b.com --to=two@c.com

- Add `FROM:` and `TO:` addresses with command line arguments. You can add more than one receivers.
- If you want to deliver emails, make sure to use `--send-email` (otherwise it will not send).
- Adjust politeness delay (for web crawl) with `--sleep`. It's set to 5 seconds by default.

# Arguments

## list

There are two choices.

- `weekly`: Top 20 posts from last week, published by eksisozluk.com. Output is saved at `/tmp/{year}-{week_of_year}.html`.
- `daily`: Most popular entries from yesterday, published by eksisozluk.com. Output is saved at `/tmp/{ymd}.html`.

## send-email

Does not send any email until this flag is set

## sleep

Amount of seconds to sleep between each request. This is passed to `WWW::Eksi` as politeness delay argument. Defaults to 5 if not provided.

## from

Email address that email will be sent from

## to

Email address to send email to. This argument can be used more than once (see sample above)

# LICENSE

MIT.
