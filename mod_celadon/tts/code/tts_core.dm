// TTS Core System - Mumbleboops Integration
// Based on Mojave-Sun PR #2142: https://github.com/Mojave-Sun/mojave-sun-13/pull/2142

// Глобальные переменные
GLOBAL_VAR_INIT(tts_enabled, TRUE)
GLOBAL_VAR_INIT(tts_voices, list("male_01", "male_02", "male_03", "male_04", "male_05", "male_06", "male_07", "female_01", "female_02", "female_03", "ms13effects"))
GLOBAL_VAR_INIT(tts_user_prefs, list())
GLOBAL_DATUM(tts_system, /datum/tts_system)

// Сигналы для TTS (уже определены в базовом коде)
// COMSIG_MOB_SAY, COMSIG_MOB_WHISPER, COMSIG_MOB_EMOTE

// TTS Preferences
#define TTS_PREF_ENABLED "tts_enabled"
#define TTS_PREF_VOICE "tts_voice"
#define TTS_PREF_VOLUME "tts_volume"

// Voice types - based on available sound files
#define VOICE_MALE_01 "male_01"
#define VOICE_MALE_02 "male_02"
#define VOICE_MALE_03 "male_03"
#define VOICE_MALE_04 "male_04"
#define VOICE_MALE_05 "male_05"
#define VOICE_MALE_06 "male_06"
#define VOICE_MALE_07 "male_07"
#define VOICE_FEMALE_01 "female_01"
#define VOICE_FEMALE_02 "female_02"
#define VOICE_FEMALE_03 "female_03"
#define VOICE_MS13EFFECTS "ms13effects"

// TTS Core Datum
/datum/tts_system
	var/enabled = TRUE
	var/list/available_voices = list()
	var/list/user_preferences = list()
	var/list/voice_sounds = list()
	var/list/voice_letter_sounds = list() // voice -> (uppercase letter 'A'-'Z') -> filepath

/datum/tts_system/New()
	. = ..()
	initialize_voices()
	load_user_preferences()

/datum/tts_system/proc/initialize_voices()
	available_voices = GLOB.tts_voices

	// Initialize voice sounds cache
	for(var/voice in available_voices)
		voice_sounds[voice] = list()
		voice_letter_sounds[voice] = list()

		// Determine sound directory based on voice type
		var/sound_dir
		if(voice == "ms13effects")
			sound_dir = "mod_celadon/tts/sound/ms13effects/"
		else
			sound_dir = "mod_celadon/tts/sound/voices/[voice]/"

		// Check if voice directory exists
		if(fexists(sound_dir))
			// Load all available sound files for this voice
			for(var/sound_file in flist(sound_dir))
				if(findtext(sound_file, ".wav") || findtext(sound_file, ".ogg"))
					var/full_path = "[sound_dir][sound_file]"
					voice_sounds[voice] += full_path
					// Build per-letter map if filename like s_A.wav
					var/pos = findtext(sound_file, "s_")
					if(pos)
						var/letter = uppertext(copytext(sound_file, pos + 2, pos + 3))
						if(length(letter) == 1)
							var/ascii = text2ascii(letter)
							if(ascii >= 65 && ascii <= 90)
								voice_letter_sounds[voice][letter] = full_path

		// Log loaded sounds count
		var/loaded_count = length(voice_sounds[voice])
		if(loaded_count > 0)
			log_world("TTS: Loaded [loaded_count] sounds for voice [voice] from [sound_dir]")
		else
			log_world("TTS: WARNING - No sounds found for voice [voice] in [sound_dir]")

/datum/tts_system/proc/load_user_preferences()
	user_preferences = GLOB.tts_user_prefs

/datum/tts_system/proc/save_user_preferences()
	GLOB.tts_user_prefs = user_preferences

// TTS User Preferences Component
/datum/component/tts_preferences
	var/enabled = TRUE
	var/voice = "male_07"
	var/volume = 50

/datum/component/tts_preferences/Initialize(enabled = TRUE, voice = "male_07", volume = 50)
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	src.enabled = enabled
	src.voice = voice
	src.volume = volume

/datum/component/tts_preferences/proc/get_pref(pref_name)
	switch(pref_name)
		if(TTS_PREF_ENABLED)
			return enabled
		if(TTS_PREF_VOICE)
			return voice
		if(TTS_PREF_VOLUME)
			return volume
	return null

/datum/component/tts_preferences/proc/set_pref(pref_name, value)
	switch(pref_name)
		if(TTS_PREF_ENABLED)
			enabled = value
		if(TTS_PREF_VOICE)
			voice = value
		if(TTS_PREF_VOLUME)
			volume = clamp(value, 0, 100)

// TTS Speech Processing
/datum/tts_system/proc/process_speech(mob/living/speaker, message, message_type = "say")
	if(!enabled || !speaker || !message)
		return

	var/datum/component/tts_preferences/prefs = speaker.GetComponent(/datum/component/tts_preferences)
	if(!prefs || !prefs.get_pref(TTS_PREF_ENABLED))
		return

	var/voice = prefs.get_pref(TTS_PREF_VOICE)
	var/volume = prefs.get_pref(TTS_PREF_VOLUME)

	// Schedule per-symbol boops using timers (non-blocking chain)
	schedule_mumbleboops(speaker, message, voice, volume, message_type)
	return

// generate_mumbleboops no longer used; replaced by timer-based scheduler

/datum/tts_system/proc/parse_message_to_groups(message)
	var/list/groups = list()
	var/list/punctuation = list(",", ":", ";", ".", "?", "!", "'", "-")

	// Manual parsing like original chatter system
	var/current_word = ""

	for(var/i = 1; i <= length(message); i++)
		var/char = copytext(message, i, i + 1)

		if(char == " ")
			// Space - end current word
			if(length(current_word) > 0)
				groups += length(current_word)
				current_word = ""
		else if(char in punctuation)
			// Punctuation - end current word and add punctuation
			if(length(current_word) > 0)
				groups += length(current_word)
				current_word = ""
			groups += char
		else if(findtext(char, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"))
			// Letter or number - add to current word
			current_word += char
		else
			// Any other character (including Cyrillic) - add to current word
			current_word += char

	// Add any remaining word
	if(length(current_word) > 0)
		groups += length(current_word)

	return groups

/datum/tts_system/proc/get_punctuation_pause(punctuation)
	// Check for punctuation and return pause length
	switch(punctuation)
		if(",")
			return 3
		if(":")
			return 3
		if(";")
			return 2
		if(".")
			return 6
		if("?")
			return 6
		if("!")
			return 6
		if("'")
			return 1
		if("-")
			return 1
		else
			return 0

// Map any input character (Latin/Cyrillic/digit) to uppercase Latin letter A..Z for selecting boop sample

// Helper: check Cyrillic ranges using Unicode codepoints available via text2ascii
/datum/tts_system/proc/_is_cyrillic_upper(c)
	return (c == 1025) || (c >= 1040 && c <= 1071)

/datum/tts_system/proc/_is_cyrillic_lower(c)
	return (c == 1105) || (c >= 1072 && c <= 1103)

/datum/tts_system/proc/map_char_to_letter(ch)
	if(!length(ch))
		return null
	var/c = text2ascii(ch)
	// digits -> map 0..9 to letters A..J
	if(c >= 48 && c <= 57)
		return ascii2text(65 + (c - 48))
	// Latin A-Z
	if(c >= 65 && c <= 90)
		return ch
	// Latin a-z
	if(c >= 97 && c <= 122)
		return uppertext(ch)
	// Cyrillic Ё/ё
	if(c == 1025 || c == 1105)
		return "E"
	// Cyrillic А..Я (1040..1071) -> map roughly by phonetics to Latin
	if(_is_cyrillic_upper(c))
		switch(ch)
			if("А") return "A"
			if("Б") return "B"
			if("В") return "V" // map to V
			if("Г") return "G"
			if("Д") return "D"
			if("Е") return "E"
			if("Ж") return "Z" // zh -> Z
			if("З") return "Z"
			if("И") return "I"
			if("Й") return "I"
			if("К") return "K"
			if("Л") return "L"
			if("М") return "M"
			if("Н") return "N"
			if("О") return "O"
			if("П") return "P"
			if("Р") return "R"
			if("С") return "S"
			if("Т") return "T"
			if("У") return "U"
			if("Ф") return "F"
			if("Х") return "H"
			if("Ц") return "C"
			if("Ч") return "C"
			if("Ш") return "S"
			if("Щ") return "S"
			if("Ъ") return "A"
			if("Ы") return "Y"
			if("Ь") return "I"
			if("Э") return "E"
			if("Ю") return "U"
			if("Я") return "Y"
		return "A"
	// Cyrillic а..я (1072..1103)
	if(_is_cyrillic_lower(c))
		return map_char_to_letter(uppertext(ch))
	return null

// get_word_sound_length no longer used

/datum/tts_system/proc/get_voice_sound(voice, position_index)
	// Prefer per-letter mapping (s_A.wav .. s_Z.wav)
	if(voice_letter_sounds[voice] && length(voice_letter_sounds[voice]))
		var/list/letter_map = voice_letter_sounds[voice]
		var/idx = ((position_index - 1) % 26) + 1
		var/letter = ascii2text(64 + idx) // 'A'..'Z'
		var/path = letter_map[letter]
		if(path)
			return path

	// Fallback to cycling pool
	if(!voice_sounds[voice] || !length(voice_sounds[voice]))
		return null
	var/list/available_sounds = voice_sounds[voice]
	var/sound_count = length(available_sounds)
	var/sound_index = ((position_index - 1) % sound_count) + 1
	var/selected_sound = available_sounds[sound_index]
	return selected_sound

/datum/tts_system/proc/get_sleep_multiplier(voice)
	// These values are tenths of seconds, so 0.5 == 0.05seconds (like original)
	. = 1
	switch(voice)
		if("male_01")
			. = 0.5
		if("male_02")
			. = 0.5
		if("male_03")
			. = 0.5
		if("male_04")
			. = 0.7
		if("male_05")
			. = 0.7
		if("male_06")
			. = 0.6
		if("male_07")
			. = 0.5
		if("female_01")
			. = 0.6
		if("female_02")
			. = 0.7
		if("female_03")
			. = 0.5
		if("ms13effects")
			. = 0.8

/datum/tts_system/proc/_play_one_boop(mob/living/speaker, sound_file, volume_adjusted, range)
	if(!speaker || QDELETED(speaker))
		return
	// Vary = TRUE to add slight pitch variation for more speech-like feel
	playsound(speaker, sound_file, volume_adjusted * 50, TRUE, range)

/datum/tts_system/proc/schedule_mumbleboops(mob/living/speaker, message, voice, volume, message_type)
	if(!speaker || !length(message))
		return

	var/range = get_speech_range(message_type)
	var/volume_adjusted = volume / 100.0

	var/sleep_multiplier = get_sleep_multiplier(voice)

	// Base delays (in deciseconds, like sleep()) – normal tempo
	var/base_letter_delay_ds = max(1, round(2 * sleep_multiplier))
	var/base_word_gap_ds = max(1, round(2 * sleep_multiplier))

	var/list/punctuation = list(",", ":", ";", ".", "?", "!", "'", "-")

	var/cumulative_ds = 0
	for(var/i = 1; i <= length_char(message); i++)
		var/ch = copytext_char(message, i, i + 1)
		if(ch == " ")
			cumulative_ds += base_word_gap_ds
			continue
		if(ch in punctuation)
			var/pp = get_punctuation_pause(ch)
			if(pp > 0)
				cumulative_ds += pp
			continue
		// Map Cyrillic/Latin/digit to a Latin A-Z key
		var/letter = map_char_to_letter(ch)
		if(!letter)
			continue
		var/idx = clamp(text2ascii(letter) - 64, 1, 26)
		var/sound_file = get_voice_sound(voice, idx)
		if(sound_file)
			addtimer(CALLBACK(src, /datum/tts_system/proc/_play_one_boop, speaker, sound_file, volume_adjusted, range), cumulative_ds, TIMER_STOPPABLE)
		// base delay
		cumulative_ds += base_letter_delay_ds

// play_mumbleboops no longer used; replaced by non-blocking schedule

/datum/tts_system/proc/get_speech_range(message_type)
	switch(message_type)
		if("whisper")
			return 1
		if("say")
			return 7
		if("emote")
			return 5
		else
			return 7

// Debug and statistics
/datum/tts_system/proc/debug_voice_loading()
	log_world("TTS: Debug - Available voices: [length(available_voices)]")
	for(var/voice in available_voices)
		var/sound_count = length(voice_sounds[voice])
		log_world("TTS: Debug - Voice [voice]: [sound_count] sounds")

/datum/tts_system/proc/get_statistics()
	var/list/stats = list()
	stats["available_voices"] = length(available_voices)
	stats["loaded_sounds"] = 0
	stats["user_preferences"] = length(user_preferences)

	for(var/voice in voice_sounds)
		stats["loaded_sounds"] += length(voice_sounds[voice])

	return stats

// Client verbs for TTS control
/client/verb/toggle_tts()
	set name = "Toggle TTS"
	set category = "Special Verbs"
	set desc = "Включить или выключить TTS"

	var/mob/living/user = mob
	if(!user)
		to_chat(usr, span_warning("Вы должны быть живым существом для использования TTS."))
		return

	var/datum/component/tts_preferences/prefs = user.GetComponent(/datum/component/tts_preferences)
	if(!prefs)
		prefs = user.AddComponent(/datum/component/tts_preferences)

	var/current_state = prefs.get_pref(TTS_PREF_ENABLED)
	prefs.set_pref(TTS_PREF_ENABLED, !current_state)
	var/new_state = prefs.get_pref(TTS_PREF_ENABLED)

	to_chat(user, span_notice("TTS [new_state ? "включен" : "выключен"]."))

/client/verb/tts_voice()
	set name = "TTS Voice"
	set category = "Special Verbs"
	set desc = "Изменить голос TTS"

	var/mob/living/user = mob
	if(!user)
		to_chat(usr, span_warning("Вы должны быть живым существом для использования TTS."))
		return

	var/datum/component/tts_preferences/prefs = user.GetComponent(/datum/component/tts_preferences)
	if(!prefs)
		prefs = user.AddComponent(/datum/component/tts_preferences)

	var/list/available_voices = GLOB.tts_voices
	var/current_voice = prefs.get_pref(TTS_PREF_VOICE)
	var/new_voice = input(user, "Выберите голос", "TTS Voice", current_voice) as null|anything in available_voices
	if(new_voice)
		prefs.set_pref(TTS_PREF_VOICE, new_voice)
		to_chat(user, span_notice("Голос изменен на [new_voice]."))

/client/verb/test_tts()
	set name = "Test TTS"
	set category = "Special Verbs"
	set desc = "Протестировать TTS"

	var/mob/living/user = mob
	if(!user)
		to_chat(usr, span_warning("Вы должны быть живым существом для использования TTS."))
		return

	var/datum/component/tts_preferences/prefs = user.GetComponent(/datum/component/tts_preferences)
	if(!prefs)
		prefs = user.AddComponent(/datum/component/tts_preferences)

	if(!prefs.get_pref(TTS_PREF_ENABLED))
		to_chat(user, span_warning("TTS выключен. Включите его сначала."))
		return

	var/voice = prefs.get_pref(TTS_PREF_VOICE)
	GLOB.tts_system.process_speech(user, "Hello, this is a test message.", "say")
	to_chat(user, span_notice("Проиграна тестовая фраза голосом [voice]."))

// Admin verbs for TTS management
/client/verb/test_tts_system()
	set name = "Test TTS System"
	set category = "Admin Verbs"
	set desc = "Протестировать систему TTS"

	if(!check_rights(R_ADMIN))
		return

	if(!GLOB.tts_system)
		to_chat(usr, span_warning("TTS система не инициализирована."))
		return

	var/list/stats = GLOB.tts_system.get_statistics()
	to_chat(usr, span_info("=== TTS System Statistics ==="))
	to_chat(usr, span_info("Available voices: [stats["available_voices"]]"))
	to_chat(usr, span_info("Loaded sounds: [stats["loaded_sounds"]]"))
	to_chat(usr, span_info("User preferences: [stats["user_preferences"]]"))

	GLOB.tts_system.debug_voice_loading()

/client/verb/tts_system_info()
	set name = "TTS System Info"
	set category = "Admin Verbs"
	set desc = "Показать информацию о системе TTS"

	if(!check_rights(R_ADMIN))
		return

	to_chat(usr, span_info("=== TTS System Information ==="))
	to_chat(usr, span_info("System enabled: [GLOB.tts_enabled ? "Yes" : "No"]"))
	to_chat(usr, span_info("Available voices: [jointext(GLOB.tts_voices, ", ")]"))

	if(GLOB.tts_system)
		var/list/stats = GLOB.tts_system.get_statistics()
		to_chat(usr, span_info("Loaded sounds: [stats["loaded_sounds"]]"))
		to_chat(usr, span_info("User preferences: [stats["user_preferences"]]"))
	else
		to_chat(usr, span_warning("TTS system not initialized."))
