# Быстрая настройка Cursor для SS13/BYOND

## 🚀 Быстрый старт (5 минут)

### 1. Подключите источники в Cursor

**Репозитории (Settings → Sources → Add Repository):**
```
https://github.com/tgstation/tgstation (CRITICAL)
https://github.com/SpaceManiac/SpacemanDMM (HIGH)
```

**Документация (Settings → Sources → Add Doc):**
```
https://www.byond.com/docs/ref/ (BYOND Reference)
https://github.com/tgstation/tgstation/blob/master/.github/CONTRIBUTING.md (Coding Standards)
https://github.com/tgstation/tgstation/blob/master/tgui/README.md (TGUI Guide)
```

### 2. Проверьте настройку

Откройте любой `.dm` файл и спросите Cursor:
> "Как использовать Initialize() в этом проекте?"

## 📋 Что получите

✅ **DM (BYOND) поддержка**
- Синтаксис и автодополнение
- Паттерны Initialize/Destroy
- Component/Element системы
- GC и сигналы

✅ **TGUI поддержка**
- TypeScript/React синтаксис
- act() и useBackend()
- Компоненты и стили
- Hot reload

✅ **Качество кода**
- SpacemanDMM линтинг
- Стандарты /tg/station
- mapmerge2 для карт
- Unit тесты

✅ **Документация**
- BYOND Reference
- /tg/station docs
- TGUI guides
- Локальные файлы проекта

## 🔧 Дополнительно (опционально)

### Установите расширения:
- TypeScript and JavaScript Language Features
- GitLens
- Prettier - Code formatter
- ESLint

### Настройте терминал:
```bash
# Компиляция
bin/build.cmd

# TGUI dev сервер
bin/tgui-dev.cmd
```

## 🎯 Готово!

Теперь Cursor понимает:
- DM синтаксис и паттерны
- TGUI архитектуру
- Стандарты проекта
- Документацию BYOND

**Следующий шаг**: Изучите `CURSOR_SETUP.md` для детальной настройки.
