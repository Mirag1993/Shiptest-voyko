// Crafting recipe для MedAssist Handcraft
// Добавляем категорию Medicine в personal crafting

// Определяем категорию локально для мода
#ifndef CAT_MEDICINE
#define CAT_MEDICINE "Medicine"
#endif

// Добавляем категорию в список (хук)
/datum/component/personal_crafting/Initialize()
	. = ..()
	if(!categories[CAT_MEDICINE])
		categories[CAT_MEDICINE] = CAT_NONE

// Рецепт крафта MedAssist Handcraft
/datum/crafting_recipe/medassist_handcraft
	name = "QuickHeal Handcraft"
	result = /obj/item/medassist_device/handcraft
	time = 100
	reqs = list(
		/obj/item/restraints/handcuffs/cable = 2,
		/obj/item/stack/tape/industrial = 1,
		/obj/item/reagent_containers/syringe = 1,
		/obj/item/stack/sheet/metal = 2,
		/obj/item/assembly/health = 1,
		/obj/item/stock_parts/cell = 1,
		/obj/item/stock_parts/manipulator = 1,
		/obj/item/stack/cable_coil = 5
	)
	tools = list(
		TOOL_SCREWDRIVER,
		TOOL_WIRECUTTER,
		TOOL_WELDER,
		TOOL_MULTITOOL
	)
	category = CAT_MEDICINE

