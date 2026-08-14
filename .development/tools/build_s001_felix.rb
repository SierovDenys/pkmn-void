# ==============================================================================
# S-001 "Meeting Felix" — builds the scene in Town 1 (Map007).
#
#   ruby .development/tools/build_s001_felix.rb
#
# ВАЖНО: RMXP должен быть закрыт (см. .development/notes/engine-notes.md).
#
# Текст сцены пишется здесь, а не в RMXP: скрипт пересобирает событие целиком,
# так что правка реплики — это правка строки ниже и повторный запуск.
# Язык базового текста — английский (RMXP не юникодный). Русский/украинский
# подключаются позже через Debug menu -> Extract text for translation.
#
# Что создаёт:
#   event 1  S001_Felix      (44,54) — у стойки кафе; 3 страницы: покой / сцена / пусто
#   event 2  S001_Trigger_A  (41,54) \
#   event 3  S001_Trigger_B  (41,55)  > невидимые датчики, Player Touch
#   event 4  S001_Trigger_C  (41,56) /
#
#   switch 59  S001: Felix scene start
#   switch 60  S001: Felix scene done
#   var     2  S001: how the player introduced themselves (1 = trainer, 2 = passing through)
# ==============================================================================

require_relative "rgss_stubs"

MAP_FILE   = "Data/Map007.rxdata"
SW_START   = 59
SW_DONE    = 60
VAR_INTRO  = 2

map = load_rxdata(MAP_FILE)

# ------------------------------------------------------------------------------
# Конструкторы объектов RPG::*. Классы уже определены загрузкой карты.
# ------------------------------------------------------------------------------
def cmd(code, params = [], indent = 0)
  c = RPG::EventCommand.new
  c.instance_variable_set(:@code, code)
  c.instance_variable_set(:@indent, indent)
  c.instance_variable_set(:@parameters, params)
  c
end

# Show Text. Строки склеиваются движком через пробел (command_101 -> 401),
# так что перенос здесь — только для читаемости в редакторе.
def text(lines, indent = 0)
  lines = [lines] if lines.is_a?(String)
  [cmd(101, [lines[0]], indent)] +
    lines[1..].map { |l| cmd(401, [l], indent) }
end

def mv(code, params = [])
  c = RPG::MoveCommand.new
  c.instance_variable_set(:@code, code)
  c.instance_variable_set(:@parameters, params)
  c
end

def route(cmds, repeat: false, skippable: true)
  r = RPG::MoveRoute.new
  r.instance_variable_set(:@repeat, repeat)
  r.instance_variable_set(:@skippable, skippable)
  r.instance_variable_set(:@list, cmds + [mv(0)])
  r
end

def condition(switch1: nil, switch2: nil, variable: nil, var_value: 0, self_switch: nil)
  c = RPG::Event::Page::Condition.new
  c.instance_variable_set(:@switch1_valid,     !switch1.nil?)
  c.instance_variable_set(:@switch1_id,        switch1 || 1)
  c.instance_variable_set(:@switch2_valid,     !switch2.nil?)
  c.instance_variable_set(:@switch2_id,        switch2 || 1)
  c.instance_variable_set(:@variable_valid,    !variable.nil?)
  c.instance_variable_set(:@variable_id,       variable || 1)
  c.instance_variable_set(:@variable_value,    var_value)
  c.instance_variable_set(:@self_switch_valid, !self_switch.nil?)
  c.instance_variable_set(:@self_switch_ch,    self_switch || "A")
  c
end

def graphic(name: "", direction: 2, pattern: 0)
  g = RPG::Event::Page::Graphic.new
  g.instance_variable_set(:@tile_id,        0)
  g.instance_variable_set(:@character_name, name)
  g.instance_variable_set(:@character_hue,  0)
  g.instance_variable_set(:@direction,      direction)
  g.instance_variable_set(:@pattern,        pattern)
  g.instance_variable_set(:@opacity,        255)
  g.instance_variable_set(:@blend_type,     0)
  g
end

def page(list:, cond: condition, gfx: graphic, trigger: 0,
         speed: 4, freq: 3, walk_anime: true, step_anime: false,
         direction_fix: false, through: false, always_on_top: false)
  p = RPG::Event::Page.new
  p.instance_variable_set(:@condition,       cond)
  p.instance_variable_set(:@graphic,         gfx)
  p.instance_variable_set(:@move_type,       0)
  p.instance_variable_set(:@move_speed,      speed)
  p.instance_variable_set(:@move_frequency,  freq)
  p.instance_variable_set(:@move_route,      route([], repeat: true, skippable: false))
  p.instance_variable_set(:@walk_anime,      walk_anime)
  p.instance_variable_set(:@step_anime,      step_anime)
  p.instance_variable_set(:@direction_fix,   direction_fix)
  p.instance_variable_set(:@through,         through)
  p.instance_variable_set(:@always_on_top,   always_on_top)
  p.instance_variable_set(:@trigger,         trigger)
  p.instance_variable_set(:@list,            list + [cmd(0)])
  p
end

def event(id:, name:, x:, y:, pages:)
  e = RPG::Event.new
  e.instance_variable_set(:@id,    id)
  e.instance_variable_set(:@name,  name)
  e.instance_variable_set(:@x,     x)
  e.instance_variable_set(:@y,     y)
  e.instance_variable_set(:@pages, pages)
  e
end

BLANK_PAGE_LIST = [].freeze

# ------------------------------------------------------------------------------
# Сцена (страница 2 Феликса, Autorun)
#
# Феликс стоит у стойки кафе на (44,54) лицом вверх — пьёт кофе. Замечает игрока,
# окликает, спускается на тропу и идёт влево ему навстречу.
# ------------------------------------------------------------------------------
scene = []

# --- оклик от стойки ---------------------------------------------------------
scene << cmd(209, [0, route([mv(25)])])            # отрывается от кофе, смотрит на игрока
scene << cmd(106, [8])
scene += text("Hey! Hey, on the road!")

# --- спускается и подходит ---------------------------------------------------
scene << cmd(209, [0, route([mv(29, [4]), mv(1)] + Array.new(4) { mv(10) } + [mv(25)])])
scene << cmd(210)                                  # ждём завершения
scene << cmd(209, [-1, route([mv(18)])])           # игрок поворачивается вправо

# --- знакомство --------------------------------------------------------------
scene += text(["You're not from around here, are you?",
               "Don't bother denying it —",
               "the locals walk differently."])
scene += text(["They've been down this road a hundred",
               "times. They don't look around anymore.",
               "You do."])

scene += text(["So which is it? Are you a trainer,",
               "or just passing through?"])
scene << cmd(102, [["I'm a trainer.", "Just passing through."], 0])

scene << cmd(402, [0, "I'm a trainer."])
scene << cmd(122, [VAR_INTRO, VAR_INTRO, 0, 0, 1], 1)
scene += text(["Ha. Refreshing. Someone who just",
               "says what they are."], 1)

scene << cmd(402, [1, "Just passing through."])
scene << cmd(122, [VAR_INTRO, VAR_INTRO, 0, 0, 2], 1)
scene += text(["\"Just passing through.\" Sure.",
               "With a Poké Ball on your belt. Sure."], 1)

scene << cmd(404)

# --- бой ---------------------------------------------------------------------
scene += text(["Then let's find out. I've been here",
               "two hours, my coffee's gone cold,",
               "and there's nobody worth a match."])
scene += text("One battle. Quick.")

scene << cmd(355, ['setBattleRule("canLose")'])
scene << cmd(111, [12, 'TrainerBattle.start(:FELIX, "Felix")'])
scene += text(["Alright. Alright!",
               "Now we're talking."], 1)
scene << cmd(411)
scene += text(["Don't sulk. I battle everyone who",
               "comes down this road —",
               "I've just had more practice."], 1)
scene += text(["Hand them over.",
               "Let's patch them up."], 1)
scene << cmd(355, ["$player.heal_party"], 1)      # чтобы игрок не остался без покемонов
scene << cmd(412)

scene += text("Here. For your trouble.")
scene << cmd(355, ["pbReceiveItem(:POTION, 2)"])

# --- Лига --------------------------------------------------------------------
scene += text(["Listen, since you're here anyway.",
               "Get yourself registered with the League."])
scene += text(["The upside is simple: a badge is a pass.",
               "It gets you into restricted zones, and",
               "patrols stop asking questions."])
scene += text(["The downside is just as simple:",
               "you go on the register. Where you've been,",
               "who you fought, what you caught."])
scene += text(["Someone reads all of it.",
               "I'm registered. Some days I regret it."])

# --- крючок в основной сюжет -------------------------------------------------
scene += text("One more thing. Since you're a tourist.")
scene += text(["These past few weeks, Pokémon have been",
               "leaving the routes.",
               "Not migrating. Leaving."])
scene += text(["I figured I was imagining it.",
               "Then I counted. I wasn't."])
scene += text(["So if you see something you don't",
               "understand — don't go poking at it.",
               "Count it first."])

# --- уходит ------------------------------------------------------------------
scene += text(["Right. Coffee's done.",
               "See you around, tourist."])
scene << cmd(209, [0, route([mv(37), mv(29, [5])] + Array.new(10) { mv(3) })])
scene << cmd(210)

scene << cmd(121, [SW_START, SW_START, 1])         # старт OFF
scene << cmd(121, [SW_DONE,  SW_DONE,  0])         # пройдено ON

# ------------------------------------------------------------------------------
# Событие Феликса
# ------------------------------------------------------------------------------
felix_gfx = graphic(name: "[main].Felix", direction: 8)   # 8 = вверх, к стойке

felix = event(
  id: 1, name: "S001_Felix", x: 44, y: 54,
  pages: [
    # 1 — до сцены: стоит у кафе с кофе
    page(list: text(["Good day for it.", "Nice and quiet."]), gfx: felix_gfx, trigger: 0),
    # 2 — сцена
    page(list: scene, cond: condition(switch1: SW_START), gfx: felix_gfx, trigger: 3),
    # 3 — после: Феликса здесь больше нет
    page(list: BLANK_PAGE_LIST.dup, cond: condition(switch1: SW_DONE), trigger: 0)
  ]
)

# ------------------------------------------------------------------------------
# Датчики: три невидимых события поперёк тропы
# ------------------------------------------------------------------------------
def trigger_event(id, name, x, y)
  list = [
    cmd(111, [6, -1, 6]),                          # если игрок смотрит вправо
    cmd(121, [SW_START, SW_START, 0], 1),
    cmd(412)
  ]
  event(
    id: id, name: name, x: x, y: y,
    pages: [
      page(list: list, trigger: 1),                # Player Touch
      page(list: BLANK_PAGE_LIST.dup, cond: condition(switch1: SW_DONE), trigger: 0)
    ]
  )
end

map.events[1] = felix
map.events[2] = trigger_event(2, "S001_Trigger_A", 41, 54)
map.events[3] = trigger_event(3, "S001_Trigger_B", 41, 55)
map.events[4] = trigger_event(4, "S001_Trigger_C", 41, 56)

save_rxdata(MAP_FILE, map)

# ------------------------------------------------------------------------------
# Имена свитчей и переменных
# ------------------------------------------------------------------------------
sys = load_rxdata("Data/System.rxdata")
sys.switches[SW_START] = "S001: Felix scene start"
sys.switches[SW_DONE]  = "S001: Felix scene done"
sys.variables[1]         = "Battle outcome (engine, outcomeVar)"
sys.variables[VAR_INTRO] = "S001: how the player introduced themselves"
save_rxdata("Data/System.rxdata", sys)

puts "Done."
map.events.sort_by { |k, _| k }.each do |id, e|
  puts format("  event %d  %-16s (%03d,%03d)  pages: %d", id, e.name, e.x, e.y, e.pages.size)
end
