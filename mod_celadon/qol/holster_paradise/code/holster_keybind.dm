// Система клавиш для кобур — Автор: Mirag1993
// Переменная для защиты от двойного нажатия
/mob/var/holster_processing = FALSE

// Макросы DEBUG логов определены в holster_types.dm

// Хоткей для кобуры (настраиваемая клавиша)
/datum/keybinding/human/holster
	hotkey_keys = list("Unbound")
	name = "holster"
	full_name = "Holster"
	description = "Holster or unholster weapon"
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
		HOLSTER_DBG(HOLSTER_LOG_DEBUG, src, "handle_holster_keybind: already processing for user [src.ckey]")
		return COMSIG_KB_ACTIVATED
	// Проверки состояния пользователя делегируются в низкоуровневые методы кобуры
	HOLSTER_DBG(HOLSTER_LOG_DEBUG, src, "handle_holster_keybind: processing holster request for user [src.ckey]")
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
	// Флаг processing уже проверен в handle_holster_keybind()
	HOLSTER_DBG(HOLSTER_LOG_DEBUG, src, "holster_weapon: starting holster operation for user [src.ckey]")
	// Получаем кобуру
	var/obj/item/clothing/accessory/holster/holster = locate_holster_from_uniform()
	if(!holster)
		HOLSTER_LOG(HOLSTER_LOG_WARNING, src, "holster_weapon: no holster for user [src.ckey]")
		holster_notify_fail(src, HOLSTER_FAIL_NO_HOLSTER)
		holster_processing = FALSE
		return
	var/datum/component/storage/STR = holster.get_storage_component(src)
	var/obj/item/weapon = get_active_held_item()
	// Если в кобуре уже есть предмет — всегда достаём, даже если рука занята
	if(holster.has_contents(STR))
		HOLSTER_DBG(HOLSTER_LOG_DEBUG, src, "holster_weapon: holster has item, delegating unholster() for user [src.ckey]")
		holster.unholster(src)
		holster_processing = FALSE
		return
	// Иначе — если в руке предмет, пытаемся убрать его в кобуру
	if(weapon)
		HOLSTER_DBG(HOLSTER_LOG_DEBUG, src, "holster_weapon: delegating holster() for [weapon.type] user [src.ckey]")
		holster.holster(weapon, src)
		holster_processing = FALSE
		return
	// Иначе — достаём из кобуры (если пусто — придёт сообщение)
	HOLSTER_DBG(HOLSTER_LOG_DEBUG, src, "holster_weapon: delegating unholster() for user [src.ckey]")
	holster.unholster(src)
	holster_processing = FALSE

// Простая обёртка для поиска кобуры из униформы
/mob/living/carbon/human/proc/locate_holster_from_uniform()
	if(!istype(w_uniform) || QDELETED(w_uniform))
		return null
	var/obj/item/clothing/under/uniform = w_uniform
	if(!uniform.attached_accessory || QDELETED(uniform.attached_accessory))
		return null
	if(!istype(uniform.attached_accessory, /obj/item/clothing/accessory/holster))
		return null
	return uniform.attached_accessory


