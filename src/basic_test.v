module main

fn test_get_volume() {
	normalize_file('songs/A Cruel Angel\'s Thesis [Neon Genesis Evangelion] by Yoko Takahashi.mp3', -20.0) or { return }
	println(get_volume('songs/A Cruel Angel\'s Thesis [Neon Genesis Evangelion] by Yoko Takahashi.mp3') or { return })
}