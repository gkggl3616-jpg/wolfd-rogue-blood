extends RefCounted
const Art=preload("res://ui/source_theme.gd")
const Layout=preload("res://ui/source_layout.gd")
const SourceCard=preload("res://ui/source_item_card.gd")
var ui
var clock=0.0
var opening=false
var reward={}
var preview
var title_label
var accept
var progress
var count_labels=[]
var summary
func build():
	var section=ui.native("section/inventory",ui.content);section.show_only(["WeaponState","Inventory"])
	ui.text(ui.content,"EKİPMAN  /  KUTULAR",Vector2(366,91),Vector2(600,27),18,Art.GOLD)
	ui.paragraph(ui.content,"Yerel kutu koleksiyonu\nYerel nakit ile açılır.",Vector2(18,90),Vector2(320,70),15)
	ui.button(ui.content,"Envanter",Vector2(366,124),Vector2(130,26),func():ui.navigate("Envanter"))
	ui.button(ui.content,"Açılanlar",Vector2(506,124),Vector2(130,26),history)
	var rows=ui.game.boxes.catalog.boxes
	if ui.selected.is_empty():ui.selected=rows[0]
	var selected=ui.selected
	Art.sprite(ui.content,selected.icon,Vector2(18,192),Vector2(320,256)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui.text(ui.content,selected.name,Vector2(18,456),Vector2(320,40),20,Art.GOLD)
	summary=ui.paragraph(ui.content,"Kalan adet: %d\nYerel fiyat: %d nakit" % [int(ui.game.boxes.state.counts.get(selected.id,0)),int(selected.localPrice)],Vector2(18,510),Vector2(320,74),17)
	for i in range(rows.size()):
		var entry=rows[i];var at=Vector2(366+i*210,154)
		var button=SourceCard.create(ui.content,at,Vector2(208,135),func():ui.selected=entry;ui.refresh())
		button.set_meta("box_id",entry.id)
		Art.sprite(button,entry.icon,Vector2(3,3),Vector2(202,76)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ui.text(button,entry.name,Vector2(5,80),Vector2(198,20),13)
		count_labels.append([entry.id,ui.text(button,"Kalan adet: %d" % int(ui.game.boxes.state.counts.get(entry.id,0)),Vector2(5,105),Vector2(198,20),12)])
	ui.button(ui.content,"Tekrar al · %d nakit" % int(selected.localPrice),Vector2(366,325),Vector2(294,34),func():buy(selected))
	ui.button(ui.content,"Kullan · Kutuyu aç",Vector2(674,325),Vector2(322,34),func():open_box(selected),int(ui.game.boxes.state.counts.get(selected.id,0))>0)
	ui.paragraph(ui.content,"KUTU İÇERİĞİ\nYerel denemede aşağıdaki dövmeler eşit olasılıkla seçilir. PC kutu oranı ve süreli kupon hizmeti bu sürümde bulunmaz.",Vector2(366,393),Vector2(630,80),15)
	for i in range(mini(8,selected.rewards.size())):
		var entry=selected.rewards[i];var at=Vector2(366+(i%4)*157,492+int(i/4)*102)
		Art.sprite(ui.content,entry.texture,at,Vector2(150,72)).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ui.text(ui.content,entry.name,at+Vector2(0,73),Vector2(150,24),11)
func buy(entry):
	var request="buy-%s-%s" % [Time.get_ticks_usec(),randi()]
	ui.confirm("KUTU SATIN AL",entry.name+"\n%d yerel nakit harcansın mı?" % int(entry.localPrice),func():
		var result=ui.game.box_action("buy",entry.id,request)
		if result.ok:ui.refresh()
		else:ui.show_error(result.error)
	,func():pass)
func open_box(entry):
	var result=ui.game.box_action("open",entry.id,"open-%s-%s" % [Time.get_ticks_usec(),randi()])
	if not result.ok:ui.show_error(result.error);return
	for row in count_labels:row[1].text="Kalan adet: %d" % int(ui.game.boxes.state.counts.get(row[0],0))
	summary.text="Kalan adet: %d\nYerel fiyat: %d nakit" % [int(ui.game.boxes.state.counts.get(entry.id,0)),int(entry.localPrice)]
	show_reward(result.reward,true,entry.icon)
func show_reward(item,animate=false,box_icon=""):
	reward=item;clock=0;opening=animate
	ui.confirm("KAZANILAN EŞYA","",func():ui.refresh())
	for child in ui.modal.get_children():
		if child is Layout:child.hide()
	Art.sprite(ui.modal,"wt_interface/ai/pve/rewardboxui/wr_popup_box_open.dtx",Vector2(251,130),Vector2(522,494),Rect2(0,0,326,309))
	var inner=ColorRect.new();inner.color=Color("263a4c");inner.position=Vector2(269,171);inner.size=Vector2(486,430);ui.modal.add_child(inner)
	title_label=ui.text(ui.modal,"Kutu açılıyor…" if animate else item.name,Vector2(278,186),Vector2(468,46),21,Art.GOLD);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	preview=Art.sprite(ui.modal,box_icon if animate else item.texture,Vector2(328,245),Vector2(368,209));preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	progress=ProgressBar.new();progress.position=Vector2(300,477);progress.size=Vector2(424,18);progress.show_percentage=false;ui.modal.add_child(progress);progress.visible=animate
	ui.text(ui.modal,"Kazanılan eşya · Yerel koleksiyona kaydedildi",Vector2(280,516),Vector2(464,26),13).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	accept=ui.button(ui.modal,"Dövmeyi kullan",Vector2(283,562),Vector2(220,32),func():
		if ui.game.book.set_tattoo(item.role,item.texture):ui.game.player.apply_tattoos();ui.close_modal();ui.navigate("Dövmeler")
		else:ui.show_error("Dövme seçimi kaydedilemedi.")
	);accept.disabled=animate
	ui.button(ui.modal,"Tamam",Vector2(523,562),Vector2(220,32),func():ui.close_modal();ui.refresh())
func history():
	ui.confirm("AÇILAN KUTULAR","",func():pass)
	var rows=ui.game.boxes.state.history
	if rows.is_empty():ui.text(ui.modal,"Henüz kutu açılmadı.",Vector2(320,310),Vector2(380,40),16);return
	for i in range(mini(5,rows.size())):
		var entry=rows[i]
		ui.button(ui.modal,"#%d · %s" % [int(entry.serial),entry.name],Vector2(300,290+i*34),Vector2(424,30),func():show_reward(entry))
func update(delta):
	if not opening:return
	if not is_instance_valid(ui.modal) or not is_instance_valid(preview):opening=false;return
	clock+=delta;progress.value=minf(100,clock/1.4*100);preview.modulate=Color.WHITE*(0.8+sin(clock*12)*0.2)
	if clock>=1.4:
		opening=false;preview.modulate=Color.WHITE;preview.texture=Art.texture(reward.texture);title_label.text=reward.name;progress.hide();accept.disabled=false
