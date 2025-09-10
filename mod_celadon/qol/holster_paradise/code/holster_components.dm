// Действия для кобур
// Экшн кнопка кобуры
/datum/action/item_action/accessory/holster
	name = "Кобура"
	button_icon_state = "holster"

/datum/action/item_action/accessory/holster/Trigger()
	var/obj/item/clothing/accessory/holster/holster = target
	if(!holster)
		return

	var/holsteritem = owner.get_active_hand()
	if(!holsteritem)
		// Пустая рука - достаем оружие из кобуры
		holster.unholster(owner)
	else if(istype(holsteritem, /obj/item/clothing/accessory/holster))
		// В руке другая кобура - ничего не делаем
		to_chat(owner, span_warning("Нельзя положить кобуру в кобуру!"))
	else
		// В руке оружие - пытаемся его спрятать
		holster.holster(holsteritem, owner)

