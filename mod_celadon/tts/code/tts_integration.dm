// TTS Integration with Chat System
// Integrates TTS with the game's speech system

// Override speech functions to trigger TTS
/mob/living/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	. = ..()

	// Process TTS after normal speech
	if(GLOB.tts_system && GLOB.tts_enabled)
		GLOB.tts_system.process_speech(src, message, "say")

/mob/living/whisper(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	. = ..()

	// Process TTS after normal whisper
	if(GLOB.tts_system && GLOB.tts_enabled)
		GLOB.tts_system.process_speech(src, message, "whisper")

/mob/living/emote(act, m_type = null, message = null, intentional = FALSE)
	. = ..()

	// Process TTS for emotes that involve speech
	if(GLOB.tts_system && GLOB.tts_enabled && message)
		GLOB.tts_system.process_speech(src, message, "emote")

// Note: TTS is integrated through say(), whisper(), and emote() overrides
// This provides comprehensive coverage of speech in the game

// Auto-assign TTS preferences based on character gender
/mob/living/proc/setup_tts_preferences()
	var/datum/component/tts_preferences/prefs = GetComponent(/datum/component/tts_preferences)
	if(!prefs)
		prefs = AddComponent(/datum/component/tts_preferences)

	// Set default voice based on gender
	var/default_voice = "male_07" // Default for unknown gender
	// For now, use male_07 as default for all mobs
	// Gender-based voice selection can be implemented later

	prefs.set_pref(TTS_PREF_VOICE, default_voice)
	prefs.set_pref(TTS_PREF_ENABLED, TRUE)
	prefs.set_pref(TTS_PREF_VOLUME, 50)

// Setup TTS preferences when mob is created
/mob/living/Initialize()
	. = ..()

	// Setup TTS preferences
	setup_tts_preferences()

// Simple TTS preferences UI
/proc/open_tts_preferences(mob/living/user)
	if(!user || !user.client)
		return

	var/datum/component/tts_preferences/prefs = user.GetComponent(/datum/component/tts_preferences)
	if(!prefs)
		prefs = user.AddComponent(/datum/component/tts_preferences)

	var/list/options = list()
	options["Cancel"] = "cancel"
	options["Toggle TTS"] = "toggle"
	options["Change Voice"] = "voice"
	options["Change Volume"] = "volume"
	options["Test Voice"] = "test"
	options["Show Settings"] = "settings"

	var/choice = input(user, "TTS Preferences", "TTS Settings") as null|anything in options
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

// Client verb to open TTS preferences
/client/verb/tts_preferences()
	set name = "TTS Preferences"
	set category = "Special Verbs"
	set desc = "Открыть настройки TTS"

	var/mob/living/user = mob
	if(!user)
		to_chat(usr, span_warning("Вы должны быть живым существом для использования TTS."))
		return

	open_tts_preferences(user)
