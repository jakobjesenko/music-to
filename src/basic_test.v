module main
import os
import json

fn test_get_volume() {
	temp := os.read_file('./songs.json') or {return}
	mut song_list :=json.decode([]SongData, temp) or {return}
	s := song_list[38]
	println(s)
	normalize_file(make_filename(s, '.mp3'), -20.0) or {
		eprintln(err)
	}
}