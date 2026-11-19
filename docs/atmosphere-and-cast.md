# NIGHTSPLIT: a reason to come back

Creative proposal, 2026-11-18. This extends the director brief; character names,
chapter beats and music are draft material, not previously established canon.
The music controller is implemented separately. The cast and scenes below are
not yet implemented in Studio. Unrevealed history and payoffs stay out of this repo.

## The promise

**We bring everyone home.**

A five-person recovery crew works beyond the last safe neighborhoods. During the
day they restore routes, buy equipment and pull records out of abandoned relay
stations. At Breaknight, those same routes become hunting grounds. The crew can
return with a priceless blackbox and still consider the operation a failure if
someone's Echo Tag is missing.

The central dramatic question: **who gets included in “everyone”?** A friend,
a rival, a stranger behind the next gate, someone whose rescue costs the shelter
its remaining power? The answer must come through actions players participate in.

The avatar squad remains the protagonist. NPCs have their own work, relationships
and mistakes; they do not complete the exciting objectives while players watch.

## Three people first

Introduce only Mara and Ivo in Relay Nine's first story mission. Introduce Sera
in a later operation. Build affection before asking for grief. These are recurring
supporting characters, not replacements for player classes.

### Mara Venn, recovery lead

- Silhouette: short mustard rescue jacket, compact cutting tool, a white repair
  stitch running down one sleeve. Practical, unmistakable from a distance.
- Public aim: make the shelter's recovery crew dependable enough that people stop
  leaving names off rescue requests because they assume nobody will come.
- Appealing behavior: remembers a recruit's preferred nickname; repairs their
  equipment before her own; insists that even terrible cooking deserves a table.
- Flaw: promises more rescues than the crew can sustain, then takes on the danger
  herself instead of admitting she needs help. Her bravery can become control.
- Signature: leaves a small lamp on at a return point. “So nobody has to guess.”
- First playable proof: marks a safe return route before asking for the blackbox.
  In a later authored mission, she needs the team to recover her Echo.
- Sample line: “The record can wait. Your fifth can't.”

### Ivo Renn, relay mechanic

- Silhouette: slate overalls, orange cable spool, mismatched glove. A rolling
  toolcase that he treats like a badly behaved pet, never a comedy mascot.
- Public aim: restore reliable transport so rescue stops depending on heroic luck.
- Appealing behavior: dry jokes about his own repairs; gives machines absurdly
  polite names; celebrates another player's clever shortcut without claiming it.
- Flaw: treats an uncertain measurement as a personal failure. He can hide an
  anomaly while trying to fix it, making an honest mistake harder to repair.
- Signature: taps a short rhythm on a panel before energizing it.
- First playable proof: a bypass he built saves the crew time, but its limited
  capacity means someone must choose which system gets power.
- Sample exchange: Ivo: “That was the quiet gate.” Mara: “Build a quieter one.”
  Ivo: “That's called a wall.”

### Sera Holt, route scout from another shelter

- Silhouette: narrow blue scarf, folded route boards, worn reflective leg bands.
- Public aim: keep the route between her shelter and the recovery network open.
- Appealing behavior: shares route information even when the crew is a competitor;
  notices when a teammate is lagging and slows without making a speech about it.
- Flaw: calculates acceptable losses quickly, then mistakes speed for certainty.
- Signature: a familiar waypoint becomes a challenge, “Beat my time, then show me
  the route.” Rivalry grows from gameplay competence, not constant insults.
- First playable proof: supplies an alternate extraction route with a real cost.
- Sample line: “I know how to get three people out. Help me make it five.”

Mara and Sera both rescue people, but disagree about promises and triage. Ivo's
engineering choices make their disagreement concrete. Give each pair quiet scenes,
shared successes and changed behavior after conflict. Nobody exists only to die,
betray the team, deliver exposition or admire the player.

## First operation: The Last Lamp

Target: one compact mission using Relay Nine's existing spaces. This is an authored
Operation treatment; the present repeatable slice does not yet have this progression.

1. **Someone expects you back.** At the safe edge, Mara lights the return marker.
   Ivo's first caption describes the job in one sentence: restore the relay, recover
   the record, return together. Players get control immediately.
2. **Competence makes friends.** Fix the relay under pressure. Ivo reacts to the
   actual successful repair, not a timer pretending the team succeeded. A short
   warmer musical answer follows the unresolved opening theme.
3. **A gate is a decision.** The existing charge purchase opens the intake and
   exposes the team to danger. The cast acknowledges that decision. Do not add a
   compulsory vote menu or gate the mission on reading text.
4. **The warning has a witness.** The optional 08/09 plate, welded evacuation lift
   and WE DID inscription can all be found along usable paths. They remain useful
   environmental observations, not three mandatory keys.
5. **Make the mechanic matter.** During a real Echo recovery, Mara offers a short
   practical direction. Never manufacture a player death to force this scene.
   A solo run receives an equivalent route-risk beat, not an impossible team task.
6. **A small answer; a larger question.** The recovered record contains an ordinary
   evacuation roll call. One response comes from the sealed lift after the order
   to close it. End on the implication, not an explanation. The team reaches a
   tangible success even if nobody inspects an optional clue.
7. **Home has a ritual.** The return marker stays lit until the squad is accounted
   for. One brief exchange acknowledges what actually happened: clean extraction,
   successful rescue or a missing teammate. No celebratory line over a failed rescue.

The recording is presented as short caption fragments and a visual waveform, in
keeping with the no-voice direction. The mystery never relies on hearing a hidden
frequency, recognizing a melody or reading Morse code.

## How the larger story earns its scale

- Each operation answers its immediate question. Do not postpone every answer
  to a hypothetical final update.
- Use three evidence types before a major reinterpretation: a physical detail,
  an independent account and a consequence players can test.
- Escalate from a station, to a connected route, to a dispute about the network.
  A bigger enemy is not automatically a more meaningful chapter.
- A powerful new ability needs a readable limitation and a cooperative use.
  Its best scene should let a player protect or enable someone else.
- Keep repeatable combat canon-compatible without claiming every defeat/reset is
  a literal time loop. Operation chapters have authored chronology; ordinary run
  resets are game structure unless a specific story establishes otherwise.
- Earn emotional peaks through kindness, rivalry, repair and sacrifice. Avoid
  arbitrary deaths, fake deaths and “everyone was secretly evil” shortcuts.
- Use the cited shows as the director's quality bar for attachment, escalation and
  connected payoffs. All characters, histories, symbols, music and mechanics here
  must have their own identity.

## Musical identity: Leave a Light

Original composition sketch: a call that hangs unresolved, answered by another
instrument. The emotional progression is solitude -> pressure -> determination
-> relief. It should make rescuing someone feel worth the risk.

| State | Arrangement | Runtime trigger in this pass |
| --- | --- | --- |
| Day | Soft mallet phrase, spacious pad, low pulse | RunState = Day |
| Breaknight | Same theme, bass ostinato, restrained drums, tighter rhythm | RunState = Breaknight |
| Rescue | Theme raised into a stronger register; rhythm keeps moving | Local player carries an Echo during Day/Breaknight |
| Complete | Warm harmonic answer, lighter percussion | RunState = Complete |
| Reset or unknown | Silence for breathing room | Any other RunState |

Combat warnings, footsteps and team communication must stay readable. Score starts
at a conservative volume. Turning music off must never hide actionable information.
The shipped controller crossfades complete arrangements; it does not claim to be
beat-synchronized stem mixing. A future production score should extend these short
sketches, introduce rests/variation, and be mixed against actual combat on phones.

Deliverable `tools/compose_score.py` creates four 24-second loops and a 90-second
crossfaded listening preview. The melody and synthesized sounds are newly authored
for this sketch. No samples or soundtrack excerpts are used. This is a synthesized
composition demo, not a finished orchestral recording or an in-game audio upload.

## Next vertical slice

1. Audition the score sketch and arrange/replace it as needed.
2. Upload accepted loops to the experience owner and configure their actual IDs.
3. Implement one Mara/Ivo mission with event-based, short, interruptible captions.
4. Playtest whether players recall a person and an unanswered question after one run.
5. Expand only after the first mission is fun and readable without the story.

No new NPCs, boss, persistent chapter progression or voice acting ship in this pass.
