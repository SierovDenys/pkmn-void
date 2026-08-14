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

### **Hidden Abilities as a reward — IMPLEMENTED**

Plugin: `Plugins/Hidden Ability Chance`.

In vanilla Essentials v21 a wild Pokémon **never** gets its Hidden Ability: the index comes from `personalID & 1`, so only 0 or 1. The only source of index 2 in the whole engine is the Ability Patch item. The data exists though — `HiddenAbilities` is defined for 762 of 898 species.

The official games have no flat wild rate either; it is always tied to special content (Dream World, Friend Safari, SOS chains, raids). Hence:

| Condition | Chance |
|---|---|
| Ordinary wild | **0** — as in the originals, no device means no Hidden Abilities at all |
| With the Analyzer | **1/50** — a slow background option |
| Anomaly zones | set per map in `ANOMALY_MAPS`, takes priority over the Analyzer |

**Key principle:** a chance you cannot detect is worse than no chance at all — without a detector the player would have to catch hundreds and inspect each one. So the base chance is zero, and the mechanic switches on together with the item.

**Where 1/50 comes from.** Converting odds into player time (an encounter every ~15–25 steps, ~30 s per encounter cycle):

| Chance | To meet a Hidden Ability | To get a specific species (6-species zone) |
|---|---|---|
| 1/20 | ~10 minutes | ~1 hour |
| **1/50** | ~25 minutes | ~2.5 hours |
| 1/100 | ~50 minutes | ~5 hours — a wall, not a reward |

A Hidden Ability is a build component, not cosmetics. Shinies are hunted at 1/4096 precisely because missing one costs nothing; here the player wants a *specific* species with a *specific* ability.

**The lesson from the official games is structural, not numerical:** there, Hidden Abilities always come from a short deliberate loop (a raid, an SOS chain), never from wandering through grass. So the primary sources stay **quests and anomaly zones**, and the Analyzer's 1/50 is the fallback for when a particular species is needed right now.

**Resonance Analyzer** (`:RESONANCEANALYZER`, key item, added to `PBS/items.txt`) does two things: raises the chance and **reveals the Hidden Ability during battle, before catching**. Modelled on the Shiny Charm — owning it is enough.

The name ties into [Q-002], where the source of the "anomalous pulse" turns out to be a Bronzor whose psychic waves resonate through the mine's metalwork. The device picks up that same resonance, so the item and the first quest explain each other.

**Still to do by hand:**

> * **Hand the item out** via an event — naturally a reward for the Professor's Act 1 quest, which also introduces the player to the anomaly theme.  
> * **Remove Ability Patch from shops.** It currently has an ordinary price of 10000. Sold freely it devalues the chance, the anomaly zones and the quest rewards all at once. Ability Capsule (swaps between 0 and 1 only) is safe to sell — that is the Act 1–2 item.  
> * **Fill in `ANOMALY_MAPS`** once anomaly maps exist.

## **🕵️ 10\. Government Suspicion Meter**

The protagonist is an undercover Syndicate operative. The meter tracks how interested the Government has become.

### **Principle: an axis of choice, not a penalty**

The standard failure of "wanted" meters is that they only punish — so the player starts avoiding exactly the content the meter exists for. Investigate anomalies → suspicion rises → stop investigating anomalies. The mechanic strangles itself.

So the meter is **two-sided**: Government suspicion rises together with Syndicate trust. This follows from §3 of the concept document — the Syndicate is cold and threatens the player for hesitating, so an unsuspected protagonist is one who is doing a poor job for their employers.

```
LOW suspicion                      HIGH suspicion
official access, cheap services,   surveillance, patrols, government
quiet life                         doors closed
BUT: Syndicate displeased,         BUT: Syndicate pleased, black
threats, supplies cut              market, access to their zones
```

There is no correct slider position — there are two playstyles, each granting and denying something.

### **Gameplay consequences**

All of this is event pages conditioned on "variable >= N". No story writing required.

> * **Patrols and searches.** Agents appear along routes; above a threshold they block transit points and confiscate anomalous samples.  
> * **Battles.** Agents are the hardest non-Gym trainers, with high `SkillLevel`. Higher suspicion means more encounters but better spoils. This is where the interest in hard battles (§8) plugs in.  
> * **Access flips.** Government facilities close, Syndicate zones open. Since access is the primary reward currency (§9), this is the strongest lever.  
> * **Anomaly sites get cordoned off.** Places where the player left traces gain guards and barriers.  
> * **Locals clam up.** Above a threshold NPCs want no trouble and stop sharing rumours — striking directly at the investigation loop.

### **What moves it**

> * **Raises:** being seen at anomaly sites, taking samples, breaking into facilities, getting caught by a patrol, siding with the Syndicate during events.  
> * **Lowers:** handing data to the Government (at the cost of Syndicate trust), completing their errands, paying a fixer, and **winning a Badge** — badges act as public legitimacy, which also explains why an undercover operative bothers with the League beyond the prize.

### **Link to the main story — UNDECIDED**

Three options, from tight coupling to full separation:

> * **A. The meter determines the act checkpoint outcome.** Maximum significance, but the main story's outcome starts depending on a system.  
> * **B. The meter gates access to certain scenes** without changing outcomes.  
> * **C. The meter affects gameplay only.** Story branches come from explicit choices in events; the meter remains systemic pressure.

**Argument for B or C:** the main story is written by a partner, while the meter is driven by a system owned by the other person. Tight coupling creates a dependency between two people — any rebalancing of the meter starts disturbing someone else's work. The decoupled option is safer for collaboration.

### **Implementation**

One variable and 3–4 thresholds. No new systems. The one thing that needs care is **legibility**: the player must understand where they sit on the meter and what moves it, otherwise consequences read as arbitrary. The journal (`idea.md` §2) already provides the surface for this.

## **🐉 11\. Raids, Small World Events, Rare Rewards**

### **Raids — the machinery already exists, nothing to write**

Deluxe Battle Kit ships a complete raid-boss framework. Verified in the plugin's code:

> * **`Wild Boss Attributes`** — `hp_boost` and `hp_level` (inflated HP), `immunities` and `hasBossImmunity?` (status immunity), `isRaidBoss?`.
> * **`RaidShield`** — shields, as in Max Raid Battles.
> * **`battle_rules["raidStyleCapture"]`** and `raidCaptureMode` — Sword/Shield-style capture after the win.
> * **`pbRegisterPartner(tr_type, tr_name)`** (Essentials core) — an allied trainer in a double battle.

So a "raid" assembles from existing parts: **the player and a partner against a boss with inflated HP, immunities and shields**, with a capture phase at the end. Not a line of custom battle logic.

**The Rival as the connecting figure is a good fit.** He is already described as a confident fighter with deep tactical understanding (`characters.md` §1), so recurring raid participation develops him rather than contradicting him — and gives him a repeatable function beyond duels.

Raids are also the natural source of Hidden Ability Pokémon, exactly as in the official games (see §9).

### **Small random world events — low priority**

> * Purely visual vignettes: two trainers battling in the distance, a Pokémon darting across the path, someone rummaging in the bushes and running off.
> * **More valuable than it looks:** they fill the gaps between story beats — precisely the hole created by the main story being written by a partner while the world is not.
> * Implementation: a Parallel Process event plus a random value, or a registry of situations modelled on `HandlerHash`.
> * **Hard constraint:** a visual vignette must never take control away for more than a couple of seconds, or the "living world" becomes an obstacle.

### **A pseudo-legendary as a hidden quest reward**

The hidden quest — yes. The randomness — with caveats.

> * **Pseudo-legendaries are weak in Act 1.** Beldum knows essentially only Take Down until level 20; Larvitar evolves at 30. Under a hard per-act level cap such a Pokémon is a burden rather than a reward. Not an argument against — it is a long-term investment — but the player must understand what they are taking.
> * **A random TYPE sits badly in a game where team composition decides fights.** Dratini, Beldum and Larvitar are three different roles. On a pure roll the player cannot plan, and the reward becomes a lottery.
> * **Better: roll 2–3 candidates, let the player pick one.** Replayability survives — different runs offer different sets — while the choice stays with the player.
> * **Better still:** which one appears depends on what the player did — faction, biome explored, the outcome of an earlier quest. Then randomness becomes consequence and obeys the "every path leaves a trace" rule.
