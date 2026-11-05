extends RefCounted
const MODE=900001
const ROUNDS=3
const TARGET=4
const SECONDS=90.0
var active=false
var round_number=1
var wins=0
var losses=0
var round_kills=0
var spawned=0
var phase="combat"
var intermission=0.0
var player_form="human"
func begin(form):
	active=true;round_number=1;wins=0;losses=0;round_kills=0;spawned=0;phase="combat";intermission=0;player_form="wolf" if form=="wolf" else "human"
func finish_round(won):
	if not active or phase!="combat":return false
	if won:wins+=1
	else:losses+=1
	phase="finished" if round_number>=ROUNDS else "intermission"
	intermission=3.0
	return true
func next_round():
	if not active or phase!="intermission":return false
	round_number+=1;round_kills=0;spawned=0;phase="combat";intermission=0
	return true
func enemy_kind():return "human" if player_form=="wolf" else "wolf"
