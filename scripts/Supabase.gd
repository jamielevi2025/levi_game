extends Node

const SUPABASE_URL = 'https://ctmdnopvlvrdhcxbtoyd.supabase.co'
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWRub3B2bHZyZGhjeGJ0b3lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3NTU5MjgsImV4cCI6MjA5MDMzMTkyOH0.SULc1HG4SZ7AGE-CxaOqCleBJXu1a4epnmy8TZrN_io'

signal score_submitted
signal scores_fetched(scores: Array)


func submit_score(player_name: String, score: int, level: int) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		http.queue_free()
		if code == 201:
			emit_signal('score_submitted')
		else:
			print('Submit error: ', code, ' ', body.get_string_from_utf8())
	)
	var body = JSON.stringify({
		'name': player_name,
		'score': score,
		'level': level
	})
	var headers = [
		'Content-Type: application/json',
		'apikey: ' + SUPABASE_KEY,
		'Authorization: Bearer ' + SUPABASE_KEY,
		'Prefer: return=minimal'
	]
	http.request(SUPABASE_URL + '/rest/v1/scores', headers, HTTPClient.METHOD_POST, body)


func fetch_scores() -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		http.queue_free()
		if code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json != null:
				emit_signal('scores_fetched', json)
		else:
			print('Fetch error: ', code)
	)
	var headers = [
		'apikey: ' + SUPABASE_KEY,
		'Authorization: Bearer ' + SUPABASE_KEY,
		'Accept: application/json',
		'Content-Type: application/json',
		'Accept-Encoding: identity'
	]
	http.request(SUPABASE_URL + '/rest/v1/scores?select=name,score,level,created_at&order=score.desc&limit=10', headers, HTTPClient.METHOD_GET, '')
