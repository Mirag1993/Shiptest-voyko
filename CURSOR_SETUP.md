# Настройка Cursor для SS13/BYOND Development

## Обзор

Это руководство поможет настроить Cursor для эффективной разработки на SS13/BYOND проектах. Мы подключим все необходимые источники знаний и настроим правила для качественной работы с кодом.

## Шаг 1: Подключение источников знаний

### 1.1 Репозитории (Indexed Sources)

В Cursor перейдите в Settings → Sources и добавьте следующие репозитории:

#### Обязательные репозитории:
- **/tg/station**: `https://github.com/tgstation/tgstation`
  - Приоритет: CRITICAL
  - Описание: Базовый форк для понимания архитектуры
- **TGUI**: `https://github.com/tgstation/tgstation/tree/master/tgui`
  - Приоритет: CRITICAL
  - Описание: UI фреймворк для SS13

#### Дополнительные репозитории:
- **SpacemanDMM**: `https://github.com/SpaceManiac/SpacemanDMM`
  - Приоритет: HIGH
  - Описание: Инструменты для статического анализа
- **StrongDMM**: `https://github.com/SpaiR/StrongDMM`
  - Приоритет: MEDIUM
  - Описание: Редактор карт

### 1.2 Документация (Docs)

Добавьте следующие документы в раздел Docs:

#### BYOND/DM документация:
- **BYOND Dream Maker Language Reference**: `https://www.byond.com/docs/ref/`
- **BYOND Reference/Guide**: `https://www.byond.com/docs/guide/`
- **BYOND 515/516 Release Notes**: `https://www.byond.com/forum/post/2871235`

#### /tg/station документация:
- **CONTRIBUTING**: `https://github.com/tgstation/tgstation/blob/master/.github/CONTRIBUTING.md`
- **Mapping Guide**: `https://github.com/tgstation/tgstation/blob/master/docs/Mapping.md`
- **TGUI Documentation**: `https://github.com/tgstation/tgstation/blob/master/tgui/README.md`
- **Component Reference**: `https://github.com/tgstation/tgstation/blob/master/tgui/docs/component-reference.md`

### 1.3 Локальные файлы

Добавьте локальные файлы проекта как источники:
- `./README.md`
- `./docs/installation.md`
- `./tgui/README.md`
- `./SpacemanDMM.toml`
- `./.editorconfig`

## Шаг 2: Настройка правил проекта

### 2.1 Файл .cursorrules

Файл `.cursorrules` уже создан в корне проекта. Он содержит:
- Правила для DM (BYOND) разработки
- Правила для TGUI разработки
- Стандарты кодирования
- Рекомендации по производительности
- Правила безопасности

### 2.2 Файл .cursorsources

Файл `.cursorsources` содержит полный список источников знаний с приоритетами и описаниями.

## Шаг 3: Настройка расширений

### 3.1 Рекомендуемые расширения для Cursor:

#### Для DM (BYOND):
- **Dream Maker Language Support** (если доступно)
- **SpacemanDMM Integration**
- **BYOND Syntax Highlighting**

#### Для TGUI (TypeScript/React):
- **TypeScript and JavaScript Language Features**
- **ES7+ React/Redux/React-Native snippets**
- **Prettier - Code formatter**
- **ESLint**

#### Общие:
- **GitLens**
- **Git History**
- **Path Intellisense**
- **Auto Rename Tag**

## Шаг 4: Настройка рабочего окружения

### 4.1 Конфигурация проекта

Убедитесь, что в проекте есть следующие файлы:
- `.editorconfig` - настройки редактора
- `SpacemanDMM.toml` - конфигурация линтера
- `.gitignore` - исключения для Git
- `package.json` (в папке tgui) - зависимости TGUI

### 4.2 Настройка путей

В Cursor настройте следующие пути:
- **BYOND**: Путь к установленному BYOND
- **SpacemanDMM**: Путь к SpacemanDMM (если установлен)
- **StrongDMM**: Путь к StrongDMM (если установлен)

## Шаг 5: Проверка настройки

### 5.1 Тестовая проверка

1. Откройте любой `.dm` файл в проекте
2. Проверьте подсветку синтаксиса
3. Попробуйте автодополнение
4. Проверьте работу с TGUI файлами

### 5.2 Проверка источников знаний

В Cursor попробуйте задать вопросы:
- "Как использовать Initialize() в DM?"
- "Как создать TGUI компонент?"
- "Какие паттерны используются в /tg/station?"

## Шаг 6: Дополнительные настройки

### 6.1 Настройка терминала

Настройте терминал для работы с проектом:
```bash
# Компиляция проекта
bin/build.cmd

# Запуск TGUI dev сервера
bin/tgui-dev.cmd

# Запуск линтера
bin/lint.cmd
```

### 6.2 Настройка отладки

Создайте конфигурацию для отладки в `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch BYOND",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/bin/server.cmd"
    }
  ]
}
```

## Шаг 7: Рекомендации по использованию

### 7.1 Работа с кодом

1. **Всегда следуйте стилю проекта** - используйте `.cursorrules`
2. **Спрашивайте Cursor о паттернах** - используйте подключенные источники
3. **Проверяйте код линтером** - используйте SpacemanDMM
4. **Тестируйте изменения** - запускайте проект локально

### 7.2 Работа с картами

1. **Используйте mapmerge2** перед коммитом
2. **Следуйте правилам маппинга** из документации
3. **Проверяйте карты в StrongDMM**

### 7.3 Работа с TGUI

1. **Следуйте архитектуре TGUI** - используйте act() и сигналы
2. **Используйте TypeScript** для типизации
3. **Следуйте стилю компонентов** из документации

## Шаг 8: Решение проблем

### 8.1 Частые проблемы

#### Cursor не распознает DM синтаксис:
- Убедитесь, что установлены правильные расширения
- Проверьте настройки файловых ассоциаций

#### Источники знаний не работают:
- Проверьте правильность URL в `.cursorsources`
- Убедитесь, что источники проиндексированы

#### TGUI не компилируется:
- Проверьте Node.js и Yarn версии
- Запустите `yarn install` в папке tgui

### 8.2 Получение помощи

- **Discord**: https://discord.gg/rxsggTJzY3
- **GitHub Issues**: Создайте issue в репозитории
- **BYOND Forums**: https://www.byond.com/forum/

## Заключение

После выполнения всех шагов Cursor будет настроен для эффективной разработки SS13/BYOND проектов. Система будет:

- Понимать DM синтаксис и паттерны
- Предлагать правильные решения для TGUI
- Следовать стандартам проекта
- Использовать актуальную документацию
- Помогать с отладкой и тестированием

Регулярно обновляйте источники знаний и следите за изменениями в документации проекта.
