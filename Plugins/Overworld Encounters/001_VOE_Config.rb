# IMPORTANT!!
# If you are using Roaming Pokémon, it is necessary to add
# next if $game_temp.overworld_encounter
# after each mention of: next if $PokemonGlobal.roamedAlready
# otherwise Overworld Encounters can trigger Roaming Battles

class VOESettings
  BLACK_LIST_MAPS = [61, 62, 63, 64, 65, 66]
  BLACK_LIST_WATER = [96]
  REFLECTION_MAP_IDS = [70, 103, 105]

  GRASS_TILES = [
    :Grass, :TallGrass, :DeepSand, :SpringGrass, :SpringTallGrass, :SummerGrass, :SummerTallGrass,
    :AutumnGrass, :AutumnTallGrass, :WinterGrass, :WinterTallGrass, :SpringRockyGrass, :SummerRockyGrass,
    :AutumnRockyGrass, :WinterRockyGrass, :SpringForestGrass, :SummerForestGrass, :AutumnForestGrass,
    :WinterForestGrass,
  ]
  WATER_TILES = [:Water, :StillWater, :Dirty_Water, :SpringWater, :SummerWater, :AutumnWater, :WinterWater]

  SPAWN_ANIMATION = 2
  SHINY_ANIMATION = 53
  FLEE_SOUND = "Door exit"
  SHINY_SOUND = "Mining reveal"
  LOG_SPAWNS = false
  DISABLE_SETTINGS = false
  MAX_DISTANCE = 8
  DELETE_EVENTS = true
  DELETE_SHINY = false
  BRIGHT_SHINY = true # Shinies won't be affected by DayNight Tone
  COLORFUL_TEXT = true
  WATER_SPAWNS_ONLY_SURFING = true

  DIFFERENT_ENCOUNTERS = false
  ENCOUNTER_TABLE = 1

  # Use 0 to disable overworld shinies. Set to (SETTINGS::SHINY_POKEMON_CHANCE / 65536) for normal odds.
  SHINY_RATE = 8192

  # How many encounters will be spawned on each map (mapId => numberOfEvents) (0 = default)
  MAX_PER_MAP = {
    # 42 => 0,
    # 57 => 3,
    0 => 5,
  }

  # The amount of encounters currently on the map
  def self.current_encounters
    return 0 unless $game_map

    unless @current_encounters
      count = 0
      $game_map.events.each_value do |event|
        next unless event.name[/OverworldPkmn/i]

        count += 1
      end
      @current_encounters = count
    end
    @current_encounters
  end

  # Setter for the current encounters
  class << self
    attr_writer :current_encounters
  end

  # Get the max amount of encounters for this map
  def self.get_max
    return MAX_PER_MAP[$game_map.map_id] if MAX_PER_MAP[$game_map.map_id]

    MAX_PER_MAP[0]
  end
end

MenuHandlers.add(
  :options_menu, :owpkmnenabled,
  {
    "name" => _INTL("Overworld Encounters"),
    "order" => 100,
    "type" => EnumOption,
    "parameters" => [_INTL("On"), _INTL("Off")],
    "description" => _INTL("Enable/disable overworld encounters."),
    "condition" => proc { next VOESettings::DISABLE_SETTINGS },
    "get_proc" => proc { next $PokemonSystem.owpkmnenabled },
    "set_proc" => proc { |value, _scene| $PokemonSystem.owpkmnenabled = value },
  }
)

class Spriteset_Map
  alias voe_update update

  def update
    voe_update

    @character_sprites.each do |sprite|
      next unless sprite.character
      next unless VOESettings::BRIGHT_SHINY
      if sprite.character.name&.include?("(Shiny)")
        sprite.tone.set(0, 0, 0, 0)
      end
    end
  end
end

class PokemonSystem
  attr_accessor :owpkmnenabled # Whether Overworld Pokémon appear (0=on, 1=off)

  def owpkmnenabled=(val); @owpkmnenabled = val; end
  def owpkmnenabled; @owpkmnenabled; end
end

class PokemonOption_Scene
  alias owpkmn_pbEndScene pbEndScene unless method_defined?(:owpkmn_pbEndScene)

  def pbEndScene
    owpkmn_pbEndScene
    if $PokemonSystem.owpkmnenabled == 1 || $PokemonEncounters && VOESettings::DISABLE_SETTINGS
      $game_map.events.each_value do |event|
        next unless event.name[/OverworldPkmn/i]

        pbDestroyOverworldEncounter(event, true, false)
      end
    end
  end
end

# --------------------------------------------------------
# Method from Followers EX Plugin
# --------------------------------------------------------
def pbOWSpriteFilename(species, form = 0, gender = 0, shiny = false, shadow = false, swimming = false)
  # Check for swimming sprites first if swimming
  if swimming
    folder = shiny ? "Swimming Shiny" : "Swimming"
    ret = GameData::Species.check_graphic_file(
      "Graphics/Characters/", species, form,
      gender, shiny, shadow, folder
    )
    return ret if !nil_or_empty?(ret)

    # If no swimming sprite, check for levitate sprites (for airborne Pokemon)
    folder = shiny ? "Levitates Shiny" : "Levitates"
    ret = GameData::Species.check_graphic_file(
      "Graphics/Characters/", species, form,
      gender, shiny, shadow, folder
    )
    return ret if !nil_or_empty?(ret)
  end

  # Fall back to regular follower sprites
  ret = GameData::Species.check_graphic_file(
    "Graphics/Characters/", species, form,
    gender, shiny, shadow, "Followers"
  )
  ret = "Graphics/Characters/Followers/" if nil_or_empty?(ret)
  return ret
end

def pbChooseWildPokemonByVersion(map_ID, enc_type, version)
  # Get the encounter table
  encounter_data = GameData::Encounter.get(map_ID, version)
  enc_list = encounter_data.types[enc_type]

  # Calculate the total probability value
  chance_total = 0

  return [:DITTO, 69] if enc_list.nil?
  enc_list.each { |a| chance_total += a[0] }

  # Escolhe o Pokémon aleatoriamente a partir da Tabela de Encontro
  rnd = rand(chance_total)
  encounter = nil
  enc_list.each do |enc|
    rnd -= enc[0]
    next if rnd >= 0

    encounter = enc
    break
  end

  # Return [species, level]
  level = rand(encounter[2]..encounter[3])
  [encounter[1], level]
end

def pbGetTileID(map_id, x, y)
  return 0 if (x == 0 || y == 0) || (x.nil? || y.nil?)
  debug = false

  echoln "[getTileID] #{map_id}, #{x}, #{y}" if debug
  thistile = $map_factory.getRealTilePos(map_id, x, y)
  map = $map_factory.getMap(thistile[0])
  tile_id = map.data[thistile[1], thistile[2], 0]

  echoln "[getTileID] #{tile_id}" if debug
  return 0 if tile_id == nil
  return GameData::TerrainTag.try_get(map.terrain_tags[tile_id]).id
end

def pbConvertMoveCommands(list)
  list.map do |entry|
    if entry.is_a?(Symbol)
      # Ex: :move_down
      code = VOE_MOVE_COMMANDS[entry]
      RPG::MoveCommand.new(code)
    elsif entry.is_a?(Array)
      # Ex: [:wait, 30] ou [:jump, 1, -1]
      cmd, *params = entry
      code = VOE_MOVE_COMMANDS[cmd]
      RPG::MoveCommand.new(code, params)
    elsif entry.is_a?(Hash)
      # Ex: { :switch_on => 5 }
      cmd = entry.keys.first
      args = [entry[cmd]].flatten
      code = VOE_MOVE_COMMANDS[cmd]
      RPG::MoveCommand.new(code, args)
    else
      entry
    end
  end
end

VOE_MOVE_COMMANDS = {
  move_down: 1,
  move_left: 2,
  move_right: 3,
  move_up: 4,

  move_lower_left: 5,
  move_lower_right: 6,
  move_upper_left: 7,
  move_upper_right: 8,

  move_random: 9,
  move_toward_player: 10,
  move_away_from_player: 11,
  move_forward: 12,
  move_backward: 13,

  jump: 14,                  # Ex: [:jump, 2, 1]
  wait: 15,                  # Ex: [:wait, 60]

  turn_down: 16,
  turn_left: 17,
  turn_right: 18,
  turn_up: 19,

  turn_right_90: 20,
  turn_left_90: 21,
  turn_180: 22,
  turn_90_random: 23,

  turn_random: 24,
  turn_toward_player: 25,
  turn_away_from_player: 26,

  switch_on: 27,             # Ex: { switch_on: "A" }
  switch_off: 28,            # Ex: { switch_off: "A" }
  change_speed: 29,          # Ex: [:change_speed, 4]
  change_freq: 30,           # Ex: [:change_freq, 3]

  walk_anime_on: 31,
  walk_anime_off: 32,
  step_anime_on: 33,
  step_anime_off: 34,
  direction_fix_on: 35,
  direction_fix_off: 36,
  through_on: 37,
  through_off: 38,
  always_on_top_on: 39,
  always_on_top_off: 40,

  change_graphic: 41,        # Ex: [:change_graphic, "Trainer", 2, 1]
  change_opacity: 42,        # Ex: [:change_opacity, 128]
  change_blend: 43,          # Ex: [:change_blend, 1]
  play_se: 44,               # Ex: [:play_se, RPG::AudioFile.new("Jump", 80, 100)]

  script: 45,                # Ex: [:script, "echoln('test!')"]
  end: 0,
}
