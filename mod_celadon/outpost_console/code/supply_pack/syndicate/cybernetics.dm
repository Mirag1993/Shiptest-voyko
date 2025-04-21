/datum/supply_pack/faction/syndicate/cybernetics
	group = "Cybernetics"
	crate_type = /obj/structure/closet/crate/freezer

// CYBERNETICS

/datum/supply_pack/faction/syndicate/cybernetics/cyberarm_surgset
	name = "Integrated Surgical Toolset Kit"
	desc = "The latest in advanced medical cybernetics, the Surgical Toolset can be installed in the arms and act as a concealed kit to render surgical aid at striking efficiency."
	cost = 4500
	contains = list(/obj/item/organ/cyberimp/arm/surgery)
	crate_name = "implant crate"

/datum/supply_pack/faction/syndicate/cybernetics/cyberarm_toolset
	name = "Integrated Engineering Toolset Kit"
	desc = "A recent innovation in engineering labor, this functions as a concealed toolkit for use in all manner of engineering operations. It is installed in the arms."
	cost = 2000
	contains = list(/obj/item/organ/cyberimp/arm/toolset)
	crate_name = "implant crate"

/datum/supply_pack/faction/syndicate/cybernetics/cyberhud_sec
	name = "Integrated Security HUD"
	desc = "A HUD over the user's eyes that allows one to view security and IFF data on the field. Reports of recalls and blindness are merely disinformation by competitors."
	cost = 2000
	contains = list(/obj/item/organ/cyberimp/eyes/hud/security)
	crate_name = "implant crate"

/datum/supply_pack/faction/syndicate/cybernetics/cyberhud_med
	name = "Integrated Medical Analysis HUD"
	desc = "A HUD over the user's eyes that allows one to view medical and heart-rate data on the field. Reports of recalls and blindness are merely disinformation by competitors."
	cost = 2000
	contains = list(/obj/item/organ/cyberimp/eyes/hud/medical)
	crate_name = "implant crate"

/datum/supply_pack/faction/syndicate/cybernetics/cyberhud_diagnostic
	name = "Integrated Exosuit Diagnostic HUD"
	desc = "A HUD over the user's eyes that allows one to view an uplink of Powered Exoskeleton information. Reports of recalls and blindness are merely disinformation by competitors."
	cost = 750
	contains = list(/obj/item/organ/cyberimp/eyes/hud/diagnostic)
	crate_name = "implant crate"

/datum/supply_pack/faction/syndicate/cybernetics/cyber_breathing
	name = "Integrated Breathing Tube"
	desc = "Commonly used for those with medical conditions relating to breathing, this implant provides a port to attach portable oxygen canisters to that pumps air directly into your lungs. Keep port sealed when not in use."
	cost = 1000
	contains = list(/obj/item/organ/cyberimp/mouth/breathing_tube)
	crate_name = "implant crate"

/datum/supply_pack/faction/syndicate/cybernetics/cyberorgans
	name = "Cybernetic Organs Replacement Pack"
	desc = "Precision-manufactured replacement organs for those suffering catastrophic organ failure. Keep crate sealed until use, contaminants may cause rejection."
	cost = 2000
	contains = list(/obj/item/organ/lungs/cybernetic/tier2,
					/obj/item/organ/stomach/cybernetic/tier2,
					/obj/item/organ/liver/cybernetic/tier2,
					/obj/item/organ/heart/cybernetic/tier2)
	crate_name = "organs crate"
