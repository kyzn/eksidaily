# NAME

eksimail - Deliver list of eksisozluk entries

# DESCRIPTION

Download, merge & deliver lists of entries from eksisozluk.com

Install `sendmail` if you are not going to use SendGrid Web API:

    sudo apt-get install sendmail

Install `cpanm` and `carton`

    curl -L http://cpanmin.us | perl - App::cpanminus
    cpanm Carton

This will install dependencies into local/

    carton install

# SYNOPSIS

    carton exec ./eksimail --list=daily --from=you@a.com --to=one@b.com --to=two@c.com

or

    perl -I./local/lib/perl5 ./eksimail --list=daily --from=you@a.com --to=one@b.com --to=two@c.com

- Add `--from` and `--to` addresses with command line arguments. You can add more than one receivers.
- If you don't add a `--from` an email won't be sent.
- If you want to send via SendGrid Web API, provide `--sendgrid-api-key`. Otherwise `sendmail` will be used.
- Adjust politeness delay (for web crawl) with `--sleep`. It's set to 5 seconds by default.

# Arguments

## list

There are two choices.

- `weekly`: Top 20 posts from last week, published by eksisozluk.com. Output is saved at `/tmp/{year}-{week_of_year}.html`.
- `daily`: Most popular entries from yesterday, published by eksisozluk.com. Output is saved at `/tmp/{ymd}.html`.

## sendgrid-api-key

Provide SendGrid Web API key to use SendGrid. Otherwise `sendmail` will be used.

## sleep

Amount of seconds to sleep between each request. This is passed to `WWW::Eksi` as politeness delay argument. Defaults to 5 if not provided.

## from

Email address that email will be sent from. If it's not set, an email won't be sent.

## to

Email address to send email to. This argument can be used more than once (see sample above)

# LICENSE

MIT.
