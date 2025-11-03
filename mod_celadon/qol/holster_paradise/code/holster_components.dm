/datum/action/item_action/accessory/holster
	name = "Кобура"
	button_icon_state = "holster"

/datum/action/item_action/accessory/holster/Trigger()
	var/obj/item/clothing/accessory/holster/holster = target
	if(!holster)
		return
	holster.toggle_holster(owner)
