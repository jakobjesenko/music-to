module main

import vweb
import os
import json

struct App {
	vweb.Context
mut:
	shared_data shared SharedData
}

enum SongStatus {
	missing
	present
	adjusted
	error
}

pub struct SongData {
mut:
	id int
	artist string
	title string
	url string
	status SongStatus
}

pub struct SharedData {
mut:
	song_list []SongData
	list_file string
}

fn main() {
	os.rm('./download.log') or {
		eprintln('Cannot remove downlaod.log')
	}
	vweb.run_at(new_app(), vweb.RunParams{
		port: 8081
	}) or { panic(err) }
}

fn new_app() &App {
	mut app := &App{}
	// makes all static files available.
	app.mount_static_folder_at(os.resource_abs_path('./src'), '/')

	default_file := './songs.json'
	lock app.shared_data {
		app.shared_data.list_file = default_file
		app.shared_data.song_list = load_list(default_file)
	}

	return app
}

@['/'; post; get]
pub fn (mut app App) page_home() vweb.Result {
	if app.req.method == .post{
		temp := SongData{
			artist: app.form['artist'],
			title: app.form['song-title'],
			url: app.form['song-url']
			status: .missing
		}
		lock app.shared_data {
			app.shared_data.song_list << temp
		}
	}
	song_list := app.shared_data.song_list
	file_list := ['songs', 'slon']
	return $vweb.html()
}

@['/run-jobs'; post]
pub fn (mut app App) run_jobs() vweb.Result {
	app.process_jobs()
	return app.text('OK')
}

@['/write-list']
pub fn (mut app App) page_writelist() vweb.Result {
	lock app.shared_data {
		temp := app.shared_data.song_list.clone()
		os.write_file(app.shared_data.list_file, json.encode_pretty(temp)) or { 
			app.set_status(500, 'Writing the list failed.')
			app.text('Write Failed')
		}
	}
	return app.text('Write Successful')
}