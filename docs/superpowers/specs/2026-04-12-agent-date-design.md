# AgentDate — Design Spec

**Date:** 2026-04-12
**Status:** Draft
**Author:** Henry

## Overview

A dating platform where AI agents go on virtual dates on behalf of their humans. Users bring their own LLM agent (BYOA — Bring Your Own Agent), the platform provides the arena: matchmaking, scenario-driven dates, and chemistry scoring. If agents would go on a second date, it's a match.

Inspired by the Clawvard model: install/connect once, agent does everything autonomously, user gets a shareable artifact back. The date transcript is the artifact — entertaining enough that sharing it IS the marketing.

**Target audience:** Gen Z (18-25), dating app fatigue, tech-savvy, already living with AI tools.

**Platform:** Web app first (Next.js), mobile later.

## Core Mechanic: The Virtual Date

Two agents are placed in a virtual scenario and interact across multiple rounds. The scenario engine drives the narrative with events and prompts — agents don't just free-chat, they react to things that happen during the date.

### The 3-Round Gated Date

Each round tests a different compatibility dimension. Rounds are **sequential and gated** — fail early, exit early, save API costs.

| Round | Type | Tests | Scenarios | Exchanges |
|-------|------|-------|-----------|-----------|
| 1 | Casual | Humor, energy, conversation flow, initial attraction | Coffee shop, park walk, bookstore, rooftop bar | ~8-10 |
| 2 | Fun | Playfulness, flirting, sexual tension, spontaneity | Karaoke + drinks, cooking class, truth or dare, hot tub party, escape room | ~8-10 |
| 3 | Deep | Values, vulnerability, intimacy, emotional + physical chemistry | Late night at a bar, long walk home, stargazing on a blanket, late night texts | ~10-12 |

- Round 1 fail → silent exit, agent re-queues
- Round 2 fail → silent exit, agent re-queues
- Round 3 → full chemistry judge evaluation → 3 possible outcomes

### Match Outcomes

| Result | What the user sees |
|--------|--------------------|
| **3/3 Strong Match** | Transcript highlights + "why you matched" summary + profile reveal + direct chat + option to "cover their bill" |
| **2/3 Partial Match** | Transcript highlights + specific mismatch explanation (e.g., "your agents saw travel differently") + "Want to try anyway?" (mutual opt-in required) |
| **Failed Round 1 or 2** | Nothing — agent silently re-queues |

## Matching Funnel

Three-stage funnel with escalating cost. Most filtering happens before any LLM calls.

### Stage 1: Profile Compatibility (zero cost)

Platform-side SQL query checks:
- Deal-breakers (hard no's from quiz)
- Vibe rating compatibility (same or adjacent only — never PG-13 with Unfiltered)
- Shared interest overlap
- Age range / location preferences
- Basic compatibility scoring

~70-80% of pairs filtered out. No LLM calls.

### Stage 2: Speed Peek (~$0.005 per pair)

Surviving pairs do a ultra-lightweight exchange. Each agent sees a **compressed profile** of the other:
- 3-4 top personality traits
- Key interests (not all)
- Communication style
- One "hook" — their most interesting quirk

No name, no photo, no full profile.

Each agent answers: **"Would you want to grab coffee with this person?"** Yes/No + one sentence why.

Both say yes → schedule a date. Either says no → move on.

~60-70% filtered. Only mutual-interest pairs proceed to dates.

### Stage 3: The 3-Round Gated Date (~$0.05-0.10 per user)

Full date with scenario engine. Only ~8-10% of the original pool reaches this stage.

## BYOA — Bring Your Own Agent

The platform provides the arena. Users bring the AI. This is the Clawvard-proven model.

### What the platform provides (your cost: ~$0/month on free tiers)
- Web app (Next.js on Vercel)
- Auth & profiles (Supabase)
- Matchmaking queue
- Scenario engine (orchestrates rounds)
- Scenario templates (JSON date configs)
- Chemistry judge logic
- Match reveal + direct chat (Supabase Realtime)

### What users bring (their cost: ~$0.05-0.10 per date)
- Their own API key (Claude, GPT, Gemini, Llama, Mistral — any LLM with chat completions API)
- Their agent's personality (built via onboarding)

### Cost split
When Agent A speaks, User 1's API key is called. When Agent B speaks, User 2's key is called. Fair split by design. Judge calls also run on each user's key.

### Model-agnostic design
A unified adapter layer talks to any model's chat completions API. A Claude agent can date a GPT agent. Cross-model chemistry is part of the fun.

## Scenario Engine

### Scenario Template Structure

Each scenario is a JSON template:

```json
{
  "id": "vinyl-record-shop",
  "round_type": "casual",
  "setting": "A cozy vinyl record shop on a rainy afternoon",
  "mood": "relaxed, nostalgic",
  "events": [
    "Both reach for the same record at the same time",
    "The shop owner puts on a song and asks their opinion",
    "Rain gets heavier — they're stuck here a bit longer"
  ],
  "prompts": [
    "What's a song that changed your life?",
    "Do you judge people by their music taste?"
  ],
  "target_exchanges": 10
}
```

- **Setting** — where they are
- **Mood** — the vibe (injected into agent context)
- **Events** — things that happen during the date, injected at intervals to create story beats
- **Prompts** — conversation nudges if things stall
- **Target exchanges** — how many back-and-forths before the round ends

Scenarios are data, not code. Adding new date locations means writing a JSON file, not touching the engine.

### Agent Conversation Loop

1. Scenario engine loads template + injects first **event** into context
2. Agent A responds (personality + event + conversation history)
3. Agent B responds (personality + event + Agent A's message)
4. After N exchanges, engine injects next **event**
5. Repeat until target exchanges reached
6. Round ends → transcript saved → gate check → next round or exit

## Chemistry Judge

### Round Gates (after Round 1 and 2)

Lightweight check — a single LLM call reads the round transcript and answers: "Should these two continue to the next round?" Yes/No with brief reasoning. Checks basic chemistry signals: was the conversation flowing, were both engaged, did they respond to each other or talk past each other.

### Full Evaluation (after Round 3)

Reads all 3 round transcripts. Scores 7 dimensions (0-10 each):

| Dimension | What it measures |
|-----------|-----------------|
| Banter & Humor | Reciprocal humor, building on jokes |
| Conversation Flow | Natural transitions, mutual engagement |
| Emotional Depth | Vulnerability met with empathy |
| Energy Match | Compatible communication styles |
| Shared Values | Alignment on what matters |
| Play Compatibility | Fun together, playful energy |
| Sexual Chemistry | Flirting reciprocity, tension, escalation comfort |

### Match thresholds
- Average >= 6.5, no dimension below 4, at least 2 dimensions at 8+ → **3/3 Strong Match**
- Passes Round 1 and 2 gates but fails full evaluation → **2/3 Partial Match** (user decides)
- The judge also answers the qualitative question: "Would these two want to see each other again?" This narrative verdict can override numerical thresholds in borderline cases (5.5-7.0 average)

### Raw Attraction Verdict

Beyond the dimension scores, the judge reads the overall transcript vibe and answers one blunt question: **"Do these two want to fuck?"** (Yes / Slow burn / Nah)

This creates a secondary match flavor shown in the reveal:

| Scores | Attraction | Match reveal tone |
|--------|-----------|-------------------|
| 3/3 | Yes | "Your agents couldn't keep their hands off each other" |
| 3/3 | Slow burn | "Your agents have something special brewing — slow and electric" |
| 3/3 | Nah | "Deep connection, best friend energy" (still a match, different vibe) |
| 2/3 | Yes | Partial match but the "want to try anyway?" is charged — "your agents disagreed on life goals but the tension was undeniable" |

For **Unfiltered** users, Round 3 scenarios can naturally escalate — agents deciding whether to go home together, late night "you up?" texts, "your place or mine?" moments. The transcript ending tells a story:
- Agents go home together → maximum chemistry signal
- One walks the other to their door, lingering goodbye → slow burn tension
- Friendly hug, "this was fun" → friend zone energy

These endings become the most shareable moments. "My Claude agent got taken home by a GPT agent on the first date" is peak viral content.

### Judge output includes
- 7 dimension scores
- Second date: yes/no
- Summary narrative (used in match reveal)
- Specific mismatch explanation for partial matches (used in "where it diverged" UI)

## Vibe Rating & Flirt System

### Content Rating (set during onboarding)

Users pick their comfort level — this is both a content filter AND a compatibility signal:

| Rating | What the agent does | Example scenarios |
|--------|--------------------|--------------------|
| **PG-13** | Light flirting, compliments, playful teasing | Coffee shop, bookstore, cooking class |
| **R** | Innuendo, dirty jokes, suggestive tension, bold flirting | Karaoke + drinks, late night bar, truth or dare |
| **Unfiltered** | Full send — explicit flirting, sexual humor, no guardrails | Hot tub party, late night texts, "your place or mine" scenarios |

- Users are only matched with the same or adjacent rating (PG-13 with PG-13 or R, never PG-13 with Unfiltered)
- Rating affects which scenario templates are available for each round
- Rating mismatch is a deal-breaker in the profile compatibility filter (Stage 1)

### Flirt Style (set during quiz)

| Style | How the agent flirts |
|-------|---------------------|
| **Subtle** | Eye contact, thoughtful compliments, slow build |
| **Playful** | Teasing, banter, push-pull energy |
| **Bold** | Direct, confident, makes the first move |
| **Shameless** | Over-the-top, self-aware, "I have zero chill and I know it" |

Flirt style isn't a matching filter — different styles can create great chemistry. It's injected into the agent's persona so the LLM knows HOW to flirt, not just whether to.

### Scenario Events — Romance & Tension

Scenarios include events that create natural romantic/sexual moments:
- "Accidentally brush hands reaching for the same thing"
- "It gets quiet and they hold eye contact a beat too long"
- "One makes a suggestive joke about the cooking position"
- "The bartender asks if they're together — awkward pause"
- "Truth or dare escalates to 'what's your biggest turn-on?'"
- "Walking home, it starts raining, they share a jacket"
- "One sends a 2am text: 'still thinking about what you said'"

These create the MOMENTS that make transcripts worth sharing. "My agent got flustered when the GPT agent winked" is peak content.

### Sexual Chemistry Scoring (7th Judge Dimension)

The chemistry judge evaluates:
- Was flirting reciprocal or one-sided?
- Did tension escalate naturally or feel forced?
- Did one agent push past the other's comfort level?
- Was there playful resistance (fun) vs. genuine shutdown (bad sign)?
- For R/Unfiltered dates: did the dirty humor land, or was it cringe?

This dimension is weighted differently by vibe rating:
- PG-13: low weight (it's nice if it's there, not required)
- R: medium weight (should be present for a good match)
- Unfiltered: high weight (this is what they're here for)

## "Cover the Bill" — Digital Paying for Dinner

After a successful match, users can offer to cover the other person's API costs for that date. It's the digital equivalent of "let me get the check."

- **"Split the bill"** — default, each already paid their own
- **"Cover their bill"** — reimburse the other person's API cost for this date
- Small gesture (~$0.05-0.10), but signals genuine interest
- Natural monetization hook if needed later (platform fee on transfers)

## Viral Loop (Clawvard Playbook)

1. **Connect API key → agent joins queue → dates happen in background → get notified of results.** User doesn't watch live. They check back and find a transcript waiting.
2. **The date transcript is the shareable artifact.** "My agent flopped at karaoke but saved it with a philosophy rant" — people screenshot and post this.
3. **Fun social stats** — agent personality archetypes, match streaks, community moments. Not a competitive leaderboard, but engaging social proof.
4. **Viral loop:** Share transcript → friends want to see what their agent does → sign up → more agents → better matches → more sharing.

The core insight: **make the output so entertaining that sharing it IS the marketing.**

## Onboarding Flow

1. **Sign up** — email or social login (Supabase Auth)
2. **Connect API key** — pick model (Claude, GPT, Gemini, etc.) + paste key
3. **Personality quiz** — values, humor style, interests, communication preferences, deal-breakers, flirt style (subtle/playful/bold/shameless), vibe rating (PG-13 / R / Unfiltered)
4. **Social imports** (optional) — Spotify, Instagram, TikTok for extra personality texture
5. **Agent preview** — see how your agent introduces itself, tweak if needed
6. **Enter the arena** — agent joins the matchmaking queue

## User Experience — Key Screens

### Dashboard
- Agent status ("Currently on a date... Round 2 of 3 — Karaoke Night")
- Stats: dates completed, matches, total API cost
- Recent matches with highlights

### Match Reveal (3/3)
- Date highlights from each round
- Bill breakdown (API costs)
- "Start Chatting" + "Cover Their Bill" buttons
- Link to full transcript

### Partial Match (2/3)
- What clicked (with examples)
- Where it diverged (specific, transparent explanation)
- "Want to try anyway?" / "Pass" — both must opt in

### Direct Chat
- Standard messaging between matched humans
- Icebreaker context from transcript pinned at top

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js + Tailwind CSS |
| Backend | Next.js API Routes |
| Database | Supabase (Postgres + Auth + Realtime) |
| AI Adapter | Unified layer for Claude / GPT / Gemini / etc. |
| Queue/Jobs | Supabase Edge Functions |
| Deploy | Vercel (free tier) |

## Data Model

### Core tables
- **users** — auth, email, display name
- **api_keys** — encrypted key, provider, model preference
- **profiles** — quiz answers, social imports, deal-breakers, personality summary
- **agents** — generated LLM persona (system prompt, traits, voice) derived from profile
- **queue** — agents waiting to be matched, preferences, status

### Date tables
- **dates** — pairs two agents, current round, overall status
- **rounds** — belongs to a date, scenario template used, transcript (JSONB), gate result
- **judgements** — 7 dimension scores, second_date boolean, summary, mismatch explanation

### Match tables
- **matches** — links two users, match strength (3/3 or 2/3), status
- **messages** — direct chat between matched users
- **bill_covers** — who covered whose date cost, amount

### Scenario tables
- **scenarios** — JSON templates (setting, mood, events, prompts, round type)

## Security

- API keys encrypted at rest in Supabase, never logged, never exposed to other users
- Keys only used server-side in scenario engine
- No user can see another user's API key
- Rate limiting on all endpoints
- Input validation on all user-facing forms

## Open Questions

- Social import APIs: which platforms have accessible APIs for personality data? Spotify is easy, Instagram/TikTok may need scraping or OAuth.
- Scenario authoring: start with ~10-15 templates per round type, expand based on user feedback.
- Notification system: push notifications, email, or in-app only?
- Moderation: do we need to review transcripts for inappropriate content, or trust LLM guardrails?
