import os
import regex
import json

pub fn load_list(file string) []SongData {
	return json.decode([]SongData, os.read_file(file) or {''}) or {[]}
}

pub fn make_filename(song SongData, extension string) string {
	return 'songs/${song.title} by ${song.artist}${extension}'
}

pub fn download_audio(song SongData)! {
	output := os.execute('yt-dlp -f "ba" -x --audio-format mp3 -o "${make_filename(song, '')}" ${song.url}')
	//output := os.execute('echo "${make_filename(song, '')}"')
	if output.exit_code == 0 {
		println('Success: ${output.output}')
		return
	}
	return error('${output.output}')
}

pub fn download_all(mut song_list []SongData, mut logfile &os.File)! {
	for mut song in song_list {
		if song.status == .missing || song.status == .error {
			download_audio(song) or {
				logfile.writeln('${song}\n${err.str()}')!
				song.status = .error
				continue
			}
			song.status = .present
		}
	}
}

pub fn get_volume(filename string) !f32 {
	output := os.execute('ffmpeg -i "${filename}" -hide_banner -af volumedetect -f null /dev/null')
	if output.exit_code != 0 {
		return error (output.output)
	}
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

pub fn normalize_dir(mut song_list []SongData, mut logfile &os.File){
	for mut song in song_list {
		if song.status != .present {
			continue
		}
		normalize_file(make_filename(song, '.mp3'), -20) or {
			logfile.writeln('${song}\n${err.str()}') or {
				eprintln(err)
				continue
			}
			continue
		}
		song.status = .adjusted
	}
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
	rlock app.shared_data {
		song_list = app.shared_data.song_list.clone()
	}
	download_all(mut song_list, mut logfile) or {
		eprintln(err)
		return
	}
	normalize_dir(mut song_list, mut logfile)
	lock app.shared_data {
		app.shared_data.song_list = song_list.clone()
	}
}