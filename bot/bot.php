<?php
/*
    xbmc_bot - Telegram bot
    Copyright (C) 2019 Dmitry V. Zimin

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

if(!file_exists('inc.config.php'))
{
	exit;
}

require_once("inc.config.php");

function http($url, $data)
{
	error_log('S: '.$data."\r\n\r\n", 3, "error.log");

	$curl = curl_init();

	curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($curl, CURLOPT_HEADER, false);
	curl_setopt($curl, CURLOPT_POST, true);
	curl_setopt($curl, CURLOPT_URL, $url);
	curl_setopt($curl, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
	curl_setopt($curl, CURLOPT_POSTFIELDS, $data);

	$response = curl_exec($curl);
	curl_close($curl);

	error_log('A: '.$response."\r\n\r\n", 3, "error.log");

	return $response;
}

function http_save($url, $path)
{
	$fp = fopen($path, 'w');
	$curl = curl_init();

	curl_setopt($curl, CURLOPT_URL, $url);
	curl_setopt($curl, CURLOPT_FILE, $fp); 

	curl_exec($curl);
	curl_close($curl);
	fclose($fp);
}

	error_reporting(E_ALL);
	define("Z_PROTECTED", "YES");
	
	if(BOOT)
	{
		foreach(BOT_ADMIN_CHATS as &$chat_id)
		{
			$response = array(
				'method' => 'sendMessage',
				'chat_id' => $chat_id,
				'text' => 'System was power on',
				'parse_mode' => 'Markdown'
			);

			http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
		}
	}

	$response = array(
		'offset' => $offset
	);

	$data = json_decode(http(API_URL.'getUpdates', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)), true);

	if($data && $data['ok'])
	{
		foreach($data['result'] as &$update)
		{
			if(empty($update['update_id']))
			{
				continue;
			}

			$offset = $update_id + 1;
			
			if(in_array($update['message']['from']['id', BOT_ALLOWED_USERS))
			{
				if(!empty($update['message']['text']) && $update['message']['text'] == '/poweroff')
				{
					$response = array(
						'method' => 'sendMessage',
						'chat_id' => $chat_id,
						'text' => 'System go down',
						'parse_mode' => 'Markdown'
					);

					http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
					
					system('sudo /usr/bin/shutdown -P +1');
				}
				elseif(!empty($update['message']['text']) && $update['message']['text'] == '/ping')
				{
					$response = array(
						'method' => 'sendMessage',
						'chat_id' => $chat_id,
						'text' => 'OK',
						'parse_mode' => 'Markdown'
					);

					http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
				}
				elseif(!empty($update['message']['text']) && preg_match('/^magnet:[^\\"]+$/', $update['message']['text']))
				{
					system('transmission-remote -a "'.$update['message']['text'].'"');
					
					$response = array(
						'method' => 'sendMessage',
						'chat_id' => $chat_id,
						'text' => 'Torrent added',
						'parse_mode' => 'Markdown'
					);

					http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
				}
				elseif($update['message']['document'])
				{
					if(!preg_match('/\.torrent$/', $update['message']['document']['file_name']))
					{
						$response = array(
							'method' => 'sendMessage',
							'chat_id' => $chat_id,
							'text' => 'Accept only .torrent files!',
							'parse_mode' => 'Markdown'
						);

						http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
					}
					else
					{
						$response = array(
							'file_id' => update['message']['document']['file_id']
						);
						
						$response = json_decode(http(API_URL.'getFile', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)), true);

						if($response && $response['result']['file_path'])
						{
							$filename = $update['message']['document']['file_name'];
							preg_replace('/\.torrent$/', '', $filename);
							$filename = $filename.'['.$update['message']['document']['file_unique_id'].'].torrent';
							preg_replace('/[^a-zA-Z0-9_\-. \[\]\(\)]/i', '', $filename);
							preg_replace('/^[_\-. ]+/i', '', $filename);

							http_save(API_URL.'/'.$response['result']['file_path'], DOWNLOAD_PATH.'/'.$filename);

							$response = array(
								'method' => 'sendMessage',
								'chat_id' => $chat_id,
								'text' => 'Torrent was added: '.$filename,
								'parse_mode' => 'Markdown'
							);

							http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
						}
					}
				}
				else
				{
					$response = array(
						'method' => 'sendMessage',
						'chat_id' => $chat_id,
						'text' => 'Unknown command',
						'parse_mode' => 'Markdown'
					);

					http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
				}
			}
			else
			{
				foreach(BOT_ADMIN_CHATS as &$chat_id)
				{
					$response = array(
						'method' => 'sendMessage',
						'chat_id' => $chat_id,
						'text' => 	'New unknown user'."\n".
									'JSON: <pre>'.json_encode($update, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE).'</pre>'."\n",
						'parse_mode' => 'HTML'
					);

					http(API_URL.'sendMessage', json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
				}
			}
		}
	}
	
/*
header("Content-Type: application/json");

$response = array(
	'method' => 'sendMessage',
	'chat_id' => $request['message']['chat']['id'],
	'parse_mode' => 'Markdown',
	'text' => "\xE2\x9A\xA0 Error:\n```".json_encode($request, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)."\n```\n\nKnown commands:\n\xE2\x9E\xA1 /start"
);

echo json_encode($response);
*/