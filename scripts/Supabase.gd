extends Node

const SUPABASE_URL = 'https://ctmdnopvlvrdhcxbtoyd.supabase.co'
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWRub3B2bHZyZGhjeGJ0b3lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3NTU5MjgsImV4cCI6MjA5MDMzMTkyOH0.SULc1HG4SZ7AGE-CxaOqCleBJXu1a4epnmy8TZrN_io'

signal score_submitted
signal scores_fetched(scores: Array)


func submit_score(player_name: String, score: int, level: int) -> void:
	if OS.get_name() == "Web":
		var body_str = JSON.stringify({"name": player_name, "score": score, "level": level})
		var js_code = """
			fetch('https://ctmdnopvlvrdhcxbtoyd.supabase.co/rest/v1/scores', {
				method: 'POST',
				headers: {
					'apikey': '""" + SUPABASE_KEY + """',
					'Authorization': 'Bearer """ + SUPABASE_KEY + """',
					'Content-Type': 'application/json',
					'Prefer': 'return=minimal'
				},
				body: '""" + body_str.replace("'", "\\'") + """'
			})
			.then(r => { window._supabase_submit_done = true; })
			.catch(err => { console.error('Submit error:', err); window._supabase_submit_done = true; });
			window._supabase_submit_done = false;
		"""
		JavaScriptBridge.eval(js_code)
		await get_tree().create_timer(2.0).timeout
		score_submitted.emit()
	else:
		_submit_score_native(player_name, score, level)


func _submit_score_native(player_name: String, score: int, level: int) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		http.queue_free()
		if code == 201:
			score_submitted.emit()
		else:
			print('Submit error: ', code)
	)
	var body = JSON.stringify({'name': player_name, 'score': score, 'level': level})
	var headers = [
		'Content-Type: application/json',
		'apikey: ' + SUPABASE_KEY,
		'Authorization: Bearer ' + SUPABASE_KEY,
		'Prefer: return=minimal'
	]
	http.request(SUPABASE_URL + '/rest/v1/scores', headers, HTTPClient.METHOD_POST, body)


func submit_score_with_dps(player_name: String, score: int, level: int, dps: float) -> void:
	if OS.get_name() == "Web":
		var body_str = JSON.stringify({"name": player_name, "score": score, "level": level, "dps": dps})
		var js_code = """
			fetch('https://ctmdnopvlvrdhcxbtoyd.supabase.co/rest/v1/scores', {
				method: 'POST',
				headers: {
					'apikey': '""" + SUPABASE_KEY + """',
					'Authorization': 'Bearer """ + SUPABASE_KEY + """',
					'Content-Type': 'application/json',
					'Prefer': 'return=minimal'
				},
				body: '""" + body_str.replace("'", "\\'") + """'
			})
			.then(r => { window._supabase_submit_done = true; })
			.catch(err => { console.error('Submit error:', err); window._supabase_submit_done = true; });
			window._supabase_submit_done = false;
		"""
		JavaScriptBridge.eval(js_code)
		await get_tree().create_timer(2.0).timeout
		score_submitted.emit()
	else:
		_submit_score_with_dps_native(player_name, score, level, dps)


func _submit_score_with_dps_native(player_name: String, score: int, level: int, dps: float) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		http.queue_free()
		if code == 201:
			score_submitted.emit()
		else:
			print('Submit error: ', code)
	)
	var body = JSON.stringify({'name': player_name, 'score': score, 'level': level, 'dps': dps})
	var headers = [
		'Content-Type: application/json',
		'apikey: ' + SUPABASE_KEY,
		'Authorization: Bearer ' + SUPABASE_KEY,
		'Prefer: return=minimal'
	]
	http.request(SUPABASE_URL + '/rest/v1/scores', headers, HTTPClient.METHOD_POST, body)


func fetch_scores() -> void:
	if OS.get_name() == "Web":
		var js_code = """
			fetch('https://ctmdnopvlvrdhcxbtoyd.supabase.co/rest/v1/scores?select=name,score,level,created_at&order=score.desc&limit=10', {
				method: 'GET',
				headers: {
					'apikey': '""" + SUPABASE_KEY + """',
					'Authorization': 'Bearer """ + SUPABASE_KEY + """',
					'Accept': 'application/json'
				}
			})
			.then(r => r.json())
			.then(data => {
				window._supabase_scores = JSON.stringify(data);
				window._supabase_scores_ready = true;
			})
			.catch(err => {
				console.error('Supabase fetch error:', err);
				window._supabase_scores = '[]';
				window._supabase_scores_ready = true;
			});
			window._supabase_scores_ready = false;
		"""
		JavaScriptBridge.eval(js_code)
		_poll_for_scores()
	else:
		_fetch_scores_native()


func _poll_for_scores() -> void:
	var attempts = 0
	while attempts < 50:
		await get_tree().create_timer(0.2).timeout
		var ready = JavaScriptBridge.eval("window._supabase_scores_ready === true")
		if ready:
			var json_str = JavaScriptBridge.eval("window._supabase_scores")
			print("JS fetch result: ", json_str)
			var parsed = JSON.parse_string(str(json_str))
			if parsed != null and parsed is Array:
				scores_fetched.emit(parsed)
			else:
				print("Parse failed: ", json_str)
				scores_fetched.emit([])
			return
		attempts += 1
	print("Supabase fetch timed out")
	scores_fetched.emit([])


func _fetch_scores_native() -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		await get_tree().process_frame
		var text = body.get_string_from_utf8()
		print('Native fetch code: ', code, ' body: ', text)
		if code == 200:
			var json = JSON.parse_string(text)
			if json != null and json is Array:
				scores_fetched.emit(json)
				return
		scores_fetched.emit([])
		http.queue_free()
	)
	var headers = [
		'apikey: ' + SUPABASE_KEY,
		'Authorization: Bearer ' + SUPABASE_KEY,
		'Accept: application/json',
		'Accept-Encoding: identity'
	]
	http.request(SUPABASE_URL + '/rest/v1/scores?select=name,score,level,created_at&order=score.desc&limit=10', headers, HTTPClient.METHOD_GET)
