# MOVEMENT_LAG_FIX - Технические детали

## 🔧 Архитектура решения

### Переменные клиента
```dm
// Основные дельты движения (существующие)
var/next_move_dir_add = 0
var/next_move_dir_sub = 0

// Новые переменные для импульсной системы
var/pending_impulse_dir = 0      // Гарантированный разовый шаг
var/impulse_set_time = 0         // Время установки импульса (world.time)
var/impulse_ttl_ticks = 5        // TTL для безопасности (5 тиков)

// Переменные для отладки и мониторинга
var/empty_keys_held_ticks = 0    // Счетчик пустых тиков для фокус-рекавери
var/consecutive_move_failures = 0 // Счетчик неудачных попыток движения
var/debug_movement = FALSE       // Флаг отладки
```

### Алгоритм работы

#### 1. KeyDown (нажатие клавиши)
```dm
keys_held[_key] = world.time
next_move_dir_add |= movement
pending_impulse_dir |= movement  // Устанавливаем импульс
impulse_set_time = world.time    // Запоминаем время
```

#### 2. KeyUp (отпускание клавиши)
```dm
keys_held -= _key
next_move_dir_sub |= movement
// Импульс НЕ снимаем - он снимется после попытки движения
```

#### 3. KeyLoop (каждый тик)
```dm
// 1. Базовое направление из held клавиш
movement_dir = keys_held

// 2. Применяем одноразовые дельты
movement_dir |= next_move_dir_add
movement_dir &= ~next_move_dir_sub

// 3. Импульсная система (если held пуст)
if(length(keys_held) == 0 && pending_impulse_dir)
    if(world.time - impulse_set_time <= impulse_ttl_ticks)
        movement_dir |= pending_impulse_dir
        has_impulse = TRUE

// 4. Фокус-рекавери
if(length(keys_held) == 0)
    empty_keys_held_ticks++
    if(empty_keys_held_ticks >= 2)
        movement_dir = NONE

// 5. Санитизация противоположных направлений
if((movement_dir & NORTH) && (movement_dir & SOUTH))
    movement_dir &= ~(NORTH|SOUTH)
if((movement_dir & EAST) && (movement_dir & WEST))
    movement_dir &= ~(EAST|WEST)

// 6. Попытка движения
if(movement_dir)
    move_result = Move(get_step(src, movement_dir), movement_dir)

// 7. Очистка дельт ПОСЛЕ попытки
next_move_dir_add = 0
next_move_dir_sub = 0
if(has_impulse)
    pending_impulse_dir = 0
```

#### 4. Move() (исправленный)
```dm
// УБРАЛИ: сброс дельт в начале Move()
// Теперь дельты сбрасываются только в keyLoop после попытки движения

if(world.time < move_delay)
    return FALSE
// ... остальная логика движения
```

## 🛡️ Защитные механизмы

### 1. Идемпотентность
- Дельты сбрасываются в **двух местах**: в keyLoop после попытки движения
- Это гарантирует, что дельты не "утекут" между тиками

### 2. TTL для импульсов
- Импульсы автоматически истекают через 5 тиков
- Предотвращает бесконечное "залипание" движения
- 5 тиков = ~0.5 секунды при стандартном tick_lag

### 3. Фокус-рекавери
- Если `keys_held` пуст 2+ тика подряд, движение принудительно останавливается
- Защищает от потери KeyUp при Alt-Tab или фризе окна

### 4. Тотальный ресет
- Функция `reset_movement_input()` очищает ВСЕ переменные движения
- Вызывается при критических изменениях состояния (стан, телепорт, etc.)

## 📊 Производительность

### Нагрузка на CPU
- **Минимальная**: Добавлено 3 простых переменных на клиент
- **Логика**: O(1) операции, без циклов или сложных вычислений
- **Память**: ~24 байта на клиент (6 переменных по 4 байта)

### Сетевой трафик
- **Нулевой**: Все переменные локальные, не передаются по сети
- **Совместимость**: Полная обратная совместимость с существующими клиентами

## 🧪 Тестовые сценарии

### 1. Базовый тест лага
```
1. Нажать и удерживать клавишу движения
2. Создать искусственный лаг (sleep в коде)
3. Отпустить клавишу во время лага
4. Дождаться окончания лага
5. Проверить: персонаж должен остановиться
```

### 2. Тест коротких тапов
```
1. Создать искусственный лаг
2. Быстро нажать и отпустить клавишу движения
3. Дождаться окончания лага
4. Проверить: персонаж должен сделать хотя бы один шаг
```

### 3. Тест фокус-рекавери
```
1. Нажать и удерживать клавишу движения
2. Alt-Tab (потеря фокуса)
3. Вернуться в игру через 2+ секунды
4. Проверить: персонаж должен остановиться
```

### 4. Тест смены состояний
```
1. Нажать и удерживать клавишу движения
2. Применить стан/паралич/телепорт
3. Проверить: движение должно остановиться
```

## 🔍 Отладка

### Включение отладки
```
// В игре (admin only)
Toggle Movement Debug

// В коде
client.debug_movement = TRUE
```

### Отладочные сообщения
```
MOVEMENT: keys_held=1, dir=2, impulse=false, empty_ticks=0
MOVEMENT: Total input reset performed
Movement stalled for 15 ticks
```

### Мониторинг переменных
```dm
// Проверка состояния движения
to_chat(user, "keys_held: [length(user.keys_held)]")
to_chat(user, "next_move_dir_add: [user.next_move_dir_add]")
to_chat(user, "next_move_dir_sub: [user.next_move_dir_sub]")
to_chat(user, "pending_impulse_dir: [user.pending_impulse_dir]")
to_chat(user, "impulse_set_time: [user.impulse_set_time]")
to_chat(user, "empty_keys_held_ticks: [user.empty_keys_held_ticks]")
```

## ⚠️ Известные ограничения

### 1. Совместимость с модами
- Моды, которые переопределяют `keyLoop()` или `Move()`, могут конфликтовать
- Рекомендуется тестирование с популярными модами движения

### 2. Производительность при лагах
- При экстремальных лагах (>1 секунды) импульсы могут истекать
- TTL можно увеличить, но это увеличивает риск "залипания"

### 3. Специальные случаи
- Движение через скрипты/админ-команды не затрагивается
- Только пользовательский ввод через клавиатуру

## 🔄 Будущие улучшения

### 1. Адаптивный TTL
```dm
// Динамический TTL в зависимости от лага
var/impulse_ttl_ticks = max(5, world.tick_lag * 2)
```

### 2. Статистика движения
```dm
var/movement_stats = list(
    "total_moves" = 0,
    "failed_moves" = 0,
    "impulse_moves" = 0
)
```

### 3. Конфигурируемость
```dm
// Настройки сервера
var/movement_impulse_enabled = TRUE
var/movement_focus_recovery_ticks = 2
var/movement_debug_enabled = FALSE
```
