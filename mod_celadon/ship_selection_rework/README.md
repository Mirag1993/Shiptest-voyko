#### Список PRов

- https://github.com/CeladonSS13/Shiptest/pulls/##### (основной PR)
<!--
  Ссылки на PRы, связанные с модом:
  - Создание и развитие системы выбора профессий
  - Добавление модальных окон с защитой от дублирования
  - Интеграция системы заявок на конкретные профессии
-->

## Ship Selection Rework

ID мода: CELADON_SHIP_SELECTION_REWORK
<!--
  Модуль переработки системы выбора кораблей с добавлением:
  - Современного интерфейса с группировкой по фракциям
  - Системы заявок на конкретные профессии
  - Защиты от дублирования действий
  - Автообновления UI при изменении статусов заявок
-->

### Описание мода

Полная переработка интерфейса выбора кораблей в SS13 с добавлением:

**Основные возможности:**
- Двухэтапный выбор: сначала фракция, потом корабль
- Система заявок на конкретные профессии 
- Современный дизайн с карточками и бейджами
- Автоматическое обновление статусов заявок
- Защита от дублирования действий и спама

**Job Selection System:**
- Подача заявок на конкретные профессии
- Статусы: Apply → Pending → Approved/Denied → Select
- Кнопка отмены для pending заявок
- Префикс профессии в тексте заявки (например: "Vanguard: Хочу служить")
- Возможность подавать заявки на несколько профессий

**UI/UX Улучшения:**
- Группировка кораблей по 8 фракциям с цветовыми схемами
- Интерактивная схема отношений между фракциями
- Адаптивная верстка с современными компонентами
- Бейджи для отображения статусов, времени игры, офицерских ролей
- Автообновление интерфейса без перезагрузки

### Используется в других проектах?
- Нет
<!--
  Система может быть портирована на другие SS13 сервера
  с аналогичной системой кораблей
-->

### Изменения *кор кода*

- `code/modules/asset_cache/asset_list_items.dm`: добавлен `datum/asset/simple/faction_logos` с загрузкой 8 логотипов фракций
- `code/modules/overmap/ships/ship_application.dm`: 
  - добавлена переменная `var/datum/job/target_job` для хранения целевой профессии
  - дополнен `proc/ui_data()` передачей `job_name` в интерфейс
  - дополнен `proc/application_status_change()` автообновлением Ship Select UI
<!--
  Все изменения обёрнуты в теги [CELADON-EDIT] - SHIP_SELECTION_REWORK
  для простоты отслеживания и возможного отката изменений
-->

### Оверрайды

- `mod_celadon/_master_files/code/modules/mob/dead/new_player/ship_select.dm`: 
  - `proc/ui_act()` - перехват и защита join/apply_for_job/cancel_job_application actions
  - `proc/ui_data()` - добавление динамических данных о статусах заявок
  - `proc/handle_protected_join()` - защищённая обработка присоединения к кораблю
  - `proc/handle_protected_job_application()` - обработка заявок на профессии
  - `proc/handle_cancel_job_application()` - отмена заявок
  - `proc/handle_open_faction()` - выбор фракции
  - `proc/handle_back_factions()` - возврат к списку фракций
  - `var/selected_faction` - хранение выбранной фракции

- `code/modules/overmap/ships/ship_application.dm`:
  - `var/target_job` - добавлено поле для хранения целевой профессии
  - `proc/ui_data()` - передача job_name в интерфейс
  - `proc/application_status_change()` - автообновление Ship Select UI

### Дефайны

- Используются существующие: `SHIP_APPLICATION_*` константы из `code/__DEFINES/overmap.dm`
<!--
  SHIP_APPLICATION_UNFINISHED, SHIP_APPLICATION_PENDING, 
  SHIP_APPLICATION_ACCEPTED, SHIP_APPLICATION_DENIED
-->

### Используемые файлы, не содержащиеся в модпаке

- `tgui/packages/tgui/interfaces/ShipSelect.js` - основной интерфейс выбора кораблей
- `tgui/packages/tgui/interfaces/FactionButtons.js` - компонент кнопок фракций  
- `tgui/packages/tgui/interfaces/Application.js` - модальное окно заявки
- `mod_celadon/_storge_icons/icons/assets/logo/*.png` - логотипы фракций (96x64px)

### Технические особенности

**Frontend (TGUI):**
- React компоненты с useBackend/useLocalState
- Защита от дублирования через nonce и client-side locks
- Динамическое обновление статусов через jobApplicationStatuses
- Современный дизайн с Flex/Box/Section компонентами

**Backend (DM):**
- Система статических locks (join_lock_by_ckey, processed_nonces)
- Interceptor pattern для перехвата actions
- Защита от race conditions и спама
- Автоматическое обновление UI через SStgui.send_update()

**Безопасность:**
- Nonce фильтрация против replay атак  
- Client-side single-flight protection
- Server-side locks с timeout'ами
- Валидация всех входящих параметров

### Авторы

Voyko/Assistant
<!--
  Разработано как комплексное решение для модернизации
  системы выбора кораблей в Shiptest SS13
-->
