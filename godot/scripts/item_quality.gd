extends RefCounted
# Labels are explicit source names, not an invented numerical PC rarity grade.
const COLORS={"Efsane":Color("694779"),"Elit":Color("365974"),"EX":Color("916329"),"Altın":Color("82713c"),"Gümüş":Color("56656c"),"Standart":Color("303b3e"),"Diğer":Color("343f43")}
static func label(item):
	var name=str(item.get("name","")).to_lower()
	if "efsane" in name or "legend" in name:return "Efsane"
	if "elit" in name or "elite" in name:return "Elit"
	if " ex" in name or name.begins_with("ex "):return "EX"
	if "altın" in name or "gold" in name:return "Altın"
	if "gümüş" in name or "silver" in name:return "Gümüş"
	if "temel" in name or "standart" in name or "classic" in name:return "Standart"
	return "Diğer"
