# Примеры использования portable_device_state

## Базовые примеры

### 1. Рация
```dm
/obj/item/radio/ui_state(mob/user)
	return GLOB.portable_device_state
```

### 2. PDA
```dm
/obj/item/pda/ui_state(mob/user)
	return GLOB.portable_device_state
```

### 3. Планшет
```dm
/obj/item/tablet/ui_state(mob/user)
	return GLOB.portable_device_state
```

## Продвинутые примеры

### 4. Портативный сканер
```dm
/obj/item/analyzer/ui_state(mob/user)
	return GLOB.portable_device_state
```

### 5. Гарнитура
```dm
/obj/item/radio/headset/ui_state(mob/user)
	return GLOB.portable_device_state
```

### 6. Портативный компьютер
```dm
/obj/item/modular_computer/tablet/ui_state(mob/user)
	return GLOB.portable_device_state
```

## Игровые сценарии

### Сценарий 1: Медик с рацией
```dm
// Медик лежит на полу, но может использовать рацию для вызова помощи
/mob/living/carbon/human/medical_doctor
	// ... код медика ...

// Рация работает в лежачем положении
/obj/item/radio/ui_state(mob/user)
	return GLOB.portable_device_state
```

### Сценарий 2: Инженер с PDA
```dm
// Инженер лежит после взрыва, но может использовать PDA
/mob/living/carbon/human/engineer
	// ... код инженера ...

// PDA работает в лежачем положении
/obj/item/pda/ui_state(mob/user)
	return GLOB.portable_device_state
```

### Сценарий 3: Ученый с планшетом
```dm
// Ученый лежит, но может использовать планшет для исследований
/mob/living/carbon/human/scientist
	// ... код ученого ...

// Планшет работает в лежачем положении
/obj/item/tablet/ui_state(mob/user)
	return GLOB.portable_device_state
```

## Миграция существующего кода

### Было (inventory_state):
```dm
/obj/item/radio/ui_state(mob/user)
	return GLOB.inventory_state
```

### Стало (portable_device_state):
```dm
/obj/item/radio/ui_state(mob/user)
	return GLOB.portable_device_state
```

## Тестовые примеры

### Тест 1: Сознательный лежащий пользователь
```dm
/mob/living/carbon/human/test_user
	stat = CONSCIOUS
	lying = TRUE

/obj/item/radio/test_radio
	// Рация в инвентаре пользователя

// Результат: UI_INTERACTIVE
```

### Тест 2: Без сознания пользователь
```dm
/mob/living/carbon/human/test_user
	stat = UNCONSCIOUS
	lying = TRUE

/obj/item/radio/test_radio
	// Рация в инвентаре пользователя

// Результат: UI_CLOSE
```

### Тест 3: Пользователь без предмета
```dm
/mob/living/carbon/human/test_user
	stat = CONSCIOUS
	lying = TRUE

// Рация НЕ в инвентаре пользователя

// Результат: UI_CLOSE
```

## Специальные случаи

### Случай 1: Предмет в руке
```dm
/mob/living/carbon/human/user
	// Рация в правой руке
	r_hand = /obj/item/radio

// Результат: UI_INTERACTIVE (предмет в инвентаре)
```

### Случай 2: Предмет в кармане
```dm
/mob/living/carbon/human/user
	// Рация в кармане
	// ... код кармана ...

// Результат: UI_INTERACTIVE (предмет в инвентаре)
```

### Случай 3: Предмет в слоте
```dm
/mob/living/carbon/human/user
	// Рация в слоте пояса
	belt = /obj/item/radio

// Результат: UI_INTERACTIVE (предмет в инвентаре)
```

## Отладочные примеры

### Отладка состояния UI:
```dm
/mob/proc/debug_ui_state(obj/item/device)
	var/datum/ui_state/state = device.ui_state(src)
	var/result = state.can_use_topic(device, src)
	
	to_chat(src, "=== UI State Debug ===")
	to_chat(src, "Device: [device]")
	to_chat(src, "State: [state]")
	to_chat(src, "Result: [result]")
	to_chat(src, "User stat: [stat]")
	to_chat(src, "User lying: [lying]")
	to_chat(src, "Device in user: [device in src]")
	to_chat(src, "==================")
```

### Использование отладки:
```dm
// В игре:
/debug_ui_state /obj/item/radio

// Вывод:
// === UI State Debug ===
// Device: /obj/item/radio
// State: /datum/ui_state/portable_device_state
// Result: UI_INTERACTIVE
// User stat: 0 (CONSCIOUS)
// User lying: 1 (TRUE)
// Device in user: 1 (TRUE)
// ==================
```

## Дополнительные устройства

### Умные очки:
```dm
/obj/item/clothing/glasses/smart/ui_state(mob/user)
	return GLOB.portable_device_state
```

### Портативный терминал:
```dm
/obj/item/portable_terminal/ui_state(mob/user)
	return GLOB.portable_device_state
```

### Голографический проектор:
```dm
/obj/item/holographic_projector/ui_state(mob/user)
	return GLOB.portable_device_state
```

## Игровые механики

### Механика 1: Лежачий медик
```dm
// Медик может использовать рацию лежа для вызова помощи
/mob/living/carbon/human/medical_doctor/proc/call_for_help()
	if(stat != CONSCIOUS)
		return
	// Рация работает в лежачем положении
	var/obj/item/radio/radio = get_radio()
	if(radio)
		radio.ui_interact(src)
```

### Механика 2: Раненый инженер
```dm
// Инженер может использовать PDA лежа для вызова ремонта
/mob/living/carbon/human/engineer/proc/request_repair()
	if(stat != CONSCIOUS)
		return
	// PDA работает в лежачем положении
	var/obj/item/pda/pda = get_pda()
	if(pda)
		pda.ui_interact(src)
```

### Механика 3: Ученый с планшетом
```dm
// Ученый может использовать планшет лежа для исследований
/mob/living/carbon/human/scientist/proc/continue_research()
	if(stat != CONSCIOUS)
		return
	// Планшет работает в лежачем положении
	var/obj/item/tablet/tablet = get_tablet()
	if(tablet)
		tablet.ui_interact(src)
```


---

**Совет**: Используйте эти примеры как основу для ваших собственных реализаций!
