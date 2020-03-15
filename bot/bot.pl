#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use LWP::UserAgent;
#use File::Slurp;

sub in_array
{
	my ($value, @list) = @_;

	foreach my $val (@list)
	{
		if($val eq $value)
		{
			return 1;
		}
	}

	return 0;
}

#my $text = read_file('bot.conf');
my $text = do {
   open(my $json_fh, "<:encoding(UTF-8)", 'bot.conf')
      or die("Can't open bot.conf: $!\n");
   local $/;
   <$json_fh>
};

print "file:\n\n".$text."\n\n";

my $config = decode_json($text);
print "config:\n\n".encode_json($config)."\n\n";

sub http_save
{
	my ($url, $file) = @_;

	my $ua = LWP::UserAgent->new(timeout => 30);

	my $response = $ua->get($url, ':content_file'  => $file);

	if($response->is_success)
	{
	    print "OK:".$file."\n";
	}
	else
	{
	    print $response->status_line;
	}

	return 0;
}

sub get_json
{
	my ($url) = @_;

	my $ua = LWP::UserAgent->new(timeout => 30);

	my $response = $ua->get($url);

	if($response->is_success)
	{
	    print $response->decoded_content."\n";
	    return decode_json($response->decoded_content);
	}
	else
	{
	    print $response->status_line;
	}

	return 0;
}

sub post_json
{
	my ($url, $data) = @_;

	my $ua = LWP::UserAgent->new(timeout => 30);

	my $response = $ua->post($url, $data);

	if($response->is_success)
	{
	    print $response->decoded_content."\n";
	    return decode_json($response->decoded_content);
	}
	else
	{
	    print $response->status_line;
	}

	return 0;
}

if($#ARGV >= 0 && $ARGV[0] eq '--boot')
{
	foreach my $chat_id ( @{ $config->{admins_chats} })
	{
		post_json(
			'https://api.telegram.org/bot'.$config->{bot_token}.'/sendMessage',
			{
				chat_id => $chat_id,
				text => 'System was power on'
			}
		);
	}
}

my $data = post_json(
	'https://api.telegram.org/bot'.$config->{bot_token}.'/getUpdates',
	{
		offset => $config->{offset}
	}
);

if($data && $data->{ok})
{
	foreach my $update (@{ $data->{result} })
	{
		if(!$update->{update_id})
		{
			next;
		}

		$config->{offset} = $update->{update_id} + 1;

		if(in_array($update->{message}{from}{id}, @{$config->{allowed_users}}))
		{
			if($update->{message}{text} && $update->{message}{text} eq '/poweroff')
			{
				post_json(
					'https://api.telegram.org/bot'.$config->{bot_token}.'/sendMessage',
					{
						chat_id => $update->{message}{chat}{id},
						text => 'System go down'
					}
				);
				#system('sudo /usr/bin/shutdown -P +1');
			}
			if($update->{message}{document})
			{
				if($update->{message}{document}{file_name} !~ /\.torrent$/)
				{
					print "Accept only .torrent files!\n";
				}
				else
				{
					my $response = get_json('https://api.telegram.org/bot'.$config->{bot_token}.'/getFile?file_id='.$update->{message}{document}{file_id});
					if($response && $response->{result}{file_path})
					{
						my $filename = $update->{message}{document}{file_name};
						$filename =~ s/\.torrent$//;
						$filename = $filename.'['.$update->{message}{document}{file_unique_id}.'].torrent';
						$filename =~ s/[^a-zA-Z0-9_\-. \[\]\(\)]//ig;
						$filename =~ s/^[_\-. ]+//ig;
						http_save('https://api.telegram.org/file/bot'.$config->{bot_token}.'/'.$response->{result}{file_path}, $config->{download_path}.'/'.$filename);
						post_json(
							'https://api.telegram.org/bot'.$config->{bot_token}.'/sendMessage',
							{
								chat_id => $update->{message}{chat}{id},
								text => 'Torrent was added: '.$filename
							}
						);
					}
				}
			}
		}
		else
		{
			foreach my $chat_id ( @{ $config->{admins_chats} })
			{
				post_json(
					'https://api.telegram.org/bot'.$config->{bot_token}.'/sendMessage',
					{
						chat_id => $chat_id,
						text => 'New unknown user: '.$update->{message}{from}{id}
					}
				);
			}
		}
	}
}

open(CONF, '>', 'bot.conf');

#print(CONF encode_json($config));
print(CONF JSON::PP->new->pretty->encode($config));

close(CONF);
