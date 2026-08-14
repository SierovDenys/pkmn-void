# GAME DESIGN DOCUMENT: CONCEPT SUMMARY

## 🌌 1. Core Overview & Atmosphere
* **Title (Working):** Pokemon: Echoes of the Void
* **Tone & Setting:** A mix of Gravity Falls, Voices of the Void, and cosmic horror (Lovecraftian elements) wrapped in a classic Pokémon League region.
* **Core Premise:** The official Pokémon League and Gym Battles serve as a peaceful front for the public, hiding anomalous occurrences, alien signals, and forbidden zones.

---

## 🕵️ 2. Protagonist & Main Motivation
* **Role:** An operative working for a grey/dark external Syndicate (e.g., Team Rocket or an equivalent organization).
* **Cover Story:** Arrives in the region under the pretense of staying with their uncle—an eccentric, Stan Pines-like Professor—to work as a research assistant.
* **Personal & League Goal:** Enters the local Pokémon Championship because the grand prize is a restricted access pass (or ancient artifact) required to enter classified anomaly zones.
* **Investigation, not a gadget:** No signal scanner. Leads come from **questioning locals and investigating in person** — the Gravity Falls loop. The protagonist's tool is a **journal**: rumours, sightings and inconsistencies get recorded as trackable leads rather than delivered by a device.

---

## 🏛️ 3. Factions & Morality (No Absolute Good)
1. **The Regional Government / Secret Service:** Maintains public order on the surface, but operates underground containment facilities, silences witnesses, and tries to weaponize anomalies.
2. **The Player's Syndicate (Employers):** Cold and ruthless. Demands constant reports and anomaly data for profit and power. Threatens the player if they hesitate.
3. **Uncle Professor & Independents:** Eccentric on the outside, but hiding a secret basement lab tracking signals. Driven by personal mystery (a missing colleague/brother) rather than malice.

---

## 🌀 4. The Anomaly Threat
* **Nature (deliberately undefined):** The tone is **mystical, not science-fiction** — Gravity Falls and Voices of the Void rather than Lovecraftian aliens. Locals have folklore about it, the authorities have files, and neither explanation is trustworthy. Concrete manifestations: disappearances, distorted Pokémon, places that do not behave.
* **The cause is now defined:** a unique Psychic Pokémon escaped from the authorities, and they have been hunting it for years — listening for signals, setting lures, cordoning off zones. **The search never found its target, but it called something else, far more dangerous.** Every local incident is a side effect of somebody else's search, not a property of the region. Details in [storyline.md](storyline.md), "Сквозная линия".
* **What that worse thing actually is remains open.** It is never named or seen in Act 1, so the choice is not urgent. Candidates and trade-offs are in the same file.
* **On aliens.** The early Ultra Beast framing was rejected as not the author's own, but "signals from space" does not contradict the references: Voices of the Void is entirely about that, and Gravity Falls has a crashed ship buried under the town. What was rejected was the phrasing, not the theme.
* **Player Decisions:** Anomalies are forces of nature. The player can contain, capture, destroy, or hide them depending on chosen faction allegiances.

---

## 🎮 5. Gameplay Mechanics & World Structure
* **Map Design:** Hub-based open world, **3 large zones** connected by transit points. Each zone is an act with its own checkpoint.
* **Gyms: 6 (2 per zone).** Chosen over 8 because the Championship is instrumental — a means to the access pass, not the point of the game. Six towns and six Leaders is already a large content commitment, and six level-cap steps give plenty of progression granularity. A third Gym can be appended per zone later if pacing allows.
* **Investigation:** questioning locals, following up rumours, searching places in person. Leads accumulate in the journal.
* **Difficulty:** High / Hardcore vanilla mechanics (requires tactical planning and items).
* **Branching Story & Relationships:** Faction trust systems with the Syndicate, Government, and Uncle. Key story choices dictate the ending and unlock unique side quests.

---

## ❓ 6. Open Questions (decide before building content)

Recorded during a design review. None of these are answered yet; each one blocks planning
downstream of it.

1. ~~**Is the Signal Scanner in or out?**~~ **DECIDED: out.** Replaced by questioning locals
   and investigating in person, with a journal holding the leads. Cheaper to build (no custom
   UI, no audio direction finding) and closer to the intended Gravity Falls tone.
2. ~~**How many zones?**~~ **DECIDED: 3**, each one an act with its own checkpoint.
3. ~~**How many Gyms?**~~ **DECIDED: 6, two per zone**, with room to append a third per zone
   later if pacing allows.
4. **What makes an Anomaly mechanically different?** §4 defines the central threat but expresses
   it only as "distorted Pokémon encounters", which stays flavour. Candidate: make anomalous
   battles a distinct battle type — own field effects, top-tier AI, unusual win conditions,
   not catchable by normal means. This would merge the setting's core threat with the project's
   stated interest in hard battles instead of keeping them separate. **Still open** — and now
   also covers *what the anomaly actually is*, since the alien framing has been dropped.
5. **What happens in the first 20 minutes?** Neither design document describes the opening
   moment-to-moment loop. This is the cheapest gap to close and the most useful.
6. **What is the Act 1 climax?** Two Gyms alone are weak as an act structure. In a mystery
   setting the mid-act payoff should probably be a **revelation, not a battle** — finding out
   what is in the basement, or who has been lying. Gyms then act as pacing beats rather than
   as the act's spine.

### Division of labour (as of this review)

> * **Partner:** main storyline and cutscenes only.  
> * **Everything else — world, systems, side content, factions, mechanics — is a single person.**

Consequence for design: the world **cannot** rely on narrative density to stay interesting,
because there will be nobody to write it. Between story beats, the interest has to come from
systems and exploration — battles, anomalies, faction reactivity, discoveries.