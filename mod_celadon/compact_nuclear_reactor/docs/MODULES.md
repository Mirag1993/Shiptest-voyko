# Система модулей Компактного Термогель Реактора

**Подробное руководство по модулям и их эффектам**

## 🎛️ Обзор системы модулей

### Структура слотов
```
┌─────────────────────────────────────────┐
│  Слоты модулей (2x3 сетка)              │
├─────────────────┬───────────────────────┤
│   Охлаждение    │     Мощность          │
│   (Левый ряд)   │   (Правый ряд)        │
├─────────────────┼───────────────────────┤
│ [1] [2] [3]     │ [1] [2] [3]           │
│                 │                       │
└─────────────────┴───────────────────────┘
```

### Порядок применения эффектов
- **Слева направо** в каждом ряду
- **Охлаждение** применяется первым
- **Мощность** применяется вторым
- Комбинированные эффекты накапливаются

## ❄️ Модули охлаждения

### 1. Усилитель охлаждающей жидкости (Coolant Booster)
```
Слот: Охлаждение [1]
Иконка: module_coolant_booster
```

**Эффекты:**
- `flow_bonus`: +20% к потоку геля
- `viscosity_reduction`: -10% чувствительность к вязкости
- `cooling_efficiency`: +15% эффективность охлаждения

**Применение:**
```dm
/datum/cnr_module/cooling/coolant_booster/apply_effects(list/modifiers)
    modifiers["flow_multiplier"] += 0.2
    modifiers["viscosity_sensitivity"] -= 0.1
    modifiers["cooling_efficiency"] += 0.15
    return modifiers
```

**Описание:** Увеличивает циркуляцию термогеля и снижает его чувствительность к изменениям температуры.

### 2. Ребристые пластины (Finned Plates)
```
Слот: Охлаждение [2]
Иконка: module_finned_plates
```

**Эффекты:**
- `convection_area`: +25% площадь конвекции
- `heat_transfer`: +20% теплопередача
- `radiative_cooling`: +10% радиационное охлаждение

**Применение:**
```dm
/datum/cnr_module/cooling/finned_plates/apply_effects(list/modifiers)
    modifiers["convection_area"] += 0.25
    modifiers["heat_transfer_coefficient"] += 0.2
    modifiers["radiation_coefficient"] += 0.1
    return modifiers
```

**Описание:** Увеличивает площадь теплообмена и улучшает эффективность охлаждения.

### 3. Криогенное ядро (Cryogenic Core)
```
Слот: Охлаждение [3]
Иконка: module_cryogenic_core
```

**Эффекты:**
- `cryogenic_cooling`: +40% криогенное охлаждение
- `temperature_threshold`: +100K к порогу температуры
- `emergency_cooling`: +50% аварийное охлаждение

**Применение:**
```dm
/datum/cnr_module/cooling/cryogenic_core/apply_effects(list/modifiers)
    modifiers["cryogenic_multiplier"] += 0.4
    modifiers["max_temperature"] += 100
    modifiers["emergency_cooling"] += 0.5
    return modifiers
```

**Описание:** Обеспечивает мощное криогенное охлаждение для экстремальных нагрузок.

## ⚡ Модули мощности

### 1. Усилитель мощности (Power Amplifier)
```
Слот: Мощность [1]
Иконка: module_power_amplifier
```

**Эффекты:**
- `power_multiplier`: +25% выходная мощность
- `heat_generation`: +20% генерация тепла
- `efficiency`: +10% общая эффективность

**Применение:**
```dm
/datum/cnr_module/power/power_amplifier/apply_effects(list/modifiers)
    modifiers["power_multiplier"] += 0.25
    modifiers["heat_multiplier"] += 0.2
    modifiers["efficiency"] += 0.1
    return modifiers
```

**Описание:** Значительно увеличивает выходную мощность реактора.

### 2. Стабилизирующая облицовка (Stability Liner)
```
Слот: Мощность [2]
Иконка: module_stability_liner
```

**Эффекты:**
- `stability_bonus`: +15% стабильность реакции
- `temperature_threshold`: +150K к порогу температуры
- `degradation_resistance`: +20% сопротивление деградации

**Применение:**
```dm
/datum/cnr_module/power/stability_liner/apply_effects(list/modifiers)
    modifiers["stability"] += 0.15
    modifiers["max_temperature"] += 150
    modifiers["degradation_resistance"] += 0.2
    return modifiers
```

**Описание:** Стабилизирует ядерную реакцию и повышает температурные лимиты.

### 3. Радиационный экран (Radiation Baffle)
```
Слот: Мощность [3]
Иконка: module_radiation_baffle
```

**Эффекты:**
- `radiation_reduction`: -30% излучение радиации
- `safety_margin`: +25% запас безопасности
- `containment_bonus`: +20% удержание радиации

**Применение:**
```dm
/datum/cnr_module/power/radiation_baffle/apply_effects(list/modifiers)
    modifiers["radiation_multiplier"] -= 0.3
    modifiers["safety_margin"] += 0.25
    modifiers["containment_efficiency"] += 0.2
    return modifiers
```

**Описание:** Снижает радиационное излучение и улучшает безопасность.

## 🔧 Техническая реализация

### Базовый датум модуля
```dm
/datum/cnr_module
    var/name = "Base Module"
    var/desc = "Base module description"
    var/module_type = MODULE_BASE
    var/icon_state = "module_base"
    var/active = TRUE
    
    // Основные процедуры
    proc/apply_effects(list/modifiers)
    proc/on_install(obj/machinery/cnr_reactor/reactor)
    proc/on_remove(obj/machinery/cnr_reactor/reactor)
    proc/get_description()
```

### Типы модулей
```dm
#define MODULE_BASE     0
#define MODULE_COOLING  1
#define MODULE_POWER    2
```

### Система модификаторов
```dm
// Структура модификаторов
var/list/modifiers = list(
    // Охлаждение
    "flow_multiplier" = 1.0,
    "viscosity_sensitivity" = 1.0,
    "cooling_efficiency" = 1.0,
    "convection_area" = 1.0,
    "heat_transfer_coefficient" = 1.0,
    "radiation_coefficient" = 1.0,
    
    // Мощность
    "power_multiplier" = 1.0,
    "heat_multiplier" = 1.0,
    "efficiency" = 1.0,
    "stability" = 1.0,
    "max_temperature" = 0,
    "degradation_resistance" = 1.0,
    
    // Безопасность
    "radiation_multiplier" = 1.0,
    "safety_margin" = 1.0,
    "containment_efficiency" = 1.0
)
```

## 🎮 Игровые механики

### Установка модулей
1. **Подготовка**: Убедитесь, что реактор выключен
2. **Выбор слота**: Выберите подходящий слот (охлаждение/мощность)
3. **Установка**: Используйте модуль на реакторе
4. **Проверка**: Убедитесь в правильной установке

### Удаление модулей
1. **Безопасность**: Выключите реактор
2. **Извлечение**: Используйте отвертку на слоте модуля
3. **Проверка**: Убедитесь в отсутствии повреждений

### Комбинирование эффектов
```dm
// Пример комбинации модулей
// Охлаждение: [Усилитель] [Ребристые] [Криогенное]
// Мощность: [Усилитель] [Стабилизация] [Экран]

// Итоговые эффекты:
// - Поток: +20% (только от усилителя)
// - Конвекция: +25% (от ребристых пластин)
// - Криогенное: +40% (от криогенного ядра)
// - Мощность: +25% (от усилителя мощности)
// - Стабильность: +15% (от стабилизации)
// - Радиация: -30% (от экрана)
```

## 📊 Баланс и ограничения

### Ограничения мощности
- **Максимум модулей**: 6 (3 охлаждения + 3 мощности)
- **Комбинированные эффекты**: Могут превышать 100%
- **Температурные лимиты**: Жесткие ограничения безопасности

### Рекомендуемые конфигурации

#### Безопасная работа
```
Охлаждение: [Усилитель] [Ребристые] [Пусто]
Мощность: [Пусто] [Стабилизация] [Экран]
```
- Фокус на безопасности и стабильности
- Умеренная мощность (300-400 кВт)

#### Высокая производительность
```
Охлаждение: [Усилитель] [Ребристые] [Криогенное]
Мощность: [Усилитель] [Стабилизация] [Экран]
```
- Максимальная мощность (600-800 кВт)
- Требует внимательного мониторинга

#### Экстремальная нагрузка
```
Охлаждение: [Усилитель] [Ребристые] [Криогенное]
Мощность: [Усилитель] [Усилитель] [Усилитель]
```
- Пиковая мощность (800-900 кВт)
- Очень опасная конфигурация

## 🔍 Отладка модулей

### Проверка состояния
```dm
/proc/debug_modules()
    var/list/module_info = list()
    for(var/i = 1 to 3)
        if(slots_cooling[i])
            module_info += "Cooling [i]: [slots_cooling[i].name]"
        if(slots_power[i])
            module_info += "Power [i]: [slots_power[i].name]"
    return module_info
```

### Проверка эффектов
```dm
/proc/get_active_modifiers()
    var/list/modifiers = get_base_modifiers()
    
    // Применение модулей охлаждения
    for(var/datum/cnr_module/cooling/module in slots_cooling)
        if(module && module.active)
            modifiers = module.apply_effects(modifiers)
    
    // Применение модулей мощности
    for(var/datum/cnr_module/power/module in slots_power)
        if(module && module.active)
            modifiers = module.apply_effects(modifiers)
    
    return modifiers
```

## 🚀 Расширение системы

### Создание нового модуля
```dm
/datum/cnr_module/cooling/custom_cooler
    name = "Custom Cooler"
    desc = "A custom cooling module"
    module_type = MODULE_COOLING
    icon_state = "module_custom"
    
    apply_effects(list/modifiers)
        modifiers["custom_effect"] += 0.5
        return modifiers
```

### Добавление новых эффектов
1. Добавить в базовые модификаторы
2. Обновить процедуры применения
3. Добавить в TGUI интерфейс
4. Обновить документацию

---

**Версия документации**: 0.2.0  
**Последнее обновление**: 2024-01-XX  
**Статус**: Актуально
