import os
import json


pub fn download_audio(song SongData)! {
	//output := os.execute('yt-dlp -f "ba" -x --audio-format mp3 -o "songs/${song.title} by ${song.artist}" ${song.url}')
	output := os.execute('echo "songs/${song.title} by ${song.artist}"')
	if output.exit_code == 0 {
		println('Success: ${output.output}')
		return
	}
	return error('${output.output}')
}

pub fn download_all(mut song_list []SongData, mut logfile &os.File)! {
	for mut song in song_list {
		if song.status != .present {
			download_audio(song) or {
				logfile.writeln('${song}\n${err.str()}')!
				song.status = .error
				continue
			}
			song.status = .present
		}
	}
	os.write_file('./songs.json', json.encode_pretty(song_list)) or {
		logfile.writeln('Cannot write to songs.json')!
		return err
	}
}

pub fn process_jobs(){
	mut logfile := os.open_append('download.log') or {
		eprintln('Cannot not open log file.')
		return
	}
	defer {
		logfile.close()
	}
	mut song_list := json.decode([]SongData, os.read_file('songs.json') or {
		eprintln('Cannot read from songs.json')
		return
	}) or {
		eprintln('Cannot parse songs.json')
		return
	}
	download_all(mut song_list, mut logfile) or {
		eprintln(err)
		return
	}

}