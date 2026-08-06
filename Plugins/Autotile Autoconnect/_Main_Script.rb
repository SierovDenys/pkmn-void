#===============================================================================
# Autotile Autoconnect — автостыковка для extra-автотайлов.
#===============================================================================
# ЗАЧЕМ
#
# Обычные 7 слотов стыкует РЕДАКТОР RPGXP.exe. Про EXTRA_AUTOTILES он не знает,
# поэтому extra-автотайл обычно требует ручного выбора варианта из 48.
#
# Плагин считает вариант в рантайме: рисуешь ОДНИМ тайлом, игра смотрит на
# восьмерых соседей и подставляет нужную стыковку.
#
# ГЛАВНОЕ: ХВАТАЕТ ОДНОГО ID
#
# Штатный большой extra-автотайл занимает 48 ID тайлсета, потому что номер
# варианта закодирован в самом ID: AutotileBitmaps#set_src_rect берёт строку
# картинки как (tile_id % 48).
#
# Но имя файла и номер варианта там берутся из РАЗНЫХ источников:
#
#   def set_src_rect(tile, tile_id)
#     return if !@bitmaps[tile.filename]                    # файл — из tile.filename
#     ...
#     tile.src_rect.y = (tile_id % TILES_PER_AUTOTILE) * 32 # вариант — из tile_id
#
# Значит автотайл можно объявить ОДИНОЧНЫМ (второй массив EXTRA_AUTOTILES, 1 ID),
# и отдельно подсунуть в set_src_rect номер варианта. Имя файла к тому моменту
# уже проставлено по сырому ID и не пострадает.
#
# Экономия: 1 ID вместо 48. Резерв тайлсета на 48 мест вмещает 48 таких
# автотайлов вместо одного.
#
# КАК СЧИТАЕТСЯ ВАРИАНТ
#
# Обе недостающие части уже есть в TileDrawingHelper:
#   tableNeighbors              — 8 бит по 8 соседям
#   NEIGHBORS_TO_AUTOTILE_INDEX — 256 записей, маска -> вариант 0..47
# Ими же пользуется генератор случайных подземелий. Маска считается своя, потому
# что «свой сосед» определяется по принадлежности автотайлу, а не по равенству ID.
#
# ФОРМАТ ФАЙЛА
#
# Автотайл должен быть полноценным шаблоном 96x128 (или 96x192 в expanded format)
# на кадр — то есть тем же файлом, что кладут в обычный слот. Обычные одиночные
# автотайлы 32x32 плагин не ломает: для них set_src_rect выходит раньше, чем
# дойдёт до tile_id (ветка height == SOURCE_TILE_HEIGHT), и подстановка варианта
# просто не имеет эффекта.
#
# ОГРАНИЧЕНИЯ
#
# 1. В редакторе RMXP стыковки не видно — там всегда тот тайл, которым рисуешь.
#    Неисправимо: стыковка редактора живёт внутри RPGXP.exe.
# 2. Соседи за краем карты считаются продолжением края (координаты зажимаются).
#    Стыковка через границы соединённых карт ($map_factory) не поддерживается.
# 3. Учитывается только свой слой: вода на слое 1 не состыкуется с водой на слое 2.
#===============================================================================

class TilemapRenderer
  #-----------------------------------------------------------------------------
  # Разрешённый вариант хранится на спрайте: он нужен и в refresh_tile_src_rect,
  # и при обновлении кадра анимации, куда координаты карты уже не доходят.
  #-----------------------------------------------------------------------------
  class TileSprite
    attr_accessor :autoconnect_id
  end

  module AutoConnect
    module_function

    # [опорное значение, режим] или nil, если тайл не из extra-автотайлов.
    #   :block  — штатный большой автотайл, занимает 48 ID
    #   :single — автотайл на одном ID, вариант подставляем мы
    def descriptor(map, tile_id)
      return nil if tile_id < TILESET_START_ID
      arrays = EXTRA_AUTOTILES[map.tileset_id]
      return nil if arrays.nil?
      large   = arrays[0] || []
      singles = arrays[1] || []
      single_start = TILESET_START_ID + (large.length * TILES_PER_AUTOTILE)
      if tile_id < single_start
        index = (tile_id - TILESET_START_ID) / TILES_PER_AUTOTILE
        return [TILESET_START_ID + (index * TILES_PER_AUTOTILE), :block]
      end
      index = tile_id - single_start
      return nil if index < 0 || index >= singles.length
      return [tile_id, :single]
    end

    def same?(map, x, y, layer, base, mode)
      x = x.clamp(0, map.width - 1)
      y = y.clamp(0, map.height - 1)
      id = map.data[x, y, layer]
      return false if id.nil?
      return id == base if mode == :single
      return id >= base && id < base + TILES_PER_AUTOTILE
    end

    def variant(map, x, y, layer, base, mode)
      mask = 0
      mask |= 0x01 if same?(map, x,     y - 1, layer, base, mode)   # N
      mask |= 0x02 if same?(map, x + 1, y - 1, layer, base, mode)   # NE
      mask |= 0x04 if same?(map, x + 1, y,     layer, base, mode)   # E
      mask |= 0x08 if same?(map, x + 1, y + 1, layer, base, mode)   # SE
      mask |= 0x10 if same?(map, x,     y + 1, layer, base, mode)   # S
      mask |= 0x20 if same?(map, x - 1, y + 1, layer, base, mode)   # SW
      mask |= 0x40 if same?(map, x - 1, y,     layer, base, mode)   # W
      mask |= 0x80 if same?(map, x - 1, y - 1, layer, base, mode)   # NW
      return TileDrawingHelper::NEIGHBORS_TO_AUTOTILE_INDEX[mask]
    end
  end

  #-----------------------------------------------------------------------------
  # Координаты карты в refresh_tile не приходят (x/y — позиция спрайта в сетке),
  # поэтому пересчитываем их той же формулой, что и вызывающий цикл.
  #
  # Дальше вызываем оригинал с СЫРЫМ tile_id: по нему определяется имя файла,
  # проходимость и приоритет. Вариант подменяется ниже, в src_rect.
  #-----------------------------------------------------------------------------
  alias autoconnect_refresh_tile refresh_tile

  def refresh_tile(tile, x, y, map, layer, tile_id)
    tile.autoconnect_id = nil
    desc = AutoConnect.descriptor(map, tile_id)
    if desc
      base, mode = desc
      offset_x = (map.display_x.to_f / Game_Map::X_SUBPIXELS).round
      offset_y = (map.display_y.to_f / Game_Map::Y_SUBPIXELS).round
      if ZOOM_X != 1
        offset_x = ((offset_x + (Graphics.width / 2)) * ZOOM_X) - (Graphics.width / 2)
        offset_y = ((offset_y + (Graphics.height / 2)) * ZOOM_Y) - (Graphics.height / 2)
      end
      map_x = x + (offset_x / DISPLAY_TILE_WIDTH)
      map_y = y + (offset_y / DISPLAY_TILE_HEIGHT)
      v = AutoConnect.variant(map, map_x, map_y, layer, base, mode)
      # :single — отдаём голый номер варианта, set_src_rect берёт его как % 48.
      # :block  — сохраняем штатную адресацию base + variant.
      tile.autoconnect_id = (mode == :single) ? v : base + v
    end
    autoconnect_refresh_tile(tile, x, y, map, layer, tile_id)
  end

  #-----------------------------------------------------------------------------
  # Обе точки, где tile_id превращается в строку картинки.
  #-----------------------------------------------------------------------------
  alias autoconnect_refresh_tile_src_rect refresh_tile_src_rect

  def refresh_tile_src_rect(tile, tile_id)
    autoconnect_refresh_tile_src_rect(tile, tile.autoconnect_id || tile_id)
  end

  alias autoconnect_refresh_tile_frame refresh_tile_frame

  def refresh_tile_frame(tile, tile_id)
    autoconnect_refresh_tile_frame(tile, tile.autoconnect_id || tile_id)
  end
end
