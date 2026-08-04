def pbGenerateOverworldEncounters(water = false)
  return if $scene.is_a?(Scene_Intro) || $scene.is_a?(Scene_DebugIntro)
  return if !$PokemonEncounters
  return if $player.able_pokemon_count == 0
  # return if $PokemonGlobal.surfing

  if VOESettings.current_encounters < VOESettings.get_max
    tile = get_grass_tile
    tile_id = $game_map.map_id < 2 ? :Grass : pbGetTileID($game_map.map_id, tile[0], tile[1])
    water = VOESettings::WATER_TILES.include?(tile_id)

    return if tile == []
    echoln "# --------------------------------------------------------------- #" if VOESettings::LOG_SPAWNS
    echoln "[generateOWEncounter line 15] #{tile_id} (#{tile}) [Water? #{water}]" if VOESettings::LOG_SPAWNS

    if water
      enc_type = $PokemonEncounters.find_valid_encounter_type_for_time(:Water, pbGetTimeNow)
    else
      enc_type = $PokemonEncounters.find_valid_encounter_type_for_time(:Land, pbGetTimeNow)
      if enc_type.nil?
        enc_type = $PokemonEncounters.has_cave_encounters? ? $PokemonEncounters.find_valid_encounter_type_for_time(:Cave, pbGetTimeNow) : $PokemonEncounters.encounter_type
      end
    end

    echoln "[generateOWEncounter line 26] #{enc_type}" if VOESettings::LOG_SPAWNS
    return if enc_type.nil?

    # ========================
    # Create Pokemon Routine
    # ========================

    if VOESettings::DIFFERENT_ENCOUNTERS
      pkmn = pbChooseWildPokemonByVersion($game_map.map_id, enc_type, VOESettings::ENCOUNTER_TABLE)
    else
      pkmn = $PokemonEncounters.choose_wild_pokemon_for_map($game_map.map_id, enc_type)
    end

    pkmn = Pokemon.new(pkmn[0], pkmn[1])

    echoln "[generateOWEncounter line 59] (#{event.name}) #{pkmn.species} for #{enc_type}" if VOESettings::LOG_SPAWNS
    echoln "# --------------------------------------------------------------- #" if VOESettings::LOG_SPAWNS

    if [:SCATTERBUG, :SPEWPA, :VIVILLON].include?(pkmn.species)
      debug = true
      region = pbGetCurrentRegion

      v_form = case region
        when 0; 3 # Creatia: Garden Pattern
        else; 0         end
      pkmn.form = v_form
      echoln "Vivillon family changed to form #{v_form}" if debug
    end

    echoln "Spawning #{pkmn.name} (Water? #{water})" if VOESettings::LOG_SPAWNS

    pkmn.level = (pkmn.level + rand(-2..2)).clamp(2, GameData::GrowthRate.max_level)
    pkmn.calc_stats
    pkmn.reset_moves
    pkmn.shiny = rand(VOESettings::SHINY_RATE) == 1

    echoln "#{pkmn.name} nature: #{pkmn.nature.id} (#{pkmn.nature.id.class.to_s})" if VOESettings::LOG_SPAWNS

    # ========================
    # Create Event Routine
    # ========================
    r_event = Rf.create_event do |e|
      # Event Name
      e.name = water ? "OverworldPkmn_Swim" : "OverworldPkmn"
      e.name = e.name + " Reflection" if VOESettings::REFLECTION_MAP_IDS.include?($game_map.map_id)
      e.name = e.name + " (Shiny)" if pkmn.shiny?

      # Event position
      e.x = tile[0]
      e.y = tile[1]

      # Event Page
      e.pages[0].step_anime = true
      e.pages[0].trigger = 0
      e.pages[0].list.clear
      e.pages[0].move_speed = 2
      e.pages[0].move_frequency = 2

      move_data = VOEMovement::Poke_Move[pkmn.species] || VOEMovement::Poke_Move[pkmn.species.to_sym]
      move_data = VOEMovement::Nature_Move[pkmn.nature.id] unless move_data

      if move_data
        echoln "#{pkmn.name} (#{pkmn.nature.id}) move route:\n#{move_data[:move_route]}" #if VOESettings::LOG_SPAWNS

        route = RPG::MoveRoute.new
        route.repeat = true
        route.skippable = true
        route.list = pbConvertMoveCommands(move_data[:move_route])

        e.pages[0].move_speed = move_data[:move_speed] if move_data.has_key?(:move_speed)
        e.pages[0].move_frequency = move_data[:move_frequency] if move_data.has_key?(:move_frequency)
        e.pages[0].move_type = 3
        e.pages[0].move_route = route
        e.pages[0].trigger = 2 if move_data.has_key?(:touch) && move_data[:touch] == true
      end

      # Event Final Compilation
      Compiler.push_script(e.pages[0].list, "pbInteractOverworldEncounter")
      Compiler.push_end(e.pages[0].list)
    end

    event = r_event[:event]

    event.setVariable([pkmn, r_event])
    echoln "Spawned Event Name: #{event.name}" if VOESettings::LOG_SPAWNS

    spriteset = $scene.spriteset($game_map.map_id)
    dist = (((event.x - $game_player.x).abs + (event.y - $game_player.y).abs) / 4).floor
    if pkmn.shiny?
      pbSEPlay(VOESettings::SHINY_SOUND, [75, 65, 55, 40, 27, 22, 15][dist], 100) if dist <= 6 && dist >= 0
      spriteset&.addUserAnimation(VOESettings::SHINY_ANIMATION, event.x, event.y, true, 1)
    end
    pbChangeEventSprite(event, pkmn, water)
    event.direction = rand(1..4) * 2
    event.through = false
    spriteset&.addUserAnimation(VOESettings::SPAWN_ANIMATION, event.x, event.y, true, 1)
    GameData::Species.play_cry_from_pokemon(pkmn, [75, 65, 55, 40, 27, 22, 15][dist]) if dist <= 6 && dist >= 0 && rand(20) == 1 unless dist.nil?
    VOESettings.current_encounters += 1
  end
end

EventHandlers.add(:on_enter_map, :clear_previous_overworld_encounters,
                  proc { |old_map_id|
  #echoln ">> Entered at Proc Clear Previous Overworld Encounter"

  # Blacklist
  next if VOESettings::BLACK_LIST_MAPS.include?($game_map.map_id)
  next if $game_map.map_id < 2
  next if old_map_id.nil? || old_map_id < 2
  next unless $map_factory # < Changed from $MapFactory to $map_factory

  # Add Old Map to Variable
  map = $map_factory.getMapNoAdd(old_map_id) # < Changed from $MapFactory to $map_factory

  map.events.each_value do |event|
    next unless event.name[/OverworldPkmn/i]
    pbDestroyOverworldEncounter(event, true, false)
  end
  VOESettings.current_encounters = 0

  pbGenerateOverworldEncounters
})

EventHandlers.add(:on_new_spriteset_map, :fix_exisitng_overworld_encounters,
                  proc {
  # Blacklist
  next if VOESettings::BLACK_LIST_MAPS.include?($game_map.map_id)

  next if $game_map.map_id < 2
  next if !$PokemonEncounters
  $game_map.events.each_value do |event|
    next unless event.name[/OverworldPkmn/i]
    next if event.variable.nil?
    pkmn = event.variable[0]
    next if pkmn.nil?
    water = VOESettings::WATER_TILES.include?(pbGetTileID($game_map.map_id, event.x, event.y))
    pbChangeEventSprite(event, pkmn, water)
  end
})

EventHandlers.add(:on_frame_update, :move_overworld_encounters,
                  proc {
  # Blacklist
  next if VOESettings::BLACK_LIST_MAPS.include?($game_map.map_id)

  next if $game_map.map_id < 2
  next if VOESettings::DISABLE_SETTINGS || $PokemonSystem.owpkmnenabled == 1
  next if $game_temp.in_menu
  next if !$PokemonEncounters
  $game_temp.frames_updated += 1
  next if $game_temp.frames_updated < 600 # <<< Updated Frame Rate
  $game_temp.frames_updated = 0
  $game_map.events.each_value do |event|
    next unless event.name[/OverworldPkmn/i]
    next if event.variable.nil?
    pbPokemonIdle(event)
  end
  pbGenerateOverworldEncounters
})

EventHandlers.add(:on_step_taken, :despawn_on_trainer,
                  proc { |event|
  # Blacklist
  next if VOESettings::BLACK_LIST_MAPS.include?($game_map.map_id)

  next if $game_map.map_id < 2
  next if !$scene.is_a?(Scene_Map)
  next if VOESettings::DISABLE_SETTINGS || $PokemonSystem.owpkmnenabled == 1
  next if $game_temp.in_menu
  next if !$PokemonEncounters
  $game_map.events.each_value do |event|
    next unless event.name[/OverworldPkmn/i]
    next if event.variable.nil?
    pbDestroyOverworldEncounter(event) if pbTrainersSeePkmn(event)
  end
})
