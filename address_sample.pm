#address.pm is to be used temporarily. This Will be replaced by a database call.
#Be careful for quotes. If you use " ", then you have to escape @ by \.
#Example:
#to_email_all => "test\@example.com",
#You can also use ' ' with no escape. Example:
#to_email_all => 'test@example.com',

#You can edit all a@a.a addresses accordingly. 
#Just make sure to RENAME the file to address.pm and you'll be ok.

package address;
require Exporter;
use strict;

our @ISA                = qw(Exporter);
our @EXPORT             = qw(getAddress); 

my %Address = ( 

	#Mails will be sent from $from. You need to set some address that you have permission to
	#You'd better set some address from your server. Otherwise your mail will end up in junk.
	from         => 'a@a.a',

	#You will need an actual working address here, otherwise kindle mails may not be delivered.
	reply_to	  => 'a@a.a',

	#Email recipients. All and dev can be different sets.
	to_email_all => 'a@a.a,
					 b@a.a',
	to_email_dev => 'a@a.a',

	#Kindle recipients. All and dev can be different sets.
	to_kindle_all=> 'a@a.a,
					 b@a.a',
	to_kindle_dev=> 'a@a.a',

    			   );

sub getAddress {
 return  %Address;
 }

1;