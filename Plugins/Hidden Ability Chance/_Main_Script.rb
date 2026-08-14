#===============================================================================
# Hidden Ability Chance — шанс скрытой способности у диких покемонов.
#===============================================================================
# ЗАЧЕМ
#
# В ванильном Essentials v21 дикий покемон НИКОГДА не получает скрытую
# способность. Индекс способности выводится из personalID:
#
#   def ability_index
#     @ability_index = (@personalID & 1) if !@ability_index
#
# `personalID & 1` даёт только 0 или 1, а скрытая способность — индекс 2.
# Единственный источник индекса 2 во всём движке — предмет Ability Patch.
# При этом данные есть: HiddenAbilities прописаны у 762 видов из 898.
#
# ЦИФРЫ
#
# В официальных играх общего шанса HA у диких покемонов нет — он всегда привязан
# к особому контенту (Dream World, Friend Safari, SOS-цепочки, рейды). Поэтому
# базовый шанс здесь намеренно очень низкий: скрытая способность у случайного
# дикого покемона должна быть удачей, а не добычей.
#
# ГЛАВНОЕ ПРАВИЛО ЭТОЙ МЕХАНИКИ
#
# Шанс, который нельзя обнаружить, хуже, чем его отсутствие: без детектора игрок
# должен переловить сотни покемонов и проверить каждого. Поэтому базовый шанс
# работает как фоновая редкость, а осмысленной охота становится только с
# анализатором — он и повышает шанс, и показывает результат прямо в бою,
# до поимки.
#===============================================================================

module HiddenAbilityChance
  #-----------------------------------------------------------------------------
  # Шансы заданы знаменателем: 50 означает 1/50. Значение 0 отключает шанс.
  #
  # Ориентир по времени (энкаунтер раз в ~15-25 шагов, ~30 с на цикл встречи):
  #   1/20  — ~10 минут до встречи с HA, ~1 час до конкретного вида
  #   1/50  — ~25 минут,                 ~2.5 часа
  #   1/100 — ~50 минут,                 ~5 часов  <- уже стена, не награда
  #
  # База 0 повторяет оригинальные игры: без прибора HA у диких не бывает вовсе.
  # Заодно получение анализатора ощущается как открытие целого слоя, а не как
  # прибавка к числу.
  #-----------------------------------------------------------------------------
  BASE_DENOMINATOR     = 0    # без анализатора HA у диких не бывает
  ANALYZER_DENOMINATOR = 50   # медленный фоновый вариант

  #-----------------------------------------------------------------------------
  # Ключевой предмет, включающий повышенный шанс и показ в бою.
  #-----------------------------------------------------------------------------
  ANALYZER_ITEM = :RESONANCEANALYZER

  #-----------------------------------------------------------------------------
  # Аномальные зоны: id_карты => знаменатель. Здесь скрытая способность подаётся
  # не как редкий дроп, а как симптом — покемон изменён аномалией.
  #
  #   ANOMALY_MAPS = { 12 => 4, 13 => 1 }   # 1/4 и всегда
  #-----------------------------------------------------------------------------
  ANOMALY_MAPS = {}

  module_function

  def analyzer?
    return $bag&.has?(ANALYZER_ITEM) || false
  end

  def denominator_for_current_map
    anomaly = ANOMALY_MAPS[$game_map&.map_id]
    return anomaly if anomaly                      # аномалия важнее анализатора
    return analyzer? ? ANALYZER_DENOMINATOR : BASE_DENOMINATOR
  end

  # Скрытая способность есть не у всех видов, и у форм она своя.
  def has_hidden_ability?(pkmn)
    data = GameData::Species.get_species_form(pkmn.species, pkmn.form)
    return data && !data.hidden_abilities.empty?
  end

  def apply(pkmn)
    return if pkmn.nil?
    return if !has_hidden_ability?(pkmn)
    denominator = denominator_for_current_map
    # 0 или отрицательное значение означает «никогда». Отдельная проверка нужна ещё
    # и потому, что rand(0) в Ruby возвращает не целое, а float от 0.0 до 1.0.
    return if denominator.nil? || denominator <= 0
    return if rand(denominator) != 0
    pkmn.ability_index = 2
    # Сброс обязателен: способность кешируется, и без него останется прежняя.
    # Тот же порядок использует обработчик Ability Patch в ядре.
    pkmn.ability = nil
  end
end

#===============================================================================
# Роллинг при генерации дикого покемона.
#===============================================================================
alias hidden_ability_chance_generate_wild_pokemon pbGenerateWildPokemon

def pbGenerateWildPokemon(species, level, isRoamer = false)
  pkmn = hidden_ability_chance_generate_wild_pokemon(species, level, isRoamer)
  HiddenAbilityChance.apply(pkmn)
  return pkmn
end

#===============================================================================
# Показ в бою до поимки.
#
# Подключаемся к pbStartBattleSendOut — это метод, который выводит «A wild X
# appeared!». Хук :on_start_battle не подошёл бы: он срабатывает ДО генерации
# противников, там ещё некого проверять.
#===============================================================================
class Battle
  alias hidden_ability_chance_start_battle_send_out pbStartBattleSendOut

  def pbStartBattleSendOut(sendOuts)
    hidden_ability_chance_start_battle_send_out(sendOuts)
    return if !wildBattle?
    return if !HiddenAbilityChance.analyzer?
    pbParty(1).each do |pkmn|
      next if pkmn.nil? || pkmn.ability_index != 2
      pbDisplay(_INTL("The Resonance Analyzer is reacting — {1} has a Hidden Ability!", pkmn.name))
    end
  end
end
