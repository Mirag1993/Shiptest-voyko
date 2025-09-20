// ========================================
// Утилиты логирования модуля кобур (UTF-8 без BOM)
// ========================================

#ifndef __HOLSTER_LOGGING_INCLUDED
#define __HOLSTER_LOGGING_INCLUDED

// Уровни логирования
#define HOLSTER_LOG_ERROR 1
#define HOLSTER_LOG_WARNING 2
#define HOLSTER_LOG_INFO 3
#define HOLSTER_LOG_DEBUG 4

// Глобальный уровень логирования (можно переопределить)
#ifndef HOLSTER_LOG_LEVEL
#define HOLSTER_LOG_LEVEL HOLSTER_LOG_INFO
#endif

// Макрос логирования (нужен явный user; не использовать usr)
#define HOLSTER_LOG(level, user, message) \
	do { \
		if((level) <= HOLSTER_LOG_LEVEL) { \
			log_holster_operation((level), (message), src, (user)); \
		} \
	} while(FALSE)

// Функция логирования
/proc/log_holster_operation(level, message, obj/source, mob/user)

	var/timestamp = time2text(world.timeofday, "hh:mm:ss")
	var/location = source ? "[source.type] at [source.loc]" : "unknown"
	var/user_info = user ? "[user.ckey] ([user.name])" : "no user"

	var/log_message = "[timestamp] HOLSTER [level]: [message] | Source: [location] | User: [user_info]"

	// Консоль
	log_world(log_message)

	// Ошибки/предупреждения также пишем в файл
	if(level <= HOLSTER_LOG_WARNING)
		WRITE_LOG(GLOB.world_game_log, log_message)

#endif // __HOLSTER_LOGGING_INCLUDED

