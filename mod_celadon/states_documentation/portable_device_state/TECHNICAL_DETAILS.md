# Технические детали состояний UI

## Структура файла состояния

```dm
/**
 * tgui state: portable_device_state
 *
 * Checks that the src_object is in the user's inventory
 * and that the user is conscious. Allows UI interaction
 * for lying characters. Suitable for portable devices
 * like radios, PDAs, tablets, scanners, etc.
 *
 * Copyright (c) 2024 Mirag1993
 * SPDX-License-Identifier: MIT
 */

GLOBAL_DATUM_INIT(portable_device_state, /datum/ui_state/portable_device_state, new)

/datum/ui_state/portable_device_state/can_use_topic(src_object, mob/user)
	if(!(src_object in user))
		return UI_CLOSE
	if(user.stat != CONSCIOUS)
		return UI_CLOSE
	return UI_INTERACTIVE
```

## Анализ логики

### Проверка инвентаря
```dm
if(!(src_object in user))
	return UI_CLOSE
```
- **Цель**: Убедиться, что предмет находится у пользователя
- **Проверяет**: Наличие предмета в инвентаре (руки, карманы, слоты)
- **Возвращает**: `UI_CLOSE` если предмет не у пользователя

### Проверка сознания
```dm
if(user.stat != CONSCIOUS)
	return UI_CLOSE
```
- **Цель**: Убедиться, что пользователь в сознании
- **Проверяет**: `user.stat == CONSCIOUS` (значение 0)
- **Возвращает**: `UI_CLOSE` если пользователь без сознания

### Успешное взаимодействие
```dm
return UI_INTERACTIVE
```
- **Цель**: Разрешить полное взаимодействие с UI
- **Возвращает**: `UI_INTERACTIVE` для активного UI

## Сравнение с другими состояниями

| Состояние | Инвентарь | Сознание | Лежачее | Описание |
|-----------|-----------|----------|---------|----------|
| `inventory_state` | Да | Да | Нет | Стандартное состояние |
| `conscious_state` | Нет | Да | Да | Только сознание |
| `portable_device_state` | Да | Да | Да | Наше состояние |

## Возвращаемые значения

### UI_INTERACTIVE
- **Описание**: UI полностью активен
- **Пользователь может**: Кликать, вводить данные, взаимодействовать
- **Используется**: Когда все проверки пройдены

### UI_CLOSE
- **Описание**: UI закрыт
- **Пользователь может**: Ничего
- **Используется**: Когда проверки не пройдены

### UI_UPDATE
- **Описание**: UI виден, но неактивен
- **Пользователь может**: Только смотреть
- **Используется**: В других состояниях для лежачих

## Цепочка вызовов

```
ui_interact() 
  → ui_state() 
    → GLOB.portable_device_state 
      → can_use_topic() 
        → UI_INTERACTIVE/UI_CLOSE
```

## Производительность

### Сложность: O(1)
- **Проверка инвентаря**: O(1) - простая проверка `in`
- **Проверка сознания**: O(1) - сравнение значения
- **Общая сложность**: O(1)

### Память: Минимальная
- **Глобальный датум**: Один экземпляр на сервер
- **Дополнительные переменные**: Отсутствуют

## Тестирование

### Тестовые сценарии:

1. **Сознательный стоящий пользователь с предметом**
   - **Ожидается**: `UI_INTERACTIVE`
   - **Результат**: Успешно

2. **Сознательный лежащий пользователь с предметом**
   - **Ожидается**: `UI_INTERACTIVE`
   - **Результат**: Успешно

3. **Без сознания пользователь с предметом**
   - **Ожидается**: `UI_CLOSE`
   - **Результат**: Успешно

4. **Сознательный пользователь без предмета**
   - **Ожидается**: `UI_CLOSE`
   - **Результат**: Успешно

## Отладка

### Логирование:
```dm
/datum/ui_state/portable_device_state/can_use_topic(src_object, mob/user)
	if(!(src_object in user))
		log_debug("UI closed: object not in user inventory")
		return UI_CLOSE
	if(user.stat != CONSCIOUS)
		log_debug("UI closed: user not conscious (stat: [user.stat])")
		return UI_CLOSE
	log_debug("UI interactive: all checks passed")
	return UI_INTERACTIVE
```

### Проверка состояния:
```dm
/mob/proc/check_ui_state(obj/item/device)
	var/datum/ui_state/state = device.ui_state(src)
	var/result = state.can_use_topic(device, src)
	to_chat(src, "UI State: [result]")
```

## Рекомендации по использованию

### DO:
- Используйте для портативных устройств
- Тестируйте в различных состояниях
- Документируйте изменения

### DON'T:
- Не используйте для стационарных устройств
- Не изменяйте логику без тестирования
- Не забывайте про проверку инвентаря

## Будущие улучшения

### Возможные расширения:
1. **Проверка расстояния**: Для предметов в руках
2. **Проверка рук**: Для устройств, требующих рук
3. **Проверка батареи**: Для электронных устройств
4. **Проверка повреждений**: Для сломанных устройств

### Пример расширенного состояния:
```dm
/datum/ui_state/advanced_portable_device_state/can_use_topic(src_object, mob/user)
	if(!(src_object in user))
		return UI_CLOSE
	if(user.stat != CONSCIOUS)
		return UI_CLOSE
	if(istype(src_object, /obj/item/device) && src_object.battery && src_object.battery.charge <= 0)
		return UI_CLOSE
	return UI_INTERACTIVE
```

---

**Помните**: Всегда тестируйте изменения в различных игровых ситуациях!
