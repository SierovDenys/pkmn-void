# **🎮 GAMEPLAY MECHANICS & DESIGN IDEAS**

## **📡 1\. Frequency Scanner & Search Radar (Inspiration: Voices of the Void)**

The primary tool for the agent/researcher to detect anomalies, signals, and encrypted data:

> * **Interface & Mechanics:** A handheld or stationary device tunable across various frequency bands and signal channels.  
> * **Anomaly & Audio Tracking:** Utilizes audio direction finders (pitch and static noise intensity increase upon approach) along with waveform visuals.  
> * **World Applications:**  
  * Locating hidden underground bunkers, abandoned laboratories, and encrypted caches.  
  * Triggering spawns of rare anomalous Pokémon (Ultra Beasts, Deoxys, etc.) that respond to specific radio frequencies.  
  * Intercepting faction transmissions (Government, Syndicate) and distress calls from lost NPCs.

## **🎭 2\. Event-Driven Narrative & Emergent Storytelling**

Transitioning from rigid, linear quests to a situational event system (similar to *Baldur's Gate 3* / *RimWorld*):

> * **Events Over Linear Quests:** Rather than traditional fetch quests, players encounter dynamic world situations (e.g., *Anomalous surge trapping a research squad*, *Hostile standoff between two NPCs*, *Power grid failure at a station*).  
> * **Emergent Outcomes:** Every event features 3–4 alternative resolutions influenced by:  
  * Current Pokémon party composition (utilizing systemic type capabilities).  
  * Dialogue choices and negotiations with LLM-driven NPCs.  
  * Tactical usage of inventory items and the frequency scanner.  
> * **Domino Effect:** Decisions made during events in early zones dynamically alter faction power dynamics and available events in subsequent regions.

### **Architecture (clarified)**

Branching lives **inside a zone** and converges on a single checkpoint at its exit. This constraint is what makes the system tractable for a solo developer.

> * **A zone checkpoint is one value (1–3) in a game Variable.** Later zones read **only that value**, never the path taken to reach it. The state space stays linear: 4 zones × 3 outcomes = 12 states, not thousands. The moment content starts asking "did the player save that NPC back in event three", linearity collapses back into an exponential.  
> * **Authored branching needs no custom system.** Game Switches and Variables are saved automatically, and RMXP event pages already support conditions on them. "A couple of variations per zone" requires zero code — the work is entirely content.  
> * **Side quests run on Modern Quest System** (`activateQuest` / `advanceQuestToStage` / `completeQuest`; the plugin is already installed). Rule: quests write to their own state and **never touch checkpoint Variables**. That is what keeps them event-driven without ever branching the main storyline.  
> * **Custom code is only needed for dynamic situation selection** — when an event picks itself based on party composition, reputation, or time. The scaffold can be copied from the engine's `HandlerHash` / `MenuHandlers`; the trigger point is map entry or a step counter.  
> * **Estimate:** authored branching — days. Dynamic spawner — 1–2 weeks. The dominant cost remains content, not code.

## **👥 3\. Deep NPC & Faction Relationship System**

Character interactions are driven by trust metrics, regional reputation, and personal agendas:

> * **Relationship Scale:** Player actions (assisting, betraying, covert surveillance, trading scanner data) actively shift alignment values.  
> * **Context-Aware NPC Responses:** Characters dynamically adjust dialogue options, vendor prices, willingness to share secrets, or even refuse assistance based on the player's reputation.  
> * **Personal Companion Goals:** Companions and recurring wanderers possess distinct motivations (e.g., searching for a missing Pokémon or exposing Syndicate corruption). Players can choose to enable or thwart their objectives.

## **🐾 4\. Pokémon as Environmental & Social Tools**

World interaction and dialogue engagement are built upon elemental types and innate Pokémon traits rather than rigid HM moves:

> * **Fire:** Burning away corrupted thickets, clearing wooden debris, purging anomalous biomass.  
> * **Electric:** Powering abandoned generators, hacking electronic locks in underground bunkers, rebooting fried equipment.  
> * **Water / Ice:** Cooling overheated anomaly cores, forming temporary ice bridges across hazards.  
> * **Ghost / Psychic:** Phasing through thin spatial boundaries, detecting hidden signals without relying strictly on the scanner.  
> * **Fairy / Charm:** Utilizing Fairy-type Pokémon in NPC dialogues to pacify hostiles, persuade individuals, secure discounts, or manipulate emotional states (similar to Charm/Persuasion checks in tabletop RPGs).  
> * **Difficulty System & Stat Checks (Nice to Have / Optional):**  
  * Stat requirements instead of simply checking for type availability (e.g., Attack stat checks for breaking tough obstacles or *Beauty/Cute/Charisma* stats from Contest mechanics for persuading NPCs).  
  * If stats fall short, the Pokémon either fails the action or requires stat boosts (items, buffs, higher levels).  
> * **Non-linear Approach:** Overcoming an obstacle always offers 2–3 alternative solutions depending on the active Pokémon party.

## **🤖 5\. Dynamic Adventurer NPCs (LLM Integration)**

Randomly spawning wanderers, researchers, and rival trainers roaming open-world zones with autonomous behavior:

> * **LLM-Driven Decision Making:** The language model determines the NPC's immediate goals and disposition based on their personality profile, world state, and the player's recent actions (Low Priority / Optional).  
> * **Dynamic Interactions:**  
  * **Combat:** Challenging the player to a duel or ambushing them for resources.  
  * **Bartering & Intel:** Offering unique trades (items/Pokémon) or selling coordinates to hidden frequency signals.  
  * **Cooperative Actions:** Negotiated agreements where NPCs agree to follow the player and assist in exploration (including using their own Pokémon to clear obstacles).  
> * **Persistent Rumors & Reputation:** NPCs log interactions with the player, spreading rumors throughout nearby settlements that influence future encounters with other faction members. This part runs on a plain state table and requires no LLM.

### **How the LLM actually drives NPCs (clarified)**

The model **never invents consequences**. It picks a label from a closed set defined in code; every consequence is authored logic written once.

```
follow | battle | trade | give_intel | refuse | leave
```

> * **Sidecar process.** The game never reaches the network itself. A small local script listens on `http://127.0.0.1`. It holds the API key, performs TLS, parses JSON, and **validates the response against the allowed action list**. The game receives a trivial format: first line is the label, the rest is dialogue. No JSON parser is needed in-game (Essentials has none).  
> * **Never blocks a frame.** The game posts a request, immediately receives a job id, and polls for the result from the map update loop. There is precedent in the engine itself: `PluginManager.error` runs `Thread.new` alongside `Graphics.update`, proving Ruby threads coexist with the mkxp-z frame loop.  
> * **Justification is mandatory.** The model returns a short in-character line that the NPC speaks **before** acting. Without it the choice reads as randomness and the whole system feels like a dice roller.  
> * **Safety rails:**  
  * preconditions are re-checked in-game at execution time — party alive, item present, NPC not already in battle (the world may have changed while the request was in flight);  
  * the chosen action and its prompt are logged, otherwise "the NPC attacked me out of nowhere" is impossible to reproduce;  
  * sidecar not running, timeout, or malformed response → fall back to an authored default line. The game stays fully playable without the LLM; the integration is strictly optional and intended for personal use.  
> * **Existing engine entry points:** battle — `TrainerBattle.start`, trade — `pbStartTrade`, following the player — via the **Following Pokemon EX** plugin (the core `dependentEvents` API is deprecated and removed in v22; do not build on it).  
> * **Keep the action set small** — 5–8 entries, each of which visibly changes the situation. If half the options amount to "talked and left", the model's choice affects nothing and the machinery runs idle.

## **🏠 6\. Base / Field Camp (Low Priority / Optional)**

The player's central hub for data processing, resting, and mission prep:

> * **Crafting & Equipment Modification:**  
  * Scanner assembly & upgrades (range expansion, extra frequency bands).  
  * Crafting custom Pokéballs, consumables, and hazard-protection gear using anomalous materials.  
> * **Cultivation & Breeding:**  
  * Berry plots for cultivating rare buffing berries and lures.  
  * Breeding enclosures to hatch Pokémon and regular farms.  
> * **Signal Processing & Server Rack (Voices of the Void Style):**  
  * Downloading raw audio/signal captures from field ops to process over time, unlocking exact coordinates to secret bunkers or faction intel.  
> * **Hub Automation & Pokémon Workstation Assignments:**  
  * Assigning Pokémon to base tasks (Electric type powers server racks, Fire type powers the lab, Water type waters berry patches).

## **🌧️ 7\. Dynamic Environment & Weather (Future Expansion)**

> * Changing water levels / localized flooding during heavy rain, revealing or submerging alternative pathways.  
> * Emergence or shifting of atmospheric anomaly zones tied to weather events or frequency cycles.

## **⚔️ 8\. Battle Difficulty & Progression**

Battles should be hard and demand preparation rather than grinding.

> * **Hard level cap per act.** A technique from Radical Red / Unbound. Combined with the already-installed **Automatic Level Scaling** (which scales wild and trainer levels to the player's party), this removes grinding as a strategy: there is nowhere to out-level, so the only way to get stronger is **better options** — species, moves, items. Exactly what side quests grant.  
> * **Pick N Pokémon before a battle.** If a Gym Leader fields two, the player also enters two. Removes attrition-by-numbers and turns the fight into a composition puzzle.  
  * **Already in the engine:** `pbEntryScreen` and `PokemonChallengeRules` (the Battle Frontier team-selection screen). Reusable for regular battles; no need to write it from scratch.  
> * **Smarter AI:** active switching, hazard setting (Spikes, Stealth Rock), status play.  
  * **State of the vanilla AI (verified):** skill is set by `SkillLevel` on the **trainer type**, not the individual trainer. When the field is omitted it **falls back to `BaseMoney`**. Every Leader has `BaseMoney = 100`, so they already run at the top threshold.  
  * Thresholds: `medium_skill? >= 32`, `high_skill? >= 48`, `best_skill? >= 100`.  
  * The vanilla AI **does** switch (`Battle::AI::Handlers.should_switch?`, unlocked at medium skill). So the feeling that "bots never switch" is a tuning problem in the handlers and skill flags, not a missing capability.  
  * **Deluxe Battle Kit already rewrites the AI.** The Gen-5-style visuals come from separate add-ons (*Enhanced Battle UI*, *Animated Pokémon System*); the DBK core is a battle-logic framework. It reopens `Battle::AI::AIBattler`, `Battle::AI::AIMove` and `Battle::AI::AITrainer`: "Damage Calc Refactor" (893 lines) rewrites damage scoring, "Updated AI Effects" (554 lines, 37 AI references) rewrites effect awareness.  
  * **Candidate:** *Advanced AI System v2.0* (v21.1, ~23,000 lines across 48 files). Claims: 20+ move scoring factors, 6-factor switching, Stealth Rock / Spikes / Toxic Spikes / Sticky Web awareness, role and archetype detection, prediction and pattern learning (skill 85+), doubles coordination, Mega/Z/Dynamax/Tera timing. Advanced behaviour activates at `SkillLevel >= 50`, with further tiers up to 100.  
  * **The risk is not compatibility as such** — the plugin advertises DBK auto-detection and integrates with its mechanics. The risk is that **both rewrite move scoring inside `Battle::AI::AIMove`**: load order decides whose version wins. That is what needs testing, not the Dynamax/Tera integration the description talks about.  
  * **Conclusion:** first exhaust vanilla tuning via `SkillLevel` per trainer type (ordinary trainers low, Leaders at 100). That reveals what is actually missing. Only then consider the plugin — 23,000 lines of third-party code is a large debugging surface for a solo project.

## **🎁 9\. Reward Economy**

XP and "a better item" do not work in Pokémon: XP is self-serve (just walk into grass), there is no equipment ladder, and a level cap makes surplus levels worthless. Progression in Pokémon runs along different axes, and rewards must be paid in those.

> * **TMs and moves** — unlock new world interactions, not just bigger numbers.  
> * **Access to locations** — and through them, to Pokémon species. The primary currency: it expands both the roster and the set of available solutions.  
> * **Discounts and stock** — e.g. a permanent discount from a merchant after completing their quest.  
> * **Roster directly** — a specific Pokémon, or the ability to catch a species unavailable otherwise.  
> * **Reputation** — shifts prices, willingness to help, access to contacts.  
> * **Information** — a **weak** standalone quest reward. It belongs as a side effect of deepening an NPC relationship, not as payment.  
> * **Held items as sidegrades** (Eviolite, Choice items) — widen builds without inflating numbers.

### **How the player learns they need side quests**

> * **The level cap creates the wall.** Since out-levelling is impossible, hitting a hard opponent leads to only one conclusion: better options are needed. That is the signal; no text is required.  
> * **Rewards must be visible but locked.** A closed gate, a shortcut behind a rockfall, merchant stock on display but unavailable. These advertise the quest themselves without spoiling exploration.  
> * **Hint the direction, never the contents.** "Something strange was seen near the quarry" preserves discovery; "there is a Larvitar at coordinates X" destroys it.  
> * **Pokédex area data as a reward** — see a species once, and the dex shows where the rest live. The discovery still belongs to the player.
