import os
import regex


pub fn download_audio(song SongData)! {
	output := os.execute('yt-dlp -f "ba" -x --audio-format mp3 -o "songs/${song.title} by ${song.artist}" ${song.url}')
	//output := os.execute('echo "songs/${song.title} by ${song.artist}"')
	if output.exit_code == 0 {
		println('Success: ${output.output}')
		return
	}
	return error('${output.output}')
}

pub fn (mut app App) download_all(mut song_list []SongData, mut logfile &os.File)! {
	for mut song in song_list {
		// to be removed when file is updated.
		if song.artist.len == 0{
			return
		}
		//
		if song.status != .present {
			download_audio(song) or {
				logfile.writeln('${song}\n${err.str()}')!
				song.status = .error
				continue
			}
			song.status = .present
		}
	}
	lock app.song_list {
		app.song_list = song_list.clone()
	}
}

pub fn get_volume(filename string) !f32 {
	output := os.execute('ffmpeg -i "${filename}" -hide_banner -af volumedetect -f null /dev/null')
	mut re := regex.regex_opt(r'.*mean_volume: (-?\d+\.?\d*).*') or { return error('Cannot create regex') }
	re.match_string(output.output)
	if re.groups.len < 2 {
		return error('Cannot read volume of file: ${filename}')
	}
	out := output.output[re.groups[0]..re.groups[1]].f32()
	if out != 0 {
		return out
	} else {
		return error('Cannot read volume of file: ${filename}')
	}

}

pub fn normalize_file(filename string, target f32)! {
	volume := get_volume(filename)!
	if target - 1 < volume && volume < target + 1 {
		return
	}
	factor := target - volume
	os.mv(filename, filename.replace('.mp3', '.tmp'))!
	os.execute('ffmpeg -i "${filename.replace('.mp3', '.tmp')}" -filter:a volume=${factor}dB -y "${filename}"')
	os.rm(filename.replace('.mp3', '.tmp'))!
}

pub fn (mut app App) process_jobs(){
	mut logfile := os.open_append('download.log') or {
		eprintln('Cannot not open log file.')
		return
	}
	defer {
		logfile.close()
	}

	mut song_list := []SongData{}
	rlock app.song_list {
		song_list = app.song_list.clone()
	}
	app.download_all(mut song_list, mut logfile) or {
		eprintln(err)
		return
	}

}