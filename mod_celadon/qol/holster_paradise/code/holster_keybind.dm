// Система клавиш для кобур — Автор: Mirag1993
// Переменная для защиты от двойного нажатия
/mob/var/holster_processing = FALSE

// Хоткей для кобуры (настраиваемая клавиша)
/datum/keybinding/human/holster
	hotkey_keys = list("Unbound")
	name = "holster"
	full_name = "Кобура"
	description = "Спрятать или достать оружие из кобуры"
	keybind_signal = COMSIG_KB_HUMAN_HOLSTER_DOWN

/datum/keybinding/human/holster/down(client/user)
	. = ..()
	if(.)
		return
	return SEND_SIGNAL(user.mob, keybind_signal) & COMSIG_KB_ACTIVATED

/mob/living/carbon/human/Initialize(mapload)
	. = ..()
	// Регистрируем обработчик хоткея кобуры
	RegisterSignal(src, COMSIG_KB_HUMAN_HOLSTER_DOWN, PROC_REF(handle_holster_keybind))

// Обработчик хоткея кобуры
/mob/living/carbon/human/proc/handle_holster_keybind()
	SIGNAL_HANDLER
	// Валидация базовых инвариантов
	if(!src || !istype(src) || QDELETED(src))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, src, "handle_holster_keybind: mob is null or deleted")
		return COMSIG_KB_ACTIVATED
	// Проверяем, не обрабатывается ли уже запрос
	if(holster_processing)
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "handle_holster_keybind: already processing for user [src.ckey]")
		return COMSIG_KB_ACTIVATED
	// Проверки состояния пользователя делегируются в низкоуровневые методы кобуры
	HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "handle_holster_keybind: processing holster request for user [src.ckey]")
	holster_processing = TRUE
	addtimer(CALLBACK(src, PROC_REF(holster_weapon)), 0)
	return COMSIG_KB_ACTIVATED

// Спрятать/достать оружие (делегирование в методы кобуры)
/mob/living/carbon/human/proc/holster_weapon()
	// Валидация базовых инвариантов
	if(!src || !istype(src) || QDELETED(src))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, src, "holster_weapon: mob is null or deleted")
		holster_processing = FALSE
		return
	// Дополнительная проверка состояния флага
	if(holster_processing == FALSE)
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "holster_weapon: not processing for user [src.ckey]")
		return
	HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "holster_weapon: starting holster operation for user [src.ckey]")
	// Получаем кобуру
	var/list/holster_data = get_holster_and_storage()
	var/obj/item/clothing/accessory/holster/holster = holster_data["holster"]
	if(!holster)
		HOLSTER_LOG(HOLSTER_LOG_WARNING, src, "holster_weapon: no holster for user [src.ckey]")
		to_chat(src, span_warning("У вас нет кобуры!"))
		holster_processing = FALSE
		return
	var/datum/component/storage/STR = holster_data["storage"]
	var/obj/item/weapon = get_active_held_item()
	// Если в кобуре уже есть предмет — всегда достаём, даже если рука занята
	var/list/_holster_contents = STR ? STR.contents() : null
	if(STR && LAZYLEN(_holster_contents))
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "holster_weapon: holster has item, delegating unholster() for user [src.ckey]")
		holster.unholster(src)
		holster_processing = FALSE
		return
	// Иначе — если в руке предмет, пытаемся убрать его в кобуру
	if(weapon)
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "holster_weapon: delegating holster() for [weapon.type] user [src.ckey]")
		holster.holster(weapon, src)
		holster_processing = FALSE
		return
	// Иначе — достаём из кобуры (если пусто — придёт сообщение)
	HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "holster_weapon: delegating unholster() for user [src.ckey]")
	holster.unholster(src)
	holster_processing = FALSE

// Единая функция для получения кобуры и storage-компонента (валидация)
/mob/living/carbon/human/proc/get_holster_and_storage()
	var/list/result = list("holster" = null, "storage" = null)
	// Проверяем базовые инварианты
	if(!src || !istype(src) || QDELETED(src))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, src, "get_holster_and_storage: mob is null or deleted")
		return result
	if(!istype(w_uniform) || QDELETED(w_uniform))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, src, "get_holster_and_storage: user [src.ckey] has no uniform")
		return result
	var/obj/item/clothing/under/uniform = w_uniform
	// Проверяем attached_accessory
	if(!uniform.attached_accessory || QDELETED(uniform.attached_accessory))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, src, "get_holster_and_storage: user [src.ckey] has no attached accessory")
		return result
	if(!istype(uniform.attached_accessory, /obj/item/clothing/accessory/holster))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, src, "get_holster_and_storage: user [src.ckey] attached accessory is not holster")
		return result
	var/obj/item/clothing/accessory/holster/holster = uniform.attached_accessory
	// Дополнительная проверка
	if(QDELETED(holster))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, src, "get_holster_and_storage: holster is deleted for user [src.ckey]")
		return result
	result["holster"] = holster
	// Получаем storage через функцию (если нужно)
	var/datum/component/storage/STR = holster.get_storage_component(src)
	if(!STR || QDELETED(STR))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, src, "get_holster_and_storage: storage component is null or deleted for user [src.ckey]")
		result["holster"] = null
		return result
	result["storage"] = STR
	HOLSTER_LOG(HOLSTER_LOG_DEBUG, src, "get_holster_and_storage: found holster and storage for user [src.ckey]")
	return result


