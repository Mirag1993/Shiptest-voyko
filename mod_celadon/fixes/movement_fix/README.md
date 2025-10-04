# MOVEMENT_LAG_FIX - Исправление бага движения во время лагов

## 🎯 Изначальная проблема

### Описание бага
Во время лагов сервера возникал критический баг движения:
- **Симптом**: Персонаж продолжал двигаться в одну сторону даже после отпускания клавиши движения
- **Условие**: Баг проявлялся только во время лагов сервера
- **Поведение**: Персонаж останавливался только при нажатии клавиши в противоположном направлении
- **Влияние**: Делало игру неиграбельной во время лагов, особенно критично в PvP ситуациях

### Техническая причина
Проблема была в системе обработки движения через переменные `next_move_dir_add` и `next_move_dir_sub`:

1. **При нажатии клавиши** (`keyDown`):
   - Клавиша добавляется в `keys_held`
   - Направление добавляется в `next_move_dir_add`

2. **При отпускании клавиши** (`keyUp`):
   - Клавиша удаляется из `keys_held`
   - Направление добавляется в `next_move_dir_sub`

3. **Каждый тик** (`keyLoop`):
   - Вычисляется `movement_dir` на основе `keys_held`
   - Применяются `next_move_dir_add` и `next_move_dir_sub`
   - Вызывается `Move()`

4. **В `Move()`**:
   - Если движение успешно, `next_move_dir_add` и `next_move_dir_sub` сбрасываются в 0
   - **ПРОБЛЕМА**: Если движение заблокировано (например, из-за `move_delay`), эти переменные НЕ сбрасываются

### Сценарий бага
1. Игрок нажимает клавишу движения → `next_move_dir_add` устанавливается
2. Из-за лага `Move()` возвращает `FALSE` (блокируется `move_delay`)
3. `next_move_dir_add` НЕ сбрасывается
4. Игрок отпускает клавишу → `next_move_dir_sub` устанавливается
5. Но `next_move_dir_add` все еще содержит направление!
6. В `keyLoop` применяется: `movement_dir |= next_move_dir_add` и `movement_dir &= ~next_move_dir_sub`
7. **Результат**: движение продолжается, потому что `next_move_dir_add` не был сброшен

## 🛠️ Решение

### Основной фикс
**Перенос сброса дельт в начало `Move()`**:
```dm
/client/Move(n, direct)
	// [CELADON-EDIT] - MOVEMENT_LAG_FIX - Reset movement direction buffers at the start of every Move() call
	// This prevents movement from continuing after key release during lag
	next_move_dir_add = 0
	next_move_dir_sub = 0
	// [/CELADON-EDIT]
	
	if(world.time < move_delay) //do not move anything ahead of this check please
		return FALSE
```

### Идемпотентный сброс в keyLoop
**Дополнительная защита** - сброс дельт после использования:
```dm
/atom/movable/keyLoop(client/user)
	// ... логика движения ...
	
	// [CELADON-EDIT] - MOVEMENT_LAG_FIX - Idempotent reset: clear deltas after use (one-time per tick)
	user.next_move_dir_add = 0
	user.next_move_dir_sub = 0
	// [/CELADON-EDIT]
```

### Система импульсных шагов (исправление регресса)
**Проблема регресса**: После основного фикса короткие тапы во время лага не давали шага.

**Решение**: Добавлена система импульсных шагов:
```dm
// Новые переменные
var/pending_impulse_dir = 0      // Гарантированный разовый шаг
var/impulse_set_time = 0         // Время установки импульса  
var/impulse_ttl_ticks = 5        // TTL для безопасности

// В keyDown
pending_impulse_dir |= movement
impulse_set_time = world.time

// В keyLoop
if(length(user.keys_held) == 0 && user.pending_impulse_dir)
	if(world.time - user.impulse_set_time <= user.impulse_ttl_ticks)
		movement_dir |= user.pending_impulse_dir
		has_impulse = TRUE
```

### Дополнительные защиты

#### 1. Фокус-рекавери
```dm
// Focus recovery: if keys_held is empty for too long, force stop
if(length(user.keys_held) == 0)
	user.empty_keys_held_ticks++
	if(user.empty_keys_held_ticks >= 2)
		movement_dir = NONE
```

#### 2. Тотальный ресет при смене состояний
```dm
/client/proc/reset_movement_input()
	keys_held.Cut()
	next_move_dir_add = 0
	next_move_dir_sub = 0
	pending_impulse_dir = 0
	impulse_set_time = 0
```

**Вызывается при**:
- Стане (`/datum/status_effect/incapacitating/stun/on_apply()`)
- Параличе (`/datum/status_effect/incapacitating/paralyzed/on_apply()`)
- Стам-крите (`/mob/living/carbon/proc/enter_stamcrit()`)
- Телепортации (`/atom/movable/proc/forceMove()`)

#### 3. Система отладки
```dm
var/debug_movement = FALSE
var/consecutive_move_failures = 0

// Debug verb (admin only)
/client/verb/toggle_movement_debug()
	if(!check_rights(R_DEBUG))
		return
	debug_movement = !debug_movement
```

## ✅ Финальный результат

### Что исправлено
1. **Основной баг**: Персонаж больше не продолжает двигаться после отпускания клавиши во время лагов
2. **Короткие тапы**: Работают корректно даже во время лагов благодаря импульсной системе
3. **Фокус-рекавери**: Автоматическая остановка при потере фокуса окна (Alt-Tab)
4. **Смена состояний**: Движение корректно останавливается при стане/параличе/телепортации
5. **Отладка**: Система диагностики для выявления проблем движения

### Технические улучшения
- **Идемпотентность**: Дельты сбрасываются в двух местах для максимальной надежности
- **Импульсная система**: Гарантирует хотя бы одну попытку шага при коротких тапах
- **TTL защита**: Импульсы автоматически истекают через 5 тиков
- **Правильный порядок**: add → sub для корректной обработки диагоналей
- **Троттлинг**: Отладочные сообщения не спамят чат

### Поведение системы
- **Нормальные условия**: Работает как раньше, без изменений
- **Во время лагов**: Корректно обрабатывает нажатия/отпускания клавиш
- **Короткие тапы**: Гарантируют хотя бы одну попытку движения
- **Долгие удержания**: Работают как обычно
- **Потеря фокуса**: Автоматически останавливает движение через 2 тика

## 📋 Измененные файлы

### Кор код (с тегами CELADON)
- `code/modules/client/client_defines.dm` - новые переменные и функция ресета
- `code/modules/mob/mob_movement.dm` - основной фикс в Move()
- `code/modules/keybindings/bindings_atom.dm` - улучшенная логика keyLoop
- `code/modules/keybindings/bindings_client.dm` - импульсная система в keyDown
- `code/game/atoms_movable.dm` - ресет при телепортации
- `code/datums/status_effects/debuffs.dm` - ресет при стане/параличе
- `code/modules/mob/living/carbon/status_procs.dm` - ресет при стам-крите
- `code/modules/client/verbs/reset_held_keys.dm` - debug команда

### Теги модуляризации
- `[CELADON-EDIT]` - для изменения существующего кода
- `[CELADON-ADD]` - для добавления нового функционала
- ID мода: `MOVEMENT_LAG_FIX`

## 🧪 Тестирование

### Сценарии тестирования
1. **Лаговый спам**: держим Right, создаем искусственный лаг, отпускаем Right во время лага
2. **Противонаправление**: держим Right, во время лага жмем и отпускаем Left
3. **Фокус Alt-Tab**: зажали Up → Alt-Tab → вернулись
4. **Стан/стоп**: при входе в стан с зажатой кнопкой
5. **Телепорт**: в движении телепортируемся
6. **Короткие тапы**: быстрые нажатия во время лага

### Команды для тестирования
```
// Включить отладку движения (admin only)
Toggle Movement Debug

// Ручной ресет ввода (если что-то застряло)
Reset Held Keys
```

## 🏆 Принципы Ленина

Это исправление следует принципам:
- **РЕВОЛЮЦИОННОЙ НЕПРИМИРИМОСТИ** - баг был публично выявлен и уничтожен
- **ПРАКТИКА — КРИТЕРИЙ ИСТИНЫ** - исправление проверено в реальных условиях лагов
- **СОЗНАТЕЛЬНОСТИ** - каждая строка кода имеет объяснимую цель
- **ЦЕНТРАЛИЗМА** - состояние движения централизовано в клиенте
- **ПЛАНОВОСТИ** - система работает по четким циклам и таймерам

## 👨‍💻 Автор
Mirag1993

## 📅 Дата
4 октября 2025 года

## 🔗 Связанные PR
- Основной фикс: [ссылка на PR]
- Системные улучшения: [ссылка на PR]
