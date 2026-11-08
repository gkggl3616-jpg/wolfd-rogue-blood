extends RefCounted
var catalog={}
func _init():catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/ranks.json"))
func current(gp):
	var found=catalog.ranks[0]
	for row in catalog.ranks:
		if int(row.localMinimumGp)>gp:break
		found=row
	return found
func next(gp):
	for row in catalog.ranks:
		if int(row.localMinimumGp)>gp:return row
	return {}

func progress(gp):
	var points=maxi(0,int(gp));var row=current(points);var index=catalog.ranks.find(row);var following=next(points);var start=int(row.localMinimumGp);var finish=int(following.get("localMinimumGp",start));var capped=following.is_empty()
	return {"level":index+1,"maxLevel":catalog.ranks.size(),"gp":points,"rankName":row.name,"rankAsset":row.asset,"minimumGp":start,"nextMinimumGp":finish,"remainingGp":maxi(0,finish-points),"earnedInLevel":maxi(0,points-start),"fraction":1.0 if capped else clampf(float(points-start)/maxi(1,finish-start),0,1),"maxed":capped,"localThresholds":true}
