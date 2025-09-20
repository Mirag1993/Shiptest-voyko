### Holster Paradise (Celadon QoL) — документация

- ID модуля: `CELADON_HOLSTER_PARADISE`
- Замена стандартной системы кобур на стиль Paradise‑220.

### Ключевые изменения

- Хоткей кобуры настраиваемый (Unbound по умолчанию). Stop pulling остаётся на H.
- Вся логика действий — в методах кобуры; keybind/action только делегируют.
- Централизованное логирование и обработка ошибок.
- Поиск storage вынесен в `get_storage_component()` с кэшированием и правильной инвалидацией.
- Параметры ограничений на типе кобуры:
  - `max_allowed_w_class`
  - `allow_fullauto`
  - `min_weapon_weight`, `max_weapon_weight`
  - `allowed_typecache` (typecache разрешённых типов оружия)

### Поведение (коротко)

- Извлечение:
  - Если в кобуре есть предмет, хоткей/действие сначала пытается достать его (даже если активная рука занята — предмет из руки будет сброшен по логике ниже).
  - Если кобура пуста и в активной руке есть предмет — будет попытка убрать его в кобуру.
- Спрятать в кобуру: соблюдает `can_holster()` и ограничения типа/веса/режимов.
- Достать из кобуры: единая реализация в `unholster()`.

### Интенты и руки

- Non-HARM: при извлечении, если активная рука занята, предмет в активной руке сбрасывается на пол, оружие кладётся в активную руку; если невозможно — в неактивную; если и это невозможно — на пол.
- HARM: при извлечении очищаются обе руки (оба предмета сбрасываются), оружие кладётся в активную руку и, если у него есть компонент `/datum/component/two_handed`, автоматически берётся в две руки.
- Заблокированные руки (наручники, эффекты): извлечение и прятание запрещены; выводится предупреждение.

### Хоткей и приоритеты

- Хоткей Unbound: игрок настраивает сам.
- При нажатии:
  - Если в кобуре есть предмет — приоритет на извлечение.
  - Иначе — если в руке предмет — попытка спрятать.
  - Иначе — попытка извлечения (сообщение, если кобура пуста).
- Анти‑дребезг: `mob/var/holster_processing` предотвращает двойную обработку в один тик.

### Централизованные сообщения

- **Константы ошибок:** `HOLSTER_FAIL_NO_HOLSTER`, `HOLSTER_FAIL_UNINIT`, `HOLSTER_FAIL_DISABLED`, `HOLSTER_FAIL_NESTED`, `HOLSTER_FAIL_EMPTY`, `HOLSTER_FAIL_BROKEN_ITEM`, `HOLSTER_FAIL_CANT_TAKE`
- **Константы успеха:** `HOLSTER_OK_PUT`, `HOLSTER_OK_TAKE`
- **Глобальные роутеры:**
  - `holster_notify_fail(mob/M, reason, obj/item/I)` — для случаев без доступа к экземпляру кобуры
  - `holster_notify_success(mob/M, reason, obj/item/I)` — для позитивных сообщений
- **Метод кобуры:** `notify_fail(mob/user, reason, obj/item/I)` — централизованная обработка ошибок

### Helper функции

- `has_contents(var/datum/component/storage/STR)` — проверка наличия предметов в кобуре
- `place_item_in_hands(mob/user, obj/item/I)` — размещение предмета в руках пользователя
- `invalidate_storage_cache()` — инвалидация кэша storage компонента
- `can_use_holster(mob/user, require_free_active_hand, allow_hands_blocked)` — проверка возможности использования кобуры

### Логирование

- Макрос: `HOLSTER_LOG(level, user, message)`
- Уровни: ERROR, WARNING, INFO, DEBUG
- **Управление DEBUG логами:** `HOLSTER_DEBUG` (0/1) и макрос `HOLSTER_DBG()`
- Никогда не использовать `usr`; всегда передавать явный `mob`.

### Кэширование

- `cached_storage` с TTL: `cache_duration_ticks = HOLSTER_STORAGE_CACHE_TICKS` (5 SECONDS)
- Инвалидация при `attach/detach`, `Destroy()` и через `invalidate_storage_cache()`
- Безопасная проверка `QDELETED()` и TTL

### Проверка состояний

- `can_use_holster(user, require_free_active_hand)` — используется в `can_holster()`, `holster()`, `unholster()`, action, verb; блокирует действия при недоступных/заблокированных руках.
- Возвращает коды ошибок (`HOLSTER_FAIL_*`) вместо boolean для детальной диагностики.

### Звуки

- Константы: `HOLSTER_SND_IN`, `HOLSTER_SND_OUT`, `HOLSTER_SND_VOL`.

### Миграция (из старого PR)

- Отменён ребинд H→C; хоткей кобуры оставлен Unbound, чтобы игрок сам назначил.
- Убран дублирующий поиск storage; добавлен `get_storage_component(user)`.
- Безопасная логика достания предмета перенесена в `unholster()`.
- Добавлена полная централизация сообщений и helper функций.

### Файлы

- `mod_celadon/qol/holster_paradise/code/holster_types.dm` — основные типы кобур, логика, helper функции
- `mod_celadon/qol/holster_paradise/code/holster_keybind.dm` — система хоткеев
- `mod_celadon/qol/holster_paradise/code/holster_components.dm` — action компоненты

### Архитектура

- **Единый источник истины** для всех проверок состояния пользователя
- **DRY принцип** — устранено дублирование кода
- **Централизованная обработка ошибок** через константы и роутеры
- **Безопасное кэширование** с автоматической инвалидацией
- **Консистентная логика** во всех точках входа (keybind, action, verb)
