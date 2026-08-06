# ==============================================================================
# Проставляет terrain tag 10 (:TallGrass) тайлам, помеченным в RMXP тегом 7.
#
#   ruby .development/tools/apply_terrain_tags.rb
#
# ЗАЧЕМ ЭТО НУЖНО
#
# Редактор RMXP принимает Terrain Tag только 0..7, а :TallGrass имеет номер 10.
# Более того, если выставить 10 в обход редактора, RMXP при следующей правке
# тайлсета в Database может сбросить непонятное ему значение обратно в 0.
#
# Поэтому тег 7 используется как ПОМЕТКА в редакторе (её RMXP не трогает), а
# этот скрипт переводит помеченные тайлы в настоящий 10. Список обработанных ID
# накапливается в TILE_LIST, так что после любого сброса из RMXP достаточно
# запустить скрипт снова — он восстановит теги, даже если пометок 7 уже нет.
#
# Тег 7 в Essentials — это :Water (can_surf, can_fish), поэтому оставлять его
# на кустах нельзя: тайлы стали бы пригодными для сёрфинга и рыбалки.
#
# ДВА РЕЖИМА
#
#   ruby .development/tools/apply_terrain_tags.rb --capture
#       Захватывает тайлы, помеченные тегом 7, добавляет их в список и применяет
#       тег 10. Запускать ТОЛЬКО сразу после того, как проставил новые пометки.
#
#   ruby .development/tools/apply_terrain_tags.rb
#       Ничего не captures. Просто восстанавливает тег 10 по сохранённому списку.
#       Безопасно запускать сколько угодно раз.
#
# Почему захват сделан явным: тег 7 — это настоящий :Water, и когда в тайлсете
# появится настоящая вода, помеченная семёркой по назначению, автоматический
# захват превратил бы её в высокую траву. Пометка и рабочее значение конфликтуют,
# поэтому режим захвата включается руками и только когда ты этого ждёшь.
# ==============================================================================

require_relative "rgss_stubs"

TILESET_ID = 1
MARKER_TAG = 7    # чем помечаем в редакторе RMXP
TARGET_TAG = 10   # :TallGrass (deep_bush)
TILE_LIST  = File.join(__dir__, "data", "tall_grass_tiles.txt")
TILESETS   = File.join(__dir__, "..", "..", "Data", "Tilesets.rxdata")

tilesets = load_rxdata(TILESETS)
tileset  = tilesets[TILESET_ID]
abort("Тайлсет #{TILESET_ID} не найден") if tileset.nil?

tags     = tileset.terrain_tags
passages = tileset.passages.data

capture = ARGV.include?("--capture")

# 1. Накопленный список из прошлых запусков — источник истины
known = File.exist?(TILE_LIST) ? File.readlines(TILE_LIST).grep(/^\d+/).map(&:to_i) : []
puts "в сохранённом списке: #{known.size}"

# 2. Новые пометки — только в режиме захвата
fresh = []
if capture
  fresh = (0...tags.data.size).select { |i| tags.data[i] == MARKER_TAG }
  puts "захвачено новых пометок тегом #{MARKER_TAG}: #{fresh.size}"
else
  marked = tags.data.count { |v| v == MARKER_TAG }
  if marked.positive?
    puts "тайлов с тегом #{MARKER_TAG} в тайлсете: #{marked} — НЕ трогаю их."
    puts "  если это новые пометки под высокую траву, перезапусти с --capture"
    puts "  если это настоящая вода (:Water) — всё правильно, так и должно быть"
  end
end

all = (known + fresh).uniq.sort
if all.empty?
  abort("Нечего применять: список #{File.basename(TILE_LIST)} пуст" \
        "#{capture ? " и пометок тегом #{MARKER_TAG} нет" : ". Нужен запуск с --capture"}")
end

# 3. Предупреждение: без Bush Flag глубокий куст не сработает
#    (deepBush? требует terrain.deep_bush И passages[tile_id] & 0x40)
no_bush = all.reject { |i| passages[i] & 0x40 == 0x40 }
if !no_bush.empty?
  puts "ВНИМАНИЕ: у #{no_bush.size} тайлов не стоит Bush Flag — на них эффекта не будет."
  puts "  ID: #{no_bush.first(20).inspect}"
end

# 4. Применяем
changed = all.count { |i| tags.data[i] != TARGET_TAG }
all.each { |i| tags.data[i] = TARGET_TAG }

File.write(TILE_LIST, <<~HEADER + all.join("\n") + "\n")
  # Тайлы тайлсета #{TILESET_ID} с terrain tag #{TARGET_TAG} (:TallGrass).
  # Автогенерируется .development/apply_terrain_tags.rb — не редактировать вручную.
HEADER

save_rxdata(TILESETS, tilesets)

puts "в списке всего: #{all.size}, изменено сейчас: #{changed}"
puts "список сохранён: #{TILE_LIST}"
puts "готово. Tilesets.rxdata обновлён (бэкап .bak рядом, если его ещё не было)."
