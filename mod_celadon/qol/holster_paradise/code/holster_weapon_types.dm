// Типы оружия, которое можно кобурить
// Только пистолеты, револьверы и маленькое энергетическое оружие
// Ограничение по размеру: TINY, SMALL, NORMAL (без BULKY, HUGE, GIGANTIC)
// МАКСИМУМ 1 предмет в любой кобуре
// ИСКЛЮЧЕНИЕ: Кобура нюкера принимает BULKY оружие
// Автор: Mirag1993

// Базовый тип оружия - добавляем переменную can_holster (по умолчанию FALSE)
/obj/item/gun
	var/can_holster = FALSE

// ========================================
// ПИСТОЛЕТЫ - Все баллистические пистолеты можно кобурить
// ========================================
/obj/item/gun/ballistic/automatic/pistol/Initialize(mapload)
	. = ..()
	can_holster = TRUE

/obj/item/gun/ballistic/revolver/Initialize(mapload)
	. = ..()
	can_holster = TRUE

// ========================================
// ЭНЕРГЕТИЧЕСКОЕ ОРУЖИЕ - Базовые классы (покрывают все подтипы)
// ========================================
/obj/item/gun/energy/e_gun/mini/Initialize(mapload)  // Mini energy gun - уникальный тип
	. = ..()
	can_holster = TRUE

/obj/item/gun/energy/disabler/Initialize(mapload)   // Disabler - уникальный тип
	. = ..()
	can_holster = TRUE

/obj/item/gun/energy/e_gun/Initialize(mapload)      // ВСЕ energy guns
	. = ..()
	can_holster = TRUE

/obj/item/gun/energy/laser/Initialize(mapload)      // ВСЕ laser pistols
	. = ..()
	can_holster = TRUE

/obj/item/gun/energy/plasma/Initialize(mapload)     // ВСЕ plasma pistols
	. = ..()
	can_holster = TRUE


