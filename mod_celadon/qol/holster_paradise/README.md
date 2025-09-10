
#### Список PRов:

- https://github.com/MysticalFaceLesS/Shiptest/pulls/#####

## Модуль кобур Paradise

Система кобур в стиле Paradise 220. Полная замена стандартной системы Shiptest.

ID мода: CELADON_HOLSTER_PARADISE

## Что делает:
- Заменяет стандартные кобуры Shiptest
- Добавляет клавишу H для быстрого доступа
- Проверяет размер оружия (только маленькое и нормальное)
- Поддерживает разные типы кобур

## Файлы:
- `_holster_paradise.dm` - главный файл, включает все части
- `code/holster_types.dm` - типы кобур (обычная, детектив, нюкер)
- `code/holster_keybind.dm` - клавиша H и логика работы
- `code/holster_weapon_types.dm` - какие пушки можно кобурить
- `code/holster_components.dm` - кнопки действий

## Особенности:
- **Обычные кобуры**: только TINY/SMALL/NORMAL оружие
- **Кобура нюкера**: принимает даже BULKY оружие
- **Все кобуры**: МАКСИМУМ 1 предмет
- **Клавиша H**: прячет/достает оружие из активной руки

## Как использовать:
1. Надень кобуру на униформу
2. Возьми пистолет в руку
3. Нажми H - оружие спрячется в кобуру
4. Нажми H еще раз - оружие достанется обратно

## Изменения *кор кода*

### Закомментированные оригинальные кобуры:
- EDIT: `code/modules/clothing/under/accessories.dm` - Закомментированы все определения типов кобур (`/obj/item/clothing/accessory/holster`, detective, nukie, chameleon)
- EDIT: `code/datums/components/storage/concrete/pockets.dm` - Закомментированы определения кобур в компонентах хранения (`/datum/component/storage/concrete/pockets/holster`)

### Изменения для клавиши H:
- EDIT: `code/controllers/subsystem/input.dm` - Изменена клавиша "Stop pulling" с H на C в `default_hotkeys`
- EDIT: `code/datums/keybinding/mob.dm` - Изменены `hotkey_keys` для `/datum/keybinding/mob/stop_pulling` с `list("H", "Delete")` на `list("C", "Delete")`

### Добавления для новой системы кобур:
- ADD: `code/__DEFINES/keybinding.dm` - Добавлен сигнал `COMSIG_KB_HUMAN_HOLSTER_DOWN`
- EDIT: `code/modules/mob/living/carbon/human/human.dm` - Добавлена регистрация сигнала и обработчик `handle_holster_keybind()` в `Initialize()`

## Автор:
Mirag1993

## Оверрайды

Отсутствуют

## Дефайны

- ADD: `code/__DEFINES/keybinding.dm` - `COMSIG_KB_HUMAN_HOLSTER_DOWN`

## Используемые файлы, не содержащиеся в модпаке

Отсутствуют
