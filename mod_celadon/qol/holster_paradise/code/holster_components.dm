// Действия для кобур
// Экшн-кнопка кобуры
/datum/action/item_action/accessory/holster
	name = "Кобура"
	button_icon_state = "holster"


/datum/action/item_action/accessory/holster/Trigger()
	var/obj/item/clothing/accessory/holster/holster = target
	if(!holster)
		return

	// Единая проверка состояния пользователя через helper
	var/reason = holster.can_use_holster(owner, TRUE)
	if(reason != HOLSTER_OK)
		holster.notify_fail(owner, reason)
		return

	// Унифицированная логика: приоритет извлечению из кобуры
	var/datum/component/storage/STR = holster.get_storage_component(owner)
	// Предпочитаем достать, если в кобуре есть предмет
	if(holster.has_contents(STR))
		holster.unholster(owner)
		return
	var/holsteritem = owner.get_active_held_item()
	if(istype(holsteritem, /obj/item/clothing/accessory/holster))
		// В руке другая кобура — достаем из кобуры
		holster.unholster(owner)
	else if(holsteritem)
		// В руке оружие — пытаемся его спрятать
		holster.holster(holsteritem, owner)
	else
		// Пустая рука — достаем из кобуры (сообщение, если пуста)
		holster.unholster(owner)

