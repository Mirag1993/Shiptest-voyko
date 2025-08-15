// TTS TGUI Interface
// Modern UI for TTS settings

// TTS Settings UI Datum
/datum/tts_settings_ui
	var/mob/living/user
	var/datum/component/tts_preferences/prefs

/datum/tts_settings_ui/New(mob/living/target_user)
	. = ..()
	user = target_user
	prefs = user.GetComponent(/datum/component/tts_preferences)
	if(!prefs)
		prefs = user.AddComponent(/datum/component/tts_preferences)

/datum/tts_settings_ui/proc/open_ui()
	if(!user || !user.client)
		return

	var/list/data = list()

	data["enabled"] = prefs.get_pref(TTS_PREF_ENABLED)
	data["voice"] = prefs.get_pref(TTS_PREF_VOICE)
	data["volume"] = prefs.get_pref(TTS_PREF_VOLUME)
	data["available_voices"] = GLOB.tts_voices
	data["system_enabled"] = GLOB.tts_enabled

	// For now, use a simple input-based UI instead of TGUI
	// This avoids TGUI complexity while still providing functionality
	show_simple_ui()

/datum/tts_settings_ui/proc/show_simple_ui()
	var/list/options = list()
	options["Toggle TTS"] = "toggle"
	options["Change Voice"] = "voice"
	options["Change Volume"] = "volume"
	options["Test Voice"] = "test"
	options["Show Settings"] = "settings"
	options["Cancel"] = "cancel"

	var/choice = input(user, "TTS Settings", "TTS Preferences") as null|anything in options
	if(!choice || choice == "Cancel")
		return

	switch(choice)
		if("toggle")
			var/current_state = prefs.get_pref(TTS_PREF_ENABLED)
			prefs.set_pref(TTS_PREF_ENABLED, !current_state)
			var/new_state = prefs.get_pref(TTS_PREF_ENABLED)
			to_chat(user, span_notice("TTS [new_state ? "включен" : "выключен"]."))

		if("voice")
			var/list/available_voices = GLOB.tts_voices
			var/current_voice = prefs.get_pref(TTS_PREF_VOICE)
			var/new_voice = input(user, "Выберите голос", "TTS Voice", current_voice) as null|anything in available_voices
			if(new_voice)
				prefs.set_pref(TTS_PREF_VOICE, new_voice)
				to_chat(user, span_notice("Голос изменен на [new_voice]."))

		if("volume")
			var/current_volume = prefs.get_pref(TTS_PREF_VOLUME)
			var/new_volume = input(user, "Громкость TTS (0-100)", "TTS Volume", current_volume) as num|null
			if(!isnull(new_volume))
				new_volume = clamp(new_volume, 0, 100)
				prefs.set_pref(TTS_PREF_VOLUME, new_volume)
				to_chat(user, span_notice("Громкость установлена на [new_volume]%."))

		if("test")
			if(!prefs.get_pref(TTS_PREF_ENABLED))
				to_chat(user, span_warning("TTS выключен. Включите его сначала."))
				return

			var/voice = prefs.get_pref(TTS_PREF_VOICE)
			GLOB.tts_system.process_speech(user, "Hello, this is a test message.", "say")
			to_chat(user, span_notice("Проиграна тестовая фраза голосом [voice]."))

		if("settings")
			to_chat(user, span_info("=== TTS Settings ==="))
			to_chat(user, span_info("Enabled: [prefs.get_pref(TTS_PREF_ENABLED) ? "Yes" : "No"]"))
			to_chat(user, span_info("Voice: [prefs.get_pref(TTS_PREF_VOICE)]"))
			to_chat(user, span_info("Volume: [prefs.get_pref(TTS_PREF_VOLUME)]%"))

// Client verb to open TTS settings UI
/client/verb/open_tts_settings()
	set name = "TTS Settings UI"
	set category = "Special Verbs"
	set desc = "Открыть настройки TTS в современном интерфейсе"

	var/mob/living/user = mob
	if(!user)
		to_chat(usr, span_warning("Вы должны быть живым существом для использования TTS."))
		return

	var/datum/tts_settings_ui/ui = new(user)
	ui.open_ui()

// Simple TTS status display
/client/verb/tts_status()
	set name = "TTS Status"
	set category = "Special Verbs"
	set desc = "Показать статус TTS"

	var/mob/living/user = mob
	if(!user)
		to_chat(usr, span_warning("Вы должны быть живым существом для использования TTS."))
		return

	var/datum/component/tts_preferences/prefs = user.GetComponent(/datum/component/tts_preferences)
	if(!prefs)
		prefs = user.AddComponent(/datum/component/tts_preferences)

	to_chat(user, span_info("=== TTS Status ==="))
	to_chat(user, span_info("Enabled: [prefs.get_pref(TTS_PREF_ENABLED) ? "Yes" : "No"]"))
	to_chat(user, span_info("Voice: [prefs.get_pref(TTS_PREF_VOICE)]"))
	to_chat(user, span_info("Volume: [prefs.get_pref(TTS_PREF_VOLUME)]%"))
	to_chat(user, span_info("System Enabled: [GLOB.tts_enabled ? "Yes" : "No"]"))

	if(GLOB.tts_system)
		var/list/stats = GLOB.tts_system.get_statistics()
		to_chat(user, span_info("Available Voices: [stats["available_voices"]]"))
		to_chat(user, span_info("Loaded Sounds: [stats["loaded_sounds"]]"))
	else
		to_chat(user, span_warning("TTS system not initialized."))
