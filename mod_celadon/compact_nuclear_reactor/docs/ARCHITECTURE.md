# Архитектура Компактного Термогель Реактора

**Техническая документация для разработчиков**

## 🏗️ Общая архитектура

### Основные компоненты
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Реактор       │    │   Внутренний    │    │   Внешний       │
│   (Ядро)        │◄──►│   Охладитель    │    │   Охладитель    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   NET_GEL       │    │   Модули        │    │   Окружающая    │
│   Сеть          │    │   (2x3)         │    │   Среда         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Поток данных
1. **Реактор** генерирует тепло и энергию
2. **Термогель** переносит тепло через NET_GEL
3. **Охладители** рассеивают тепло в окружающую среду
4. **Модули** модифицируют параметры системы

## 🔧 Технические детали

### Система состояний
```dm
// Состояния реактора
#define REAC_OFF        0  // Выключен
#define REAC_STARTING   1  // Запуск
#define REAC_RUNNING    2  // Работает
#define REAC_SCRAM      3  // Аварийная остановка
#define REAC_MELTDOWN   4  // Расплавление
```

### Физические формулы
```dm
// Генерация энергии
Q_gen = throttle * base_power * power_modifiers

// Генерация тепла
Q_heat = Q_gen * heat_factor * heat_modifiers

// Передача тепла
Q_transfer = (core_T - gel_T) * transfer_coefficient

// Конвекционное охлаждение
Q_conv = (gel_T - env_T) * conv_area * conv_coefficient

// Радиационное охлаждение
Q_rad = (gel_T^4 - env_T^4) * rad_area * rad_coefficient
```

### Сеть NET_GEL
```dm
// Базовый порт геля
/datum/gel_port
    var/net_type = NET_GEL
    var/connected = FALSE
    var/datum/gel_network_node/network

// Узел сети геля
/datum/gel_network_node
    var/list/ports = list()
    var/current_flow = 0
    var/flow_capacity = 1000
    var/temperature = 300
```

## 📁 Структура файлов

### Основные файлы
- `code/cnr_defs.dm` - Константы и определения
- `code/cnr_math.dm` - Физические формулы
- `code/cnr_reactor.dm` - Основной реактор
- `code/cnr_modules.dm` - Система модулей

### Системы охлаждения
- `code/cnr_cooler_internal.dm` - Внутренний охладитель
- `code/cnr_cooler_external.dm` - Внешний охладитель

### Сеть геля
- `gel_net/cnr_pipe_h.dm` - Горизонтальные трубы
- `gel_net/cnr_pipe_v.dm` - Вертикальные трубы
- `gel_net/cnr_pump.dm` - Насосы
- `gel_net/cnr_gel_cell.dm` - Ячейки геля

### Интерфейс
- `tgui/cnr_reactor.tsx` - TGUI интерфейс
- `config/cnr.json` - Конфигурация

## 🔄 Цикл обработки

### Основной цикл (каждые 2 секунды)
```dm
/obj/machinery/cnr_reactor/process()
    1. Проверка состояния
    2. Расчет физики реактора
    3. Применение охлаждения
    4. Обновление температур
    5. Проверка безопасности
    6. Излучение радиации
    7. Логирование данных
    8. Передача энергии в сеть
    9. Обновление внешнего вида
```

### Обработка охлаждения
```dm
apply_cooling()
    1. Получение мощности внутреннего охладителя
    2. Обработка внешних охладителей
    3. Применение модификаторов модулей
    4. Обновление температуры геля
```

## 🛡️ Системы безопасности

### Автоматический SCRAM
```dm
check_safety_conditions()
    if(core_T > max_temp * 0.9)  // 90% от максимума
        trigger_warning()
    if(core_T > max_temp)        // 100% от максимума
        trigger_scram()
    if(core_T > max_temp * 1.2)  // 120% от максимума
        trigger_degradation()
    if(core_T > max_temp * 1.4)  // 140% от максимума
        trigger_tile_heat()
    if(core_T > max_temp * 1.6)  // 160% от максимума
        trigger_explosion()
```

### Проверка целостности сети
```dm
validate_gel_network()
    1. Графовый обход всех портов
    2. Проверка минимального объема геля
    3. Проверка температуры геля
    4. Обнаружение утечек
    5. Проверка подключений к чужим сетям
```

## 🎛️ Система модулей

### Базовый датум модуля
```dm
/datum/cnr_module
    var/name = "Base Module"
    var/desc = "Base module description"
    var/module_type = MODULE_BASE
    var/icon_state = "module_base"
    
    proc/apply_effects(list/modifiers)
    proc/on_install(obj/machinery/cnr_reactor/reactor)
    proc/on_remove(obj/machinery/cnr_reactor/reactor)
```

### Применение эффектов
```dm
apply_module_effects()
    1. Сбор всех установленных модулей
    2. Применение эффектов слева направо
    3. Обновление модификаторов реактора
    4. Пересчет физических параметров
```

## 🔌 Интеграция с SS13

### Сеть питания
```dm
transfer_power_to_network()
    if(power_output > 0)
        var/obj/machinery/power/terminal/terminal = locate() in get_turf(src)
        if(terminal && terminal.powernet)
            terminal.powernet.load += power_output
```

### Обработка
```dm
// Интеграция с SSmachines
SSmachines.processing += src

// Обработка каждые 2 секунды
process_tick++
if(process_tick % 2 == 0)
    process_reactor_physics()
```

### TGUI интеграция
```dm
// Отправка данных в TGUI
ui_data()
    return list(
        "state" = state,
        "power_output" = power_output,
        "core_temperature" = core_T,
        "gel_temperature" = gel_T,
        "throttle" = throttle,
        "modules" = get_module_data()
    )
```

## 🔧 Конфигурация

### Внешний JSON файл
```json
{
  "reactor": {
    "base_power": 500,
    "max_temperature": 1200,
    "startup_time": 30
  },
  "modules": {
    "cooling": {
      "coolant_booster": {
        "flow_bonus": 0.2,
        "viscosity_reduction": 0.1
      }
    }
  }
}
```

### Загрузка конфигурации
```dm
load_configuration()
    var/config_file = file("config/cnr.json")
    var/config_data = json_decode(config_file)
    apply_configuration(config_data)
```

## 🐛 Отладка

### Логирование
```dm
log_process_data()
    var/log_entry = list(
        "timestamp" = world.time,
        "state" = state,
        "power" = power_output,
        "core_temp" = core_T,
        "gel_temp" = gel_T
    )
    process_log += log_entry
    if(process_log.len > max_log_entries)
        process_log.Cut(1, 2)
```

### Проверка состояния
```dm
debug_info()
    return list(
        "state" = state,
        "power_output" = power_output,
        "core_temperature" = core_T,
        "gel_temperature" = gel_T,
        "throttle" = throttle,
        "modules_installed" = get_installed_modules(),
        "coolers_connected" = get_connected_coolers()
    )
```

## 📈 Производительность

### Оптимизации
- Обработка каждые 2 секунды вместо каждого тика
- Кэширование расчетов физики
- Ленивая загрузка конфигурации
- Ограниченное логирование

### Мониторинг
- Отслеживание использования CPU
- Мониторинг памяти
- Проверка утечек в сети
- Анализ производительности модулей

---

**Версия документации**: 0.2.0  
**Последнее обновление**: 2024-01-XX  
**Статус**: Актуально
