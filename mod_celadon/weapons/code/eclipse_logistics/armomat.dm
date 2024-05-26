/obj/machinery/vending/security/armomant
	name = "\improper weapon vendor"
	desc = "A marine equipment vendor."
	product_ads = "Please insert your marine voucher in the bottom slot."
	icon = 'mod_celadon/weapons/icons/armomat/VendingGuns.dmi'
	icon_state = "armomant"
	icon_deny = "armomant-deny"
	light_mask = "armomant-mask"
	req_access = list()
	products = list(
		/obj/item/screwdriver = 5,
		/obj/item/screwdriver
		)
	contraband = list()
	premium = list()
	//voucher_items = list(
		//"Tactical Energy Gun" = /obj/item/gun/energy/e_gun/hades,
		//"Combat Shotgun" = /obj/item/gun/ballistic/shotgun/automatic/combat,
		//"Type U3 Uzi" = /obj/item/gun/ballistic/automatic/smg/mini_uzi)

/obj/machinery/vending/security/armomant/ui_interact(mob/user, datum/tgui/ui)
    ui = SStgui.try_update_ui(user, src, ui)
    if (!ui)
        ui = new(user, src, "VendingArmEntry")
        ui.open()

/obj/machinery/vending/security/armomant/ui_act(action, params, mob/user, datum/tgui/ui)
    . = ..()
    if(.)
        return
    switch(action)
        if("enter")
            if(ui)
                return UI_CLOSE // Закрываем старый интерфейс, если он открыт
            ui = new(user, src, "VendingArm") // Создаем новый интерфейс
            ui.open() // Открываем новый интерфейс
            return TRUE
        // другие действи
