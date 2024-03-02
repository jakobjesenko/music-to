module main

import vweb
import os
import json

struct App {
	vweb.Context
mut:
	song_list shared []SongData
}

enum SongStatus {
	missing
	present
	error
}

pub struct SongData {
mut:
	artist string
	title string
	url string
	status SongStatus
}

fn main() {
	vweb.run_at(new_app(), vweb.RunParams{
		port: 8081
	}) or { panic(err) }
}

fn new_app() &App {
	mut app := &App{}
	// makes all static files available.
	app.mount_static_folder_at(os.resource_abs_path('./src'), '/')

	lock app.song_list {
		app.song_list = json.decode([]SongData, os.read_file('./songs.json') or {''}) or {[]}
	}

	return app
}

@['/']
pub fn (mut app App) page_home() vweb.Result {
	// all this constants can be accessed by src/templates/page/home.html file.
	page_title := 'V is the new V'

	song_list := app.song_list

	// $vweb.html() in `<folder>_<name> vweb.Result ()` like this
	// render the `<name>.html` in folder `./templates/<folder>`
	return $vweb.html()
}

/* @['/add-song']
pub fn (mut app App) page_addsong() vweb.Result {
	return $vweb.html()
} */

@['/add-song'; post; get]
pub fn (mut app App) page_addsong() vweb.Result {
	if app.req.method == .post{
		temp := SongData{
			artist: app.form['artist'],
			title: app.form['song-title'],
			url: app.form['song-url']
			status: .missing
		}
		println(temp)
		lock app.song_list {
			app.song_list << temp
		}
	}
	song_list := app.song_list
	return $vweb.html()
}

@['/run-jobs'; post]
pub fn (mut app App) run_jobs() vweb.Result {
	lock app.song_list {
		temp := app.song_list.clone()
		os.write_file('./songs.json', json.encode_pretty(temp)) or { 
			app.set_status(500, '')
			return app.text('NOK')
		}
	}
	process_jobs()
	return app.text('OK')
}

@['/write-list']
pub fn (mut app App) page_writelist() vweb.Result {
	lock app.song_list {
		temp := app.song_list.clone()
		os.write_file('./songs.json', json.encode_pretty(temp)) or { return $vweb.html() }
	}
	return $vweb.html()
}