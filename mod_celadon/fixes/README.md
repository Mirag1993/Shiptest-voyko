

#### Список PRов:

- https://github.com/MysticalFaceLesS/Shiptest/pulls/#####
<!--
  Ссылки на PRы, связанные с модом:
  - Создание
  - Большие изменения
-->

<!-- Название мода. Не важно на русском или на английском. -->
## Fixes - фиксы

ID мода: 
CELADON_FIXES
CELADON_FIXES_BLOOD
FIX_DISPLAY_TRUSTER
FIXES_ICON_IN_HAND_MOB
FIXES_ICON
FIXES_SOUND
MECH_WEAPON
FIXES_CHAMELEON
FIXES_GOLIATH_TENTACLES
FIXES_SHIP_LOGIN_DOUBLE_NAME
FIXES_WETHIDE
<!--
  Название модпака прописными буквами, СОЕДИНЁННЫМИ_ПОДЧЁРКИВАНИЕМ,
  которое ты будешь использовать для обозначения файлов.
-->

### Описание мода

Этот мод Фиксит различные вещи в коде, например крашеры или красную катану.

Weebstick (Красная катана) теперь нельзя сломать, 
вытащив меч при подготовке блинка. (Если что-то сломается всёравно, попросите 
вызвать proc "unprime_unlock" у ближайшего админа)

**Фикс бесконечного спавна мобов при добыче:** Исправляет критический баг с бесконечным спавном мобов при использовании industrial grade mining drill в миссиях. Добавляет проверки завершения миссии во всех ключевых точках логики спавна мобов, а также защиту от продолжения спавна при удалении или поломке бура. Дополнительно производит балансировку жил класса 4 для более справедливой сложности.

<!--
  Что он делает, что добавляет: что, куда, зачем и почему - всё здесь.
  А также любая полезная информация.
-->

### Изменения *кор кода*

- ADD: `code\modules\mining\equipment\kinetic_crusher.dm`: `/obj/item/kinetic_crusher/old/update_icon_state()` -> `..()`
- REMOVE: `code\modules\mining\equipment\kinetic_crusher.dm`: `/obj/item/kinetic_crusher/old/update_icon_state()` -> `return ..()`

- ADD: `code\modules\mining\equipment\kinetic_crusher.dm`: `/obj/item/kinetic_crusher/syndie_crusher/update_icon_state()` -> `..()`
- REMOVE: `code\modules\mining\equipment\kinetic_crusher.dm`: `/obj/item/kinetic_crusher/syndie_crusher/update_icon_state()` -> `return ..()`

- EDIT: `code\modules\projectiles\ammunition\caseless\_caseless.dm`: `/obj/item/ammo_casing/caseless/on_eject()`


- ADD: `code\modules\clothing\suits\hoodies.dm`: `/obj/item/clothing/suit/hooded/hoodie/rilena` -> чиним офов, пропущенный стэйт иконки.

- ADD: `code\game\machinery\shuttle\shuttle_engine.dm`: `var/engine_type=`
- ADD: `code\game\machinery\shuttle\shuttle_engine.dm`: `/obj/machinery/power/shuttle/engine/proc/plasma_thrust`
- EDIT: `code\game\machinery\shuttle\shuttle_engine_types.dm`: `/obj/machinery/power/shuttle/engine/fueled/burn_engine`-> `return resolved_heater.consume_fuel(to_use, fuel_type)`
- ADD: `code\game\machinery\shuttle\shuttle_engine_types.dm`: `/obj/machinery/power/shuttle/engine/fueled/plasma`-> `engine_type = "plasma"`
- ADD: `code\game\machinery\shuttle\shuttle_engine_types.dm`: `/obj/machinery/power/shuttle/engine/fueled/plasma/plasma_thrust`
- EDIT: `code\modules\overmap\ships\controlled_ship_datum.dm`: `/datum/overmap/ship/controlled/burn_engines` -> `Добавлена логика`
- EDIT: `tgui\packages\tgui\interfaces\HelmConsole.js`: `estThrust * 500`-> `estThrust * 1600`
- EDIT: `tgui\packages\tgui\interfaces\HelmConsole.js`: ` format={(value) => value.toFixed(1)}` -> ` format={(value) => value.toFixed(2)}`

- ADD: `code\modules\projectiles\guns\ballistic\revolver.dm` : `/obj/item/gun/ballistic/revolver/proc/insert_casing` -> `проверка на калибр`

- EDIT: `code\modules\mining\equipment\explorer_gear.dm` : `/obj/item/clothing/mask/gas/explorer/adjustmask(user)` -> Исправлен баг с размерами газ масок при снятие фильтров
- EDIT: `code\modules\projectiles\ammunition\ballistic\rifle.dm` - исправление калибра
- EDIT: `code\modules\projectiles\boxes_magazines\external\rifle.dm` - - исправление калибра

- REMOVE: `code\game\machinery\newscaster.dm` - Полная замена на переведённый файл. Пожалуйста, сделайте это нормально.

- REMOVE: `code\game\objects\items\kitchen.dm` - Исправляет спрайт ножа.

- REMOVE: `code/modules/vending/_vending.dm` - вынос в родителя переменной

- ADD: `code\__HELPERS\text.dm` - Добавляем возможность создания имён персонажей на кирилице.
- EDIT: `code\modules\admin\player_panel.dm` - Фикс <meta>, исправлено отображение кирилицы на F6.

- EDIT: `code\game\objects\structures.dm` - Исправляет односторониие перила путям отключения одной строчки кода.

- EDIT: `code/modules/research/rdconsole.dm` - Попытка изменить абьюз, когда игрок мог внести семена сколько угодно раз, пересобирая тупо консоль. Сделано через глобальный список.

- EDIT: `code/modules/research/designs.dm` - [CELADON-EDIT] - CELADON_FIXES - Инициализация `obj/item/disk/design_disk/Initialize()` переписана на фиксированный индексный список слотов `1..max_blueprints` без ассоциативных ключей. `starting_blueprints` раскладываются по индексам, оставшиеся слоты `null`.
- EDIT: `code/modules/research/rdconsole.dm` - [CELADON-EDIT] - CELADON_FIXES -
  - `ui_designdisk()` теперь рисует строго по индексам 1..max_blueprints и нормализует длину `blueprints.len = max_blueprints`.
  - `copy_design` записывает дизайн строго по индексу слота без сжатия списка.
  - `clear_design` очищает либо все слоты, либо один слот установкой `null` по индексу; не используется `list -= value`.

- ADD: `/obj/machinery/computer/telecomms/server/ui_interact` - Добавляем поддержку UTF-8
- ADD: `/obj/machinery/computer/telecomms/monitor/ui_interact` - Добавляем поддержку UTF-8

- REMOVE: `code/modules/client/verbs/looc.dm` - Убрано пару проверок. Разрешаем писать в LOOC будучи призраком.

- EDIT: `code/modules/overmap/objects/event_datum.dm` - Выносим в отдельные родители ивенты, для корректной работы миссий на изучение

- REMOVE: `code/modules/clothing/outfits/standard.dm` : `W.registered_name = H.real_name`, `W.update_label()` - Вызывают рантаймы

- EDIT: `code/game/objects/items/devices/taperecorder.dm` - Изменение рекордера, дабы тот более не мог переводить другие языки

- EDIT: `code\modules\hydroponics\gene_modder.dm` - Добавление удаления мусора а не данных с диска

- EDIT: `code\modules\hydroponics\grown\replicapod.dm` - Исправление отобрежения ДНК на сканере

MECH_WEAPON
### Исправление бага перезарядки мех-оружия (SOB-3, BRM-6, SGL-6)
**Проблема:** Оружие с `disabledreload = TRUE` (SOB-3 Clusterbang, BRM-6 Missile Rack, SGL-6 Flashbang) не могло быть перезаряжено из-за отсутствия переменной `projectiles`, что приводило к `projectiles_max = 0` и неправильной работе логики `ammo_resupply()`.
**Решение:** Добавлены недостающие переменные `projectiles` для корректной работы автоматической инициализации `projectiles_max`.
**Изменения:**
- ADD: `code/game/mecha/equipment/weapons/weapons.dm`: `/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/breaching` -> `projectiles = 6` (с тегом `[CELADON-ADD]`)
- ADD: `code/game/mecha/equipment/weapons/weapons.dm`: `/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/flashbang` -> `projectiles = 6` (с тегом `[CELADON-ADD]`)
- ADD: `code/game/mecha/equipment/weapons/weapons.dm`: `/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/flashbang/clusterbang` -> `projectiles = 3` (с тегом `[CELADON-ADD]`)
**Автор:** Турон/Mirag1993

- EDIT: `code\modules\hydroponics\grown\replicapod.dm` - Исправлено появление людей из капусты

- EDIT: `code/modules/mob/living/carbon/human/human_movement.dm` - Учитывается влияние обуви на гравитацию

- ADD: `code/modules/mob/living/life.dm` - Добавление magboots_handle_gravity

- EDIT: `code/modules/overmap/objects/event_datum.dm`

- EDIT: `code/modules/missions/outpost/research_mission.dm` - Окргуление координат

- ADD: `code/datums/looping_sounds/machinery_sounds.dm` - Гравген во включённом состоянии жужжит.
- ADD: `code/game/machinery/shuttle/ship_gravity.dm` - Гравген во включённом состоянии слегка светится, жужжит, а "интерфейс" светится в темноте. А также добавлено взаимодействие с ЕМП, при котором с 50% шансом он переключится.
- ADD: `code/game/mecha/equipment/tools/mining_tools.dm` Мех с активной дрелью теперь копает камень.
- ADD: `code/game/objects/structures/crates_lockers/closets.dm` Мехи теперь нельзя пихать в ящики.
- ADD: `code/modules/projectiles/gun.dm` - Действие прицеливания теперь выдаётся только когда оружие держится в двух руках.
- EDIT: `code/game/atoms_movable.dm` - В космосе теперь нельзя передвигаться за счёт взаимно пульнутых мобов

- EDIT: `code/modules/clothing/head/helmet.dm` - Отображение оверлеев

- EDIT: `code/modules/surgery/surgery_step.dm` - Исправление ухода операции в бесконечный цикл

- EDIT: `code/modules/mob/living/carbon/human/species_types/kepori.dm` : Делаем так чтобы кепори могли брать мелкие предметы в клюв

- EDIT, ADD: `code/modules/mob/living/blood.dm` : Вводим нормальный уровень для крови
- EDIT, ADD: `code/game/machinery/iv_drip.dm` : Проверка крови у пациента
- ADD: `code/modules/reagents/chemistry/holder.dm` : Вводим ограничения на шприцы, бикеры, капельницы

- ADD: `code/game/objects/items/food/donut.dm` : Прописано название стандартной иконки, вместо надписи ERROR

- ADD: `code/controllers/subsystem/overmap.dm` : Прерывает удаление планеты при начале ее генерации.

FIX_DISPLAY_TRUSTER
- EDIT: `code/modules/overmap/ships/controlled_ship_datum.dm` : Откатывает на прежнее отображение скорости, у нас другой вид перемещения корабликов

FIXES_ICON_MOB_IN_HAND
- EDIT: `code/__HELPERS/dynamic_human_icon_gen.dm` : Прописано название стандартной иконки, вместо надписи ERROR

FIXES_ICON
- EDIT: `code/modules/clothing/suits/toggles.dm` - СУКА ИЗ-ЗА ЭТОГО СЛОМАЛИСЬ ВСЕ КАПЮШОНЫ

FIXES_SOUND
- ADD:	`code/game/objects/items/melee/trickweapon.dm` - Баг звука энерго меча у пилы
- EDIT:	`code/game/objects/items/melee/trickweapon.dm` - Новые звуки открытия/закрытия пилы

FIXES_CHAMELEON
- EDIT: `code/datums/mutations/chameleon.dm` - Чиним крит баг с вечной невидимостью

FIXES_GOLIATH_TENTACLES
- ADD: `code/modules/mob/living/simple_animal/hostile/mining_mobs/goliath.dm` : Добавляем прок и прверки на жизненный цикл тентакли и её создателя
FIXES_SHIP_LOGIN_DOUBLE_NAME
- ADD: `code/modules/mob/dead/new_player/ship_select.dm` : Поднимаем проверку на одинаковые имена ДО создания корабля, чтобы избежать спавна изолированного корабля

FIXES_WETHIDE
- EDIT: `code/modules/food_and_drinks/kitchen_machinery/smartfridge.dm` : Заменен устаревший метод `update_icon()` на `update_appearance()`
- EDIT: `code/game/objects/items/stacks/sheets/leather.dm` : Исправлен неправильный путь класса. Изменено `/obj/item/stack/sheet/leather/wetleather/Initialize` на `/obj/item/stack/sheet/wethide/Initialize`. Это позволяет мокрой коже правильно добавить элемент `dryable` при инициализации

**Фикс бесконечного спавна мобов при добыче:**
- ADD: `code/modules/mining/drill.dm` - Добавлена проверка завершения миссии в `process()` и вызов `stop_spawning()` в `Destroy()`
- ADD: `code/modules/mining/ore_veins.dm` - Добавлены проверки завершения миссии в `begin_spawning()`, `process()` и `increment_wave_tally()`
- ADD: `code/modules/missions/dynamic/signaled.dm` - Добавлен вызов `stop_spawning()` при завершении миссии в `mine_success()`
- EDIT: `code/modules/mining/ore_veins.dm` - Добавлена проверка `QDELETED(our_drill)` в `increment_wave_tally()` для защиты от удаленных буров
- EDIT: `code/modules/mining/ore_veins.dm` - Балансировка жил класса 4: `max_mobs = 4` (было 6), `spawn_time = 12 SECONDS` (было 8), `wave_length = 30 SECONDS` (было 45)

<!--
  Если вы редактировали какие-либо процедуры или переменные в кор коде,
  они должны быть указаны здесь.
  Нужно указать и файл, и процедуры/переменные.

  Изменений нет - напиши "Отсутствуют"
-->

### Оверрайды

- `mod_celadon/fixes/code/research_mission.dm` - вроде перезаписывает

<!-- fax_name -->
<!-- 
- `code\controllers\subsystem\overmap.dm`: `proc/spawn_ship_at_start`,
- `code\modules\paperwork\fax.dm`: `proc/connect_to_shuttle`
 -->
<!--
  Если ты добавлял новый модульный оверрайд, его нужно указать здесь.
  Здесь указываются оверрайды в твоём моде и папке `_master_files`

  Изменений нет - напиши "Отсутствуют"
-->

### Дефайны

<!-- fax_name -->
<!-- - `code/__defines/~mod_celadon/ship.dm` -->
- `code/__DEFINES/radio.dm` - Переименование частоты SolGov -> SolFed

<!--
  Если требовалось добавить какие-либо дефайны, укажи файлы,
  в которые ты их добавил, а также перечисли имена.
  И то же самое, если ты используешь дефайны, определённые другим модом.

  Не используешь - напиши "Отсутствуют"
-->

### Используемые файлы, не содержащиеся в модпаке

- `mod_celadon/crusher_trophy/code/kinetic_crusher.dm`
<!--
  Будь то немодульный файл или модульный файл, который не содержится в папке,
  принадлежащей этому конкретному моду, он должен быть упомянут здесь.
  Хорошими примерами являются иконки или звуки, которые используются одновременно
  несколькими модулями, или что-либо подобное.
-->

### Авторы:


RalseiDreemuurr, Mirag1993 , Корольный крыс, MrCat15352, MysticalFaceLesS, Burbonchik, MrRomainzZ, Molniz, Redwizz, Sjerty, Garomt, Ganza9991, KOCMOHABT

- Автор фикса дисков дизайнов: Турон/Mirag1993
- Автор фикса бесконечного спавна мобов: Турон/Mirag1993

<!--
  Здесь находится твой никнейм
  Если работал совместно - никнеймы тех, кто помогал.
  В случае порта чего-либо должна быть ссылка на источник.
-->
