/datum/modpack/tts
	name = "TTS - Mumbleboops System"
	desc = "Полноценная система Text-to-Speech с Mumbleboops, адаптированная из Mojave-Sun. Добавляет бубнящие звуки для речи, 7 типов голосов, современный интерфейс настроек и полную интеграцию с системой чата."
	author = "Voyko (адаптация из Mojave-Sun PR #2142)"

/// Инициализация модуля TTS
/// Система автоматически загружается при старте сервера

// Инициализация ДО загрузки других модулей
/datum/modpack/tts/pre_initialize()
	. = ..()
	// Проверяем доступность звуковых файлов
	log_world("TTS: Pre-initializing Mumbleboops system")

// Инициализация ВОВРЕМЯ загрузки
/datum/modpack/tts/initialize()
	. = ..()
	// Инициализируем глобальную систему TTS
	if(!GLOB.tts_system)
		GLOB.tts_system = new /datum/tts_system()
		log_world("TTS: System initialized successfully")
	else
		log_world("TTS: System already exists, skipping initialization")

// Инициализация ПОСЛЕ загрузки всех модулей
/datum/modpack/tts/post_initialize()
	. = ..()
	// Проверяем загрузку звуковых файлов и выводим статистику
	if(GLOB.tts_system)
		GLOB.tts_system.debug_voice_loading()
		var/list/stats = GLOB.tts_system.get_statistics()
		log_world("TTS: Post-initialization complete - [stats["available_voices"]] voices, [stats["loaded_sounds"]] sounds loaded")
	else
		log_world("TTS: WARNING - System not found during post-initialization")
