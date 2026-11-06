extends SceneTree
var checks=0
var failures=0
func ensure(value,description):
 checks+=1
 if not value:failures+=1;push_error("PANEL_PROTOCOL_FAIL "+description)
 else:print("PASS "+description)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scripts/game.gd").new();game.test_mode=true;game.message=Label.new()
 var wallet=game.wallet.duplicate();var profile=game.profile_name
 for body in [{},{"players":["bad"]},{"players":[{"id":"p1","name":"Wolf"}]}]:
  game.on_poll(0,200,[],JSON.stringify(body).to_utf8_buffer())
 ensure(game.wallet==wallet and game.profile_name==profile and game.remote_player=="","malformed panel state cannot partially replace profile or balances")
 var player={"id":"p1","name":"Wolf","cash":10,"kp":20,"gold":30,"gp":40}
 var state={"token":"fixture-token","players":[player]}
 game.on_poll(0,200,[],JSON.stringify(state).to_utf8_buffer())
 ensure(game.remote_player=="p1" and game.wallet.gold==30,"valid local panel state updates the actual selected player")
 wallet=game.wallet.duplicate();player.gold=-1;player.name="Changed"
 game.on_poll(0,200,[],JSON.stringify(state).to_utf8_buffer())
 ensure(game.wallet==wallet and game.profile_name=="Wolf · PC paneli","one invalid balance rolls back the entire incoming state")
 ensure(not game.grant_money("gold",0.5,"invalid") and not game.grant_money("gold",NAN,"invalid") and not game.grant_money("gold",true,"invalid"),"fractional, nonfinite and boolean grants are rejected")
 var request={"requestId":"fixture-request","playerId":"p1","currency":"gold","amount":5}
 game.grant_queue.append(request);game.on_grant(0,200,[],JSON.stringify({"balance_after":999}).to_utf8_buffer())
 ensure(game.wallet==wallet and game.grant_queue.is_empty(),"uncorrelated HTTP 200 is not treated as a successful grant or retried")
 var response={"request_id":"fixture-request","player_id":"wrong","currency":"gold","amount":5,"balance_after":35}
 game.grant_queue.append(request);game.on_grant(0,200,[],JSON.stringify(response).to_utf8_buffer())
 ensure(game.wallet==wallet,"another player's grant response cannot change this player's balance")
 response.player_id="p1";game.grant_queue.append(request);game.on_grant(0,200,[],JSON.stringify(response).to_utf8_buffer())
 ensure(game.wallet.gold==35,"a correlated grant response applies its confirmed balance")
 game.message.free();game.free();print("PANEL_PROTOCOL_QA checks=%d failures=%d" % [checks,failures]);quit(0 if failures==0 else 1)
