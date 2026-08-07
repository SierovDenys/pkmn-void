# .development

Рабочие материалы разработки. В игру ничего отсюда не попадает — Essentials читает
только `Plugins/`, `Graphics/`, `Audio/`, `Data/`, `PBS/`.

```
.development/
├── design/      замысел игры
├── notes/       заметки: плагины, источники тайлов, повадки движка
├── tools/       Ruby-скрипты для работы с .rxdata
│   └── data/    автогенерируемые данные (руками не править)
└── snippets/    куски кода на будущее, сейчас не подключены
```

| Куда | Что там |
|---|---|
| [design/idea.md](design/idea.md) | Game design document (EN) |
| [design/idea (ru).md](design/idea%20(ru).md) | он же на русском |
| [design/quests.md](design/quests.md) | **бэклог сайдквестов** — шаблон, правила проверки, сырые идеи |
| [notes/plugins.md](notes/plugins.md) | список установленных плагинов + ссылки, и что ещё присмотрено |
| [notes/tilesets-sources.md](notes/tilesets-sources.md) | откуда взяты тайлсеты, кредиты авторов |
| [notes/engine-notes.md](notes/engine-notes.md) | **грабли движка** — автотайлы, terrain tags, кэш плагинов |
| [tools/README.md](tools/README.md) | описание инструментов и как ими пользоваться |
| [snippets/](snippets/) | заготовки плагинов, которые пока не нужны |

## Требования

Скрипты в `tools/` требуют системный Ruby (стоит `C:\Ruby40-x64`). На игру он не влияет —
она использует свой встроенный `x64-msvcrt-ruby310.dll`.

```bash
ruby -v    # ruby 4.0.6
```

Формат `Marshal` в обеих версиях — `4.8`, так что файлы полностью совместимы.
