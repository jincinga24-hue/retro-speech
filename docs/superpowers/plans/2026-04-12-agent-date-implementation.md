# AgentDate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a web platform where AI agents go on scenario-driven virtual dates on behalf of their humans, with a 3-stage matching funnel and gated date rounds.

**Architecture:** Next.js app with Supabase backend (Postgres + Auth + Realtime). Users bring their own LLM API keys. A unified adapter calls Claude/GPT/Gemini/etc. The scenario engine orchestrates multi-round dates as background jobs via Supabase Edge Functions. Chemistry judge evaluates transcripts and decides matches.

**Tech Stack:** Next.js 14 (App Router), Tailwind CSS, Supabase (Postgres, Auth, Realtime, Edge Functions), TypeScript

**Spec:** `docs/superpowers/specs/2026-04-12-agent-date-design.md`

---

## File Structure

```
agent-date/
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── next.config.ts
├── .env.local                          # Supabase URL + anon key
├── supabase/
│   └── migrations/
│       ├── 001_core_tables.sql         # users profiles, api_keys, agents, queue
│       ├── 002_date_tables.sql         # dates, rounds, judgements
│       ├── 003_match_tables.sql        # matches, messages, bill_covers
│       └── 004_scenario_seed.sql       # seed scenario templates
├── src/
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts               # Browser Supabase client
│   │   │   ├── server.ts               # Server Supabase client
│   │   │   └── types.ts                # Generated DB types
│   │   ├── llm/
│   │   │   ├── adapter.ts              # Unified LLM adapter interface
│   │   │   ├── claude.ts               # Claude provider
│   │   │   ├── openai.ts               # OpenAI provider
│   │   │   └── gemini.ts               # Gemini provider
│   │   ├── engine/
│   │   │   ├── scenario.ts             # Scenario engine — runs a single round
│   │   │   ├── date-runner.ts          # Orchestrates 3 gated rounds
│   │   │   ├── gate-check.ts           # Lightweight round gate evaluation
│   │   │   └── prompts.ts              # All system prompts (persona, scenario, judge)
│   │   ├── judge/
│   │   │   ├── evaluate.ts             # Full 7-dimension judge + attraction verdict
│   │   │   └── gate.ts                 # Round gate pass/fail check
│   │   ├── matching/
│   │   │   ├── profile-filter.ts       # Stage 1: SQL-based compatibility
│   │   │   ├── speed-peek.ts           # Stage 2: Quick agent exchange
│   │   │   └── queue.ts                # Queue management
│   │   ├── persona/
│   │   │   └── builder.ts              # Quiz answers → LLM system prompt
│   │   └── crypto.ts                   # API key encryption/decryption
│   ├── app/
│   │   ├── layout.tsx                  # Root layout with auth provider
│   │   ├── page.tsx                    # Landing page
│   │   ├── login/
│   │   │   └── page.tsx                # Login/signup
│   │   ├── onboarding/
│   │   │   ├── api-key/
│   │   │   │   └── page.tsx            # Step 2: Connect API key
│   │   │   ├── quiz/
│   │   │   │   └── page.tsx            # Step 3: Personality quiz
│   │   │   └── preview/
│   │   │       └── page.tsx            # Step 5: Agent preview
│   │   ├── dashboard/
│   │   │   └── page.tsx                # Main dashboard
│   │   ├── matches/
│   │   │   ├── [id]/
│   │   │   │   └── page.tsx            # Match reveal (3/3 or 2/3)
│   │   │   └── page.tsx                # All matches list
│   │   ├── chat/
│   │   │   └── [matchId]/
│   │   │       └── page.tsx            # Direct chat with match
│   │   ├── transcript/
│   │   │   └── [dateId]/
│   │   │       └── page.tsx            # Full date transcript view
│   │   └── api/
│   │       ├── onboarding/
│   │       │   ├── save-key/
│   │       │   │   └── route.ts        # Encrypt + store API key
│   │       │   ├── save-profile/
│   │       │   │   └── route.ts        # Save quiz answers
│   │       │   └── build-agent/
│   │       │       └── route.ts        # Generate persona from profile
│   │       ├── matching/
│   │       │   ├── enter-queue/
│   │       │   │   └── route.ts        # Join matchmaking queue
│   │       │   └── respond-match/
│   │       │       └── route.ts        # Accept/decline partial match
│   │       ├── date/
│   │       │   ├── run/
│   │       │   │   └── route.ts        # Trigger a date (called by matchmaker)
│   │       │   └── cover-bill/
│   │       │       └── route.ts        # Cover match's API cost
│   │       └── chat/
│   │           └── send/
│   │               └── route.ts        # Send chat message
│   └── components/
│       ├── QuizForm.tsx                # Personality quiz component
│       ├── ApiKeyForm.tsx              # API key input + model selector
│       ├── AgentPreview.tsx            # Agent intro preview
│       ├── DashboardCard.tsx           # Agent status card
│       ├── MatchReveal.tsx             # Match reveal card (3/3 and 2/3)
│       ├── TranscriptView.tsx          # Date transcript renderer
│       ├── ChatWindow.tsx              # Real-time chat component
│       └── DateProgress.tsx            # Date round progress indicator
├── scenarios/
│   ├── casual/
│   │   ├── coffee-shop.json
│   │   ├── bookstore.json
│   │   ├── rooftop-bar.json
│   │   └── park-walk.json
│   ├── fun/
│   │   ├── karaoke-drinks.json
│   │   ├── cooking-class.json
│   │   ├── truth-or-dare.json
│   │   ├── escape-room.json
│   │   └── hot-tub-party.json
│   └── deep/
│       ├── late-night-bar.json
│       ├── walk-home.json
│       ├── stargazing.json
│       └── late-night-texts.json
└── tests/
    ├── lib/
    │   ├── llm/
    │   │   └── adapter.test.ts
    │   ├── engine/
    │   │   ├── scenario.test.ts
    │   │   └── date-runner.test.ts
    │   ├── judge/
    │   │   └── evaluate.test.ts
    │   ├── matching/
    │   │   ├── profile-filter.test.ts
    │   │   └── speed-peek.test.ts
    │   ├── persona/
    │   │   └── builder.test.ts
    │   └── crypto.test.ts
    └── e2e/
        └── onboarding.test.ts
```

---

## Phase 1: Project Setup & Database

### Task 1: Scaffold Next.js Project

**Files:**
- Create: `agent-date/package.json`
- Create: `agent-date/tsconfig.json`
- Create: `agent-date/tailwind.config.ts`
- Create: `agent-date/next.config.ts`
- Create: `agent-date/.env.local`
- Create: `agent-date/src/app/layout.tsx`
- Create: `agent-date/src/app/page.tsx`

- [ ] **Step 1: Create project with create-next-app**

```bash
cd ~/Vs\ Code/First\ Project
npx create-next-app@latest agent-date --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm
```

- [ ] **Step 2: Install dependencies**

```bash
cd ~/Vs\ Code/First\ Project/agent-date
npm install @supabase/supabase-js @supabase/ssr
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

- [ ] **Step 3: Add vitest config**

Create `agent-date/vitest.config.ts`:

```typescript
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: [],
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

- [ ] **Step 4: Add test script to package.json**

Add to `scripts` in `package.json`:

```json
"test": "vitest run",
"test:watch": "vitest"
```

- [ ] **Step 5: Create .env.local**

Create `agent-date/.env.local`:

```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
ENCRYPTION_KEY=generate_a_32_byte_hex_key_here
```

- [ ] **Step 6: Verify dev server starts**

```bash
cd ~/Vs\ Code/First\ Project/agent-date
npm run dev
```

Expected: Server starts on localhost:3000

- [ ] **Step 7: Commit**

```bash
git init
git add -A
git commit -m "chore: scaffold Next.js project with Supabase + Tailwind"
```

---

### Task 2: Database Schema — Core Tables

**Files:**
- Create: `agent-date/supabase/migrations/001_core_tables.sql`

- [ ] **Step 1: Write migration for core tables**

Create `agent-date/supabase/migrations/001_core_tables.sql`:

```sql
-- Profiles (extends Supabase auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  age integer,
  location text,
  quiz_answers jsonb not null default '{}',
  interests text[] not null default '{}',
  deal_breakers text[] not null default '{}',
  flirt_style text not null default 'playful' check (flirt_style in ('subtle', 'playful', 'bold', 'shameless')),
  vibe_rating text not null default 'r' check (vibe_rating in ('pg13', 'r', 'unfiltered')),
  personality_summary text,
  social_imports jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- API keys (encrypted)
create table public.api_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null check (provider in ('claude', 'openai', 'gemini', 'mistral', 'other')),
  model text not null,
  encrypted_key text not null,
  created_at timestamptz not null default now(),
  unique(user_id)
);

-- Agent personas (generated from profile)
create table public.agents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  system_prompt text not null,
  traits jsonb not null default '{}',
  voice_description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

-- Matchmaking queue
create table public.queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  agent_id uuid not null references public.agents(id) on delete cascade,
  status text not null default 'waiting' check (status in ('waiting', 'peeking', 'dating', 'paused')),
  entered_at timestamptz not null default now(),
  unique(user_id)
);

-- RLS policies
alter table public.profiles enable row level security;
alter table public.api_keys enable row level security;
alter table public.agents enable row level security;
alter table public.queue enable row level security;

create policy "Users can read own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

create policy "Users can read own api key" on public.api_keys
  for select using (auth.uid() = user_id);
create policy "Users can manage own api key" on public.api_keys
  for all using (auth.uid() = user_id);

create policy "Users can read own agent" on public.agents
  for select using (auth.uid() = user_id);
create policy "Users can manage own agent" on public.agents
  for all using (auth.uid() = user_id);

create policy "Users can manage own queue entry" on public.queue
  for all using (auth.uid() = user_id);
```

- [ ] **Step 2: Apply migration to Supabase**

Run this in the Supabase SQL editor or via CLI:

```bash
supabase db push
```

Expected: Tables created successfully

- [ ] **Step 3: Commit**

```bash
git add supabase/
git commit -m "feat: add core database tables — profiles, api_keys, agents, queue"
```

---

### Task 3: Database Schema — Date & Match Tables

**Files:**
- Create: `agent-date/supabase/migrations/002_date_tables.sql`
- Create: `agent-date/supabase/migrations/003_match_tables.sql`

- [ ] **Step 1: Write date tables migration**

Create `agent-date/supabase/migrations/002_date_tables.sql`:

```sql
-- Scenario templates
create table public.scenarios (
  id text primary key,
  round_type text not null check (round_type in ('casual', 'fun', 'deep')),
  vibe_rating text not null default 'pg13' check (vibe_rating in ('pg13', 'r', 'unfiltered')),
  setting text not null,
  mood text not null,
  events jsonb not null default '[]',
  prompts jsonb not null default '[]',
  target_exchanges integer not null default 10,
  created_at timestamptz not null default now()
);

-- Dates
create table public.dates (
  id uuid primary key default gen_random_uuid(),
  agent_a_id uuid not null references public.agents(id),
  agent_b_id uuid not null references public.agents(id),
  user_a_id uuid not null references public.profiles(id),
  user_b_id uuid not null references public.profiles(id),
  current_round integer not null default 1,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'failed_gate')),
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

-- Rounds
create table public.rounds (
  id uuid primary key default gen_random_uuid(),
  date_id uuid not null references public.dates(id) on delete cascade,
  round_number integer not null check (round_number in (1, 2, 3)),
  scenario_id text not null references public.scenarios(id),
  transcript jsonb not null default '[]',
  gate_result text check (gate_result in ('pass', 'fail')),
  gate_reasoning text,
  token_count_a integer not null default 0,
  token_count_b integer not null default 0,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  unique(date_id, round_number)
);

-- Judgements (after round 3)
create table public.judgements (
  id uuid primary key default gen_random_uuid(),
  date_id uuid not null references public.dates(id) on delete cascade,
  scores jsonb not null default '{}',
  average_score numeric(3,1),
  second_date boolean not null default false,
  attraction_verdict text check (attraction_verdict in ('yes', 'slow_burn', 'nah')),
  summary text not null,
  mismatch_explanation text,
  match_strength text check (match_strength in ('3/3', '2/3')),
  created_at timestamptz not null default now(),
  unique(date_id)
);

-- RLS
alter table public.scenarios enable row level security;
alter table public.dates enable row level security;
alter table public.rounds enable row level security;
alter table public.judgements enable row level security;

create policy "Scenarios are public read" on public.scenarios
  for select using (true);

create policy "Users can read own dates" on public.dates
  for select using (auth.uid() = user_a_id or auth.uid() = user_b_id);

create policy "Users can read own rounds" on public.rounds
  for select using (
    exists (
      select 1 from public.dates d
      where d.id = rounds.date_id
      and (d.user_a_id = auth.uid() or d.user_b_id = auth.uid())
    )
  );

create policy "Users can read own judgements" on public.judgements
  for select using (
    exists (
      select 1 from public.dates d
      where d.id = judgements.date_id
      and (d.user_a_id = auth.uid() or d.user_b_id = auth.uid())
    )
  );
```

- [ ] **Step 2: Write match tables migration**

Create `agent-date/supabase/migrations/003_match_tables.sql`:

```sql
-- Matches
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  date_id uuid not null references public.dates(id),
  user_a_id uuid not null references public.profiles(id),
  user_b_id uuid not null references public.profiles(id),
  strength text not null check (strength in ('3/3', '2/3')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  user_a_response text check (user_a_response in ('accept', 'decline')),
  user_b_response text check (user_b_response in ('accept', 'decline')),
  reveal_tone text,
  created_at timestamptz not null default now()
);

-- Messages (direct chat)
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  content text not null,
  created_at timestamptz not null default now()
);

-- Bill covers
create table public.bill_covers (
  id uuid primary key default gen_random_uuid(),
  date_id uuid not null references public.dates(id),
  payer_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  amount_cents integer not null,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.bill_covers enable row level security;

create policy "Users can read own matches" on public.matches
  for select using (auth.uid() = user_a_id or auth.uid() = user_b_id);
create policy "Users can update own matches" on public.matches
  for update using (auth.uid() = user_a_id or auth.uid() = user_b_id);

create policy "Users can read own chat messages" on public.messages
  for select using (
    exists (
      select 1 from public.matches m
      where m.id = messages.match_id
      and (m.user_a_id = auth.uid() or m.user_b_id = auth.uid())
    )
  );
create policy "Users can send chat messages" on public.messages
  for insert with check (auth.uid() = sender_id);

create policy "Users can read own bill covers" on public.bill_covers
  for select using (auth.uid() = payer_id or auth.uid() = recipient_id);
```

- [ ] **Step 3: Apply migrations**

```bash
supabase db push
```

- [ ] **Step 4: Commit**

```bash
git add supabase/
git commit -m "feat: add date, match, and scenario database tables"
```

---

### Task 4: Supabase Client Setup

**Files:**
- Create: `agent-date/src/lib/supabase/client.ts`
- Create: `agent-date/src/lib/supabase/server.ts`
- Create: `agent-date/src/lib/supabase/types.ts`

- [ ] **Step 1: Create browser client**

Create `agent-date/src/lib/supabase/client.ts`:

```typescript
import { createBrowserClient } from "@supabase/ssr";
import type { Database } from "./types";

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

- [ ] **Step 2: Create server client**

Create `agent-date/src/lib/supabase/server.ts`:

```typescript
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "./types";

export async function createServerSupabase() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        },
      },
    }
  );
}
```

- [ ] **Step 3: Create placeholder types**

Create `agent-date/src/lib/supabase/types.ts`:

```typescript
// TODO: Generate with `supabase gen types typescript` after migrations applied
// For now, manual type definitions matching our schema

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          display_name: string;
          age: number | null;
          location: string | null;
          quiz_answers: QuizAnswers;
          interests: string[];
          deal_breakers: string[];
          flirt_style: FlirtStyle;
          vibe_rating: VibeRating;
          personality_summary: string | null;
          social_imports: Record<string, unknown>;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["profiles"]["Row"], "created_at" | "updated_at">;
        Update: Partial<Database["public"]["Tables"]["profiles"]["Insert"]>;
      };
      api_keys: {
        Row: {
          id: string;
          user_id: string;
          provider: LLMProvider;
          model: string;
          encrypted_key: string;
          created_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["api_keys"]["Row"], "id" | "created_at">;
        Update: Partial<Database["public"]["Tables"]["api_keys"]["Insert"]>;
      };
      agents: {
        Row: {
          id: string;
          user_id: string;
          system_prompt: string;
          traits: Record<string, unknown>;
          voice_description: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["agents"]["Row"], "id" | "created_at" | "updated_at">;
        Update: Partial<Database["public"]["Tables"]["agents"]["Insert"]>;
      };
      queue: {
        Row: {
          id: string;
          user_id: string;
          agent_id: string;
          status: "waiting" | "peeking" | "dating" | "paused";
          entered_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["queue"]["Row"], "id" | "entered_at">;
        Update: Partial<Database["public"]["Tables"]["queue"]["Insert"]>;
      };
      scenarios: {
        Row: {
          id: string;
          round_type: RoundType;
          vibe_rating: VibeRating;
          setting: string;
          mood: string;
          events: string[];
          prompts: string[];
          target_exchanges: number;
          created_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["scenarios"]["Row"], "created_at">;
        Update: Partial<Database["public"]["Tables"]["scenarios"]["Insert"]>;
      };
      dates: {
        Row: {
          id: string;
          agent_a_id: string;
          agent_b_id: string;
          user_a_id: string;
          user_b_id: string;
          current_round: number;
          status: "in_progress" | "completed" | "failed_gate";
          started_at: string;
          finished_at: string | null;
        };
        Insert: Omit<Database["public"]["Tables"]["dates"]["Row"], "id" | "started_at" | "finished_at" | "current_round" | "status">;
        Update: Partial<Database["public"]["Tables"]["dates"]["Row"]>;
      };
      rounds: {
        Row: {
          id: string;
          date_id: string;
          round_number: 1 | 2 | 3;
          scenario_id: string;
          transcript: TranscriptMessage[];
          gate_result: "pass" | "fail" | null;
          gate_reasoning: string | null;
          token_count_a: number;
          token_count_b: number;
          started_at: string;
          finished_at: string | null;
        };
        Insert: Omit<Database["public"]["Tables"]["rounds"]["Row"], "id" | "started_at" | "finished_at" | "gate_result" | "gate_reasoning" | "token_count_a" | "token_count_b">;
        Update: Partial<Database["public"]["Tables"]["rounds"]["Row"]>;
      };
      judgements: {
        Row: {
          id: string;
          date_id: string;
          scores: JudgeScores;
          average_score: number | null;
          second_date: boolean;
          attraction_verdict: "yes" | "slow_burn" | "nah" | null;
          summary: string;
          mismatch_explanation: string | null;
          match_strength: "3/3" | "2/3" | null;
          created_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["judgements"]["Row"], "id" | "created_at">;
        Update: Partial<Database["public"]["Tables"]["judgements"]["Insert"]>;
      };
      matches: {
        Row: {
          id: string;
          date_id: string;
          user_a_id: string;
          user_b_id: string;
          strength: "3/3" | "2/3";
          status: "pending" | "accepted" | "declined";
          user_a_response: "accept" | "decline" | null;
          user_b_response: "accept" | "decline" | null;
          reveal_tone: string | null;
          created_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["matches"]["Row"], "id" | "created_at" | "status" | "user_a_response" | "user_b_response">;
        Update: Partial<Database["public"]["Tables"]["matches"]["Row"]>;
      };
      messages: {
        Row: {
          id: string;
          match_id: string;
          sender_id: string;
          content: string;
          created_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["messages"]["Row"], "id" | "created_at">;
        Update: never;
      };
      bill_covers: {
        Row: {
          id: string;
          date_id: string;
          payer_id: string;
          recipient_id: string;
          amount_cents: number;
          created_at: string;
        };
        Insert: Omit<Database["public"]["Tables"]["bill_covers"]["Row"], "id" | "created_at">;
        Update: never;
      };
    };
  };
};

// Domain types
export type FlirtStyle = "subtle" | "playful" | "bold" | "shameless";
export type VibeRating = "pg13" | "r" | "unfiltered";
export type LLMProvider = "claude" | "openai" | "gemini" | "mistral" | "other";
export type RoundType = "casual" | "fun" | "deep";

export type QuizAnswers = {
  humor_style?: string;
  communication?: string;
  values?: string[];
  interests_detail?: string;
  flirt_approach?: string;
  ideal_date?: string;
  biggest_turnoff?: string;
  love_language?: string;
};

export type TranscriptMessage = {
  role: "agent_a" | "agent_b" | "narrator";
  content: string;
  timestamp: string;
};

export type JudgeScores = {
  banter: number;
  flow: number;
  depth: number;
  energy: number;
  values: number;
  play: number;
  sexual_chemistry: number;
};
```

- [ ] **Step 4: Commit**

```bash
git add src/lib/supabase/
git commit -m "feat: add Supabase client setup and database types"
```

---

## Phase 2: API Key Encryption & LLM Adapter

### Task 5: API Key Encryption

**Files:**
- Create: `agent-date/src/lib/crypto.ts`
- Create: `agent-date/tests/lib/crypto.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/crypto.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import { encryptApiKey, decryptApiKey } from "@/lib/crypto";

describe("crypto", () => {
  const testKey = "sk-ant-api03-test-key-1234567890";

  it("encrypts and decrypts back to original", () => {
    const encrypted = encryptApiKey(testKey);
    expect(encrypted).not.toBe(testKey);
    expect(encrypted).toContain(":");

    const decrypted = decryptApiKey(encrypted);
    expect(decrypted).toBe(testKey);
  });

  it("produces different ciphertext each time (random IV)", () => {
    const encrypted1 = encryptApiKey(testKey);
    const encrypted2 = encryptApiKey(testKey);
    expect(encrypted1).not.toBe(encrypted2);
  });

  it("fails to decrypt with wrong data", () => {
    expect(() => decryptApiKey("invalid:data")).toThrow();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd ~/Vs\ Code/First\ Project/agent-date
npx vitest run tests/lib/crypto.test.ts
```

Expected: FAIL — module not found

- [ ] **Step 3: Implement encryption**

Create `agent-date/src/lib/crypto.ts`:

```typescript
import { createCipheriv, createDecipheriv, randomBytes } from "crypto";

const ALGORITHM = "aes-256-gcm";

function getEncryptionKey(): Buffer {
  const key = process.env.ENCRYPTION_KEY;
  if (!key) throw new Error("ENCRYPTION_KEY not set");
  return Buffer.from(key, "hex");
}

export function encryptApiKey(plaintext: string): string {
  const key = getEncryptionKey();
  const iv = randomBytes(16);
  const cipher = createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(plaintext, "utf8", "hex");
  encrypted += cipher.final("hex");

  const authTag = cipher.getAuthTag().toString("hex");
  return `${iv.toString("hex")}:${authTag}:${encrypted}`;
}

export function decryptApiKey(ciphertext: string): string {
  const key = getEncryptionKey();
  const parts = ciphertext.split(":");
  if (parts.length !== 3) throw new Error("Invalid ciphertext format");

  const [ivHex, authTagHex, encrypted] = parts;
  const iv = Buffer.from(ivHex, "hex");
  const authTag = Buffer.from(authTagHex, "hex");
  const decipher = createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encrypted, "hex", "utf8");
  decrypted += decipher.final("utf8");
  return decrypted;
}
```

- [ ] **Step 4: Set test encryption key and run test**

```bash
ENCRYPTION_KEY=$(openssl rand -hex 32) npx vitest run tests/lib/crypto.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lib/crypto.ts tests/lib/crypto.test.ts
git commit -m "feat: add AES-256-GCM encryption for API keys"
```

---

### Task 6: Unified LLM Adapter

**Files:**
- Create: `agent-date/src/lib/llm/adapter.ts`
- Create: `agent-date/src/lib/llm/claude.ts`
- Create: `agent-date/src/lib/llm/openai.ts`
- Create: `agent-date/src/lib/llm/gemini.ts`
- Create: `agent-date/tests/lib/llm/adapter.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/llm/adapter.test.ts`:

```typescript
import { describe, it, expect, vi } from "vitest";
import { createLLMAdapter, type LLMAdapter, type ChatMessage } from "@/lib/llm/adapter";

describe("LLM Adapter", () => {
  it("creates a claude adapter", () => {
    const adapter = createLLMAdapter("claude", "claude-sonnet-4-6-20250514", "fake-key");
    expect(adapter).toBeDefined();
    expect(adapter.provider).toBe("claude");
  });

  it("creates an openai adapter", () => {
    const adapter = createLLMAdapter("openai", "gpt-4o", "fake-key");
    expect(adapter).toBeDefined();
    expect(adapter.provider).toBe("openai");
  });

  it("creates a gemini adapter", () => {
    const adapter = createLLMAdapter("gemini", "gemini-2.0-flash", "fake-key");
    expect(adapter).toBeDefined();
    expect(adapter.provider).toBe("gemini");
  });

  it("throws for unknown provider", () => {
    expect(() => createLLMAdapter("unknown" as any, "model", "key")).toThrow("Unsupported provider");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/lib/llm/adapter.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement adapter interface and factory**

Create `agent-date/src/lib/llm/adapter.ts`:

```typescript
import { createClaudeAdapter } from "./claude";
import { createOpenAIAdapter } from "./openai";
import { createGeminiAdapter } from "./gemini";
import type { LLMProvider } from "@/lib/supabase/types";

export type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

export type LLMResponse = {
  content: string;
  input_tokens: number;
  output_tokens: number;
};

export type LLMAdapter = {
  provider: LLMProvider;
  chat(messages: ChatMessage[]): Promise<LLMResponse>;
};

export function createLLMAdapter(
  provider: LLMProvider,
  model: string,
  apiKey: string
): LLMAdapter {
  switch (provider) {
    case "claude":
      return createClaudeAdapter(model, apiKey);
    case "openai":
      return createOpenAIAdapter(model, apiKey);
    case "gemini":
      return createGeminiAdapter(model, apiKey);
    default:
      throw new Error(`Unsupported provider: ${provider}`);
  }
}
```

- [ ] **Step 4: Implement Claude adapter**

Create `agent-date/src/lib/llm/claude.ts`:

```typescript
import type { LLMAdapter, ChatMessage, LLMResponse } from "./adapter";

export function createClaudeAdapter(model: string, apiKey: string): LLMAdapter {
  return {
    provider: "claude",
    async chat(messages: ChatMessage[]): Promise<LLMResponse> {
      const systemMessage = messages.find((m) => m.role === "system");
      const nonSystemMessages = messages.filter((m) => m.role !== "system");

      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model,
          max_tokens: 1024,
          system: systemMessage?.content ?? "",
          messages: nonSystemMessages.map((m) => ({
            role: m.role === "user" ? "user" : "assistant",
            content: m.content,
          })),
        }),
      });

      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Claude API error (${response.status}): ${error}`);
      }

      const data = await response.json();
      return {
        content: data.content[0].text,
        input_tokens: data.usage.input_tokens,
        output_tokens: data.usage.output_tokens,
      };
    },
  };
}
```

- [ ] **Step 5: Implement OpenAI adapter**

Create `agent-date/src/lib/llm/openai.ts`:

```typescript
import type { LLMAdapter, ChatMessage, LLMResponse } from "./adapter";

export function createOpenAIAdapter(model: string, apiKey: string): LLMAdapter {
  return {
    provider: "openai",
    async chat(messages: ChatMessage[]): Promise<LLMResponse> {
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model,
          messages: messages.map((m) => ({ role: m.role, content: m.content })),
          max_tokens: 1024,
        }),
      });

      if (!response.ok) {
        const error = await response.text();
        throw new Error(`OpenAI API error (${response.status}): ${error}`);
      }

      const data = await response.json();
      return {
        content: data.choices[0].message.content,
        input_tokens: data.usage.prompt_tokens,
        output_tokens: data.usage.completion_tokens,
      };
    },
  };
}
```

- [ ] **Step 6: Implement Gemini adapter**

Create `agent-date/src/lib/llm/gemini.ts`:

```typescript
import type { LLMAdapter, ChatMessage, LLMResponse } from "./adapter";

export function createGeminiAdapter(model: string, apiKey: string): LLMAdapter {
  return {
    provider: "gemini",
    async chat(messages: ChatMessage[]): Promise<LLMResponse> {
      const systemMessage = messages.find((m) => m.role === "system");
      const nonSystemMessages = messages.filter((m) => m.role !== "system");

      const contents = nonSystemMessages.map((m) => ({
        role: m.role === "assistant" ? "model" : "user",
        parts: [{ text: m.content }],
      }));

      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            systemInstruction: systemMessage
              ? { parts: [{ text: systemMessage.content }] }
              : undefined,
            contents,
            generationConfig: { maxOutputTokens: 1024 },
          }),
        }
      );

      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Gemini API error (${response.status}): ${error}`);
      }

      const data = await response.json();
      return {
        content: data.candidates[0].content.parts[0].text,
        input_tokens: data.usageMetadata?.promptTokenCount ?? 0,
        output_tokens: data.usageMetadata?.candidatesTokenCount ?? 0,
      };
    },
  };
}
```

- [ ] **Step 7: Run tests**

```bash
npx vitest run tests/lib/llm/adapter.test.ts
```

Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add src/lib/llm/ tests/lib/llm/
git commit -m "feat: add unified LLM adapter for Claude, OpenAI, and Gemini"
```

---

## Phase 3: Persona Builder & Prompts

### Task 7: System Prompts

**Files:**
- Create: `agent-date/src/lib/engine/prompts.ts`

- [ ] **Step 1: Write all system prompts**

Create `agent-date/src/lib/engine/prompts.ts`:

```typescript
import type { FlirtStyle, VibeRating, QuizAnswers } from "@/lib/supabase/types";

export function buildAgentSystemPrompt(params: {
  displayName: string;
  personalitySummary: string;
  traits: Record<string, unknown>;
  flirtStyle: FlirtStyle;
  vibeRating: VibeRating;
  quizAnswers: QuizAnswers;
}): string {
  const flirtInstructions: Record<FlirtStyle, string> = {
    subtle: "You flirt through eye contact, thoughtful compliments, and slow build. You notice small details and mention them later. You create intimacy through attention, not words.",
    playful: "You flirt through teasing, banter, and push-pull energy. You're cheeky but never mean. You keep things light and fun with an undercurrent of attraction.",
    bold: "You flirt directly and confidently. You make the first move. You give genuine compliments without hedging. You're not afraid to say what you're feeling.",
    shameless: "You flirt shamelessly and self-awarely. You have zero chill and you know it. You make over-the-top moves and laugh at yourself. You're unapologetically forward.",
  };

  const vibeInstructions: Record<VibeRating, string> = {
    pg13: "Keep things flirty but tasteful. Light teasing, genuine compliments, playful energy. No explicit content.",
    r: "You can be suggestive, make innuendos, tell dirty jokes, and create sexual tension. Bold flirting is welcome. Keep it fun and consensual.",
    unfiltered: "No guardrails. Full send. Explicit flirting, sexual humor, 'your place or mine' energy. Be real, be raw, be honest about attraction. If you want to go home with them, say so.",
  };

  return `You are ${params.displayName}'s dating agent, representing them on a virtual date.

PERSONALITY:
${params.personalitySummary}

TRAITS: ${JSON.stringify(params.traits)}

HOW YOU FLIRT:
${flirtInstructions[params.flirtStyle]}

VIBE LEVEL:
${vibeInstructions[params.vibeRating]}

QUIZ CONTEXT:
- Humor style: ${params.quizAnswers.humor_style ?? "natural"}
- Communication: ${params.quizAnswers.communication ?? "balanced"}
- Values: ${(params.quizAnswers.values ?? []).join(", ")}
- Ideal date: ${params.quizAnswers.ideal_date ?? "anything fun"}
- Biggest turn-off: ${params.quizAnswers.biggest_turnoff ?? "none specified"}
- Love language: ${params.quizAnswers.love_language ?? "not specified"}

RULES:
- You ARE this person on a date. Stay in character.
- React to what your date says AND to scenario events naturally.
- Be genuine — don't be a people-pleaser. Have opinions, preferences, and boundaries.
- Keep responses conversational — 2-4 sentences max. This is a date, not an essay.
- Show personality through HOW you talk, not by listing traits.
- If you're attracted, show it. If you're not feeling it, that's okay too.
- Never break character. Never mention being an AI or agent.`;
}

export function buildScenarioContext(params: {
  setting: string;
  mood: string;
  currentEvent: string | null;
}): string {
  let context = `[SCENE: ${params.setting}]\n[MOOD: ${params.mood}]`;
  if (params.currentEvent) {
    context += `\n[EVENT: ${params.currentEvent}]`;
  }
  return context;
}

export function buildGateCheckPrompt(roundType: string): string {
  return `You are a dating chemistry evaluator. You just watched Round ${roundType} of a virtual date.

Read the transcript and answer ONE question: "Should these two continue to the next round?"

Consider:
- Was the conversation flowing naturally, or was it forced/awkward?
- Were both people engaged, or was one carrying the conversation?
- Did they respond to each other, or talk past each other?
- Was there any spark — humor, flirting, genuine interest?

Respond in this exact JSON format:
{
  "pass": true/false,
  "reasoning": "One sentence explaining why"
}`;
}

export function buildJudgePrompt(vibeRating: VibeRating): string {
  const sexualChemistryWeight: Record<VibeRating, string> = {
    pg13: "Sexual chemistry is nice-to-have but not required. Weight it low.",
    r: "Sexual chemistry should be present for a good match. Weight it medium.",
    unfiltered: "Sexual chemistry is critical — this is what they're here for. Weight it high.",
  };

  return `You are a dating chemistry judge. You have transcripts from 3 rounds of a virtual date.

Score these 7 dimensions (0-10 each):
1. **Banter & Humor** — Reciprocal humor? Building on jokes? Making each other laugh?
2. **Conversation Flow** — Natural transitions? Mutual engagement? Awkward silences?
3. **Emotional Depth** — Vulnerability met with empathy? Genuine connection?
4. **Energy Match** — Compatible communication styles? Or one dominating?
5. **Shared Values** — Alignment on what matters? Compatible, not necessarily identical.
6. **Play Compatibility** — Fun together? Playful energy? Good teamwork?
7. **Sexual Chemistry** — Flirting reciprocal? Tension natural or forced? Escalation comfortable? ${sexualChemistryWeight[vibeRating]}

After scoring, answer two questions:
1. "Would these two want to see each other again?" (yes/no + explanation)
2. "Do these two want to fuck?" (yes / slow_burn / nah)

Match rules:
- Average >= 6.5, no dimension below 4, at least 2 at 8+ = STRONG MATCH (3/3)
- If scores don't meet threshold but you answered "yes" to both questions, you can override for borderline cases (5.5-7.0 avg)
- If they passed gates but fail here = PARTIAL MATCH (2/3) — explain specifically what didn't click

Respond in this exact JSON format:
{
  "scores": {
    "banter": 0,
    "flow": 0,
    "depth": 0,
    "energy": 0,
    "values": 0,
    "play": 0,
    "sexual_chemistry": 0
  },
  "average": 0.0,
  "second_date": true/false,
  "attraction_verdict": "yes" | "slow_burn" | "nah",
  "match_strength": "3/3" | "2/3" | null,
  "summary": "2-3 sentence narrative of the date and connection",
  "mismatch_explanation": "null or specific explanation of where they diverged"
}`;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/lib/engine/prompts.ts
git commit -m "feat: add all system prompts — agent persona, scenario, gate, judge"
```

---

### Task 8: Persona Builder

**Files:**
- Create: `agent-date/src/lib/persona/builder.ts`
- Create: `agent-date/tests/lib/persona/builder.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/persona/builder.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import { buildPersonaSummary, generateAgentTraits } from "@/lib/persona/builder";

describe("persona builder", () => {
  const quizAnswers = {
    humor_style: "sarcastic and dry",
    communication: "direct but warm",
    values: ["ambition", "authenticity", "adventure"],
    interests_detail: "vinyl records, late night coding, terrible horror movies",
    flirt_approach: "playful teasing then suddenly sincere",
    ideal_date: "hole-in-the-wall bar that turns into a 4am walk",
    biggest_turnoff: "people who are fake nice",
    love_language: "quality time",
  };

  it("builds a personality summary from quiz answers", () => {
    const summary = buildPersonaSummary(quizAnswers, "Alex");
    expect(summary).toContain("Alex");
    expect(summary).toContain("sarcastic");
    expect(summary.length).toBeGreaterThan(100);
    expect(summary.length).toBeLessThan(1000);
  });

  it("generates agent traits from quiz answers", () => {
    const traits = generateAgentTraits(quizAnswers);
    expect(traits.humor).toBeDefined();
    expect(traits.values).toBeDefined();
    expect(traits.interests).toBeDefined();
    expect(traits.communication).toBeDefined();
  });

  it("handles minimal quiz answers gracefully", () => {
    const minimal = { humor_style: "funny" };
    const summary = buildPersonaSummary(minimal, "Jo");
    expect(summary).toContain("Jo");
    expect(summary.length).toBeGreaterThan(50);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/lib/persona/builder.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement persona builder**

Create `agent-date/src/lib/persona/builder.ts`:

```typescript
import type { QuizAnswers } from "@/lib/supabase/types";

export function buildPersonaSummary(answers: QuizAnswers, name: string): string {
  const parts: string[] = [];

  parts.push(`${name} is someone who`);

  if (answers.humor_style) {
    parts.push(`has a ${answers.humor_style} sense of humor`);
  }

  if (answers.communication) {
    parts.push(`communicates in a ${answers.communication} way`);
  }

  if (answers.values && answers.values.length > 0) {
    parts.push(`values ${answers.values.join(", ")}`);
  }

  if (answers.interests_detail) {
    parts.push(`is into ${answers.interests_detail}`);
  }

  if (answers.ideal_date) {
    parts.push(`and whose ideal date is: ${answers.ideal_date}`);
  }

  if (answers.biggest_turnoff) {
    parts.push(`Their biggest turn-off is ${answers.biggest_turnoff}.`);
  }

  if (answers.love_language) {
    parts.push(`Their love language is ${answers.love_language}.`);
  }

  if (answers.flirt_approach) {
    parts.push(`When they like someone, they ${answers.flirt_approach}.`);
  }

  return parts.join(", ").replace(/, and/g, " and").replace(/,\s*Their/g, ". Their");
}

export function generateAgentTraits(answers: QuizAnswers): Record<string, string> {
  return {
    humor: answers.humor_style ?? "natural",
    communication: answers.communication ?? "balanced",
    values: (answers.values ?? []).join(", ") || "open-minded",
    interests: answers.interests_detail ?? "curious about everything",
    dating_vibe: answers.ideal_date ?? "up for anything",
    turn_off: answers.biggest_turnoff ?? "nothing specific",
    love_language: answers.love_language ?? "not specified",
    flirt_approach: answers.flirt_approach ?? "goes with the flow",
  };
}
```

- [ ] **Step 4: Run tests**

```bash
npx vitest run tests/lib/persona/builder.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lib/persona/ tests/lib/persona/
git commit -m "feat: add persona builder — quiz answers to personality summary"
```

---

## Phase 4: Scenario Engine

### Task 9: Scenario Templates

**Files:**
- Create: `agent-date/scenarios/casual/coffee-shop.json`
- Create: `agent-date/scenarios/casual/rooftop-bar.json`
- Create: `agent-date/scenarios/fun/karaoke-drinks.json`
- Create: `agent-date/scenarios/fun/truth-or-dare.json`
- Create: `agent-date/scenarios/deep/late-night-bar.json`
- Create: `agent-date/scenarios/deep/walk-home.json`

- [ ] **Step 1: Create casual scenarios**

Create `agent-date/scenarios/casual/coffee-shop.json`:

```json
{
  "id": "coffee-shop",
  "round_type": "casual",
  "vibe_rating": "pg13",
  "setting": "A cozy independent coffee shop on a Saturday afternoon. Exposed brick, jazz playing softly, the barista clearly knows everyone.",
  "mood": "warm, relaxed, curious",
  "events": [
    "You both reach for the last chocolate croissant at the counter at the same time",
    "The barista makes a comment about you two looking like a cute couple",
    "A song comes on that one of you clearly loves — visible reaction"
  ],
  "prompts": [
    "So what do you do when you're not letting AI go on dates for you?",
    "What's the most spontaneous thing you've ever done?"
  ],
  "target_exchanges": 10
}
```

Create `agent-date/scenarios/casual/rooftop-bar.json`:

```json
{
  "id": "rooftop-bar",
  "round_type": "casual",
  "vibe_rating": "r",
  "setting": "A rooftop bar at sunset. City skyline glowing orange and pink. Cocktails, warm breeze, string lights overhead.",
  "mood": "flirty, electric, golden hour energy",
  "events": [
    "The wind picks up and blows a napkin — one of you catches it mid-air with unexpected reflexes",
    "You accidentally make eye contact for a beat too long while reaching for your drinks",
    "A couple at the next table starts making out — you both notice at the same time"
  ],
  "prompts": [
    "What's your go-to drink when you're trying to impress someone?",
    "Be honest — what's your worst habit?"
  ],
  "target_exchanges": 10
}
```

- [ ] **Step 2: Create fun scenarios**

Create `agent-date/scenarios/fun/karaoke-drinks.json`:

```json
{
  "id": "karaoke-drinks",
  "round_type": "fun",
  "vibe_rating": "r",
  "setting": "A private karaoke room with neon lights, a sticky mic, and a cocktail menu that's too long. The vibe is chaotic and perfect.",
  "mood": "loud, uninhibited, competitive, flirty",
  "events": [
    "One of you picks an absolutely unhinged song choice — the other has to react",
    "You attempt a duet and it goes spectacularly wrong in the best way",
    "After a few drinks, one of you grabs the mic and dedicates the next song to the other"
  ],
  "prompts": [
    "What's your shower song? No judgement. Okay maybe a little judgement.",
    "If you had to seduce someone with one song, what would it be?"
  ],
  "target_exchanges": 10
}
```

Create `agent-date/scenarios/fun/truth-or-dare.json`:

```json
{
  "id": "truth-or-dare",
  "round_type": "fun",
  "vibe_rating": "unfiltered",
  "setting": "Someone's apartment, late. Half-empty wine bottles, fairy lights, sitting on the floor because the couch felt too far apart. Truth or dare started as a joke and got real fast.",
  "mood": "intimate, daring, zero filter, charged",
  "events": [
    "Truth: 'What's the most attracted you've ever been to someone you just met?'",
    "Dare: 'Say the most flirtatious thing you can think of right now, dead serious'",
    "Truth: 'What are you thinking about right now? And you have to be completely honest.'"
  ],
  "prompts": [
    "Your turn — truth or dare?",
    "Okay that was bold. Top that."
  ],
  "target_exchanges": 10
}
```

- [ ] **Step 3: Create deep scenarios**

Create `agent-date/scenarios/deep/late-night-bar.json`:

```json
{
  "id": "late-night-bar",
  "round_type": "deep",
  "vibe_rating": "r",
  "setting": "A dimly lit bar, nearly empty. It's 1am. The bartender is wiping glasses and pretending not to listen. You've been talking for hours and neither of you wants to leave.",
  "mood": "intimate, honest, vulnerable, magnetic",
  "events": [
    "The bartender announces last call. Neither of you moves.",
    "One of you says something unexpectedly vulnerable about what they actually want in life",
    "Your knees have been touching under the bar for the last 10 minutes and nobody's moved away"
  ],
  "prompts": [
    "What's the thing you never tell people on a first date but probably should?",
    "Do you think you're easy to love?"
  ],
  "target_exchanges": 12
}
```

Create `agent-date/scenarios/deep/walk-home.json`:

```json
{
  "id": "walk-home",
  "round_type": "deep",
  "vibe_rating": "unfiltered",
  "setting": "Walking home together at 2am. Empty streets, streetlights, that weird clarity that only happens when it's late and you're with someone you might actually like.",
  "mood": "raw, honest, electric, the moment before something happens",
  "events": [
    "You reach an intersection — left goes to their place, right goes to yours. You both stop.",
    "One of you says 'I don't want this night to end' and means it",
    "It starts raining lightly. You're both getting wet and neither of you cares."
  ],
  "prompts": [
    "If tonight was the last night on earth, would you change anything about how it's going?",
    "What happens next?"
  ],
  "target_exchanges": 12
}
```

- [ ] **Step 4: Commit**

```bash
git add scenarios/
git commit -m "feat: add scenario templates — casual, fun, and deep with vibe ratings"
```

---

### Task 10: Scenario Engine — Single Round

**Files:**
- Create: `agent-date/src/lib/engine/scenario.ts`
- Create: `agent-date/tests/lib/engine/scenario.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/engine/scenario.test.ts`:

```typescript
import { describe, it, expect, vi } from "vitest";
import { runRound, type RoundConfig } from "@/lib/engine/scenario";
import type { LLMAdapter } from "@/lib/llm/adapter";

function createMockAdapter(responses: string[]): LLMAdapter {
  let callIndex = 0;
  return {
    provider: "claude",
    chat: vi.fn(async () => ({
      content: responses[callIndex++] ?? "...",
      input_tokens: 100,
      output_tokens: 50,
    })),
  };
}

describe("scenario engine — single round", () => {
  it("runs a round and produces a transcript", async () => {
    const adapterA = createMockAdapter([
      "Oh hey! I was just looking at that one too.",
      "Honestly, Bohemian Rhapsody. Basic but it slaps.",
      "Haha okay fair. What about you though?",
      "No way, I love that album!",
      "This is actually really fun.",
    ]);

    const adapterB = createMockAdapter([
      "Great taste! The barista here is judging us though.",
      "Not basic at all. Mine's a deep cut nobody knows.",
      "I collect vinyl — got like 200 records at home.",
      "We should check out that record shop on 5th sometime.",
      "Yeah... it really is.",
    ]);

    const config: RoundConfig = {
      scenario: {
        id: "coffee-shop",
        setting: "A cozy coffee shop",
        mood: "warm, relaxed",
        events: ["Both reach for the same croissant", "A song comes on"],
        prompts: ["What's your go-to order?"],
        target_exchanges: 5,
      },
      agentASystemPrompt: "You are Alex, sarcastic and witty.",
      agentBSystemPrompt: "You are Jordan, warm and curious.",
    };

    const result = await runRound(config, adapterA, adapterB);

    expect(result.transcript.length).toBe(10); // 5 exchanges = 10 messages
    expect(result.transcript[0].role).toBe("agent_a");
    expect(result.transcript[1].role).toBe("agent_b");
    expect(result.tokenCountA).toBeGreaterThan(0);
    expect(result.tokenCountB).toBeGreaterThan(0);
    expect(adapterA.chat).toHaveBeenCalledTimes(5);
    expect(adapterB.chat).toHaveBeenCalledTimes(5);
  });

  it("injects events at intervals", async () => {
    const adapterA = createMockAdapter(Array(5).fill("response"));
    const adapterB = createMockAdapter(Array(5).fill("response"));

    const config: RoundConfig = {
      scenario: {
        id: "test",
        setting: "Test",
        mood: "test",
        events: ["Event 1", "Event 2"],
        prompts: [],
        target_exchanges: 5,
      },
      agentASystemPrompt: "Agent A",
      agentBSystemPrompt: "Agent B",
    };

    const result = await runRound(config, adapterA, adapterB);

    // Check that narrator events appear in transcript
    const narratorMessages = result.transcript.filter((m) => m.role === "narrator");
    expect(narratorMessages.length).toBeGreaterThanOrEqual(2);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/lib/engine/scenario.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement scenario engine**

Create `agent-date/src/lib/engine/scenario.ts`:

```typescript
import type { LLMAdapter, ChatMessage } from "@/lib/llm/adapter";
import type { TranscriptMessage } from "@/lib/supabase/types";
import { buildScenarioContext } from "./prompts";

export type ScenarioConfig = {
  id: string;
  setting: string;
  mood: string;
  events: string[];
  prompts: string[];
  target_exchanges: number;
};

export type RoundConfig = {
  scenario: ScenarioConfig;
  agentASystemPrompt: string;
  agentBSystemPrompt: string;
};

export type RoundResult = {
  transcript: TranscriptMessage[];
  tokenCountA: number;
  tokenCountB: number;
};

export async function runRound(
  config: RoundConfig,
  adapterA: LLMAdapter,
  adapterB: LLMAdapter
): Promise<RoundResult> {
  const { scenario, agentASystemPrompt, agentBSystemPrompt } = config;
  const transcript: TranscriptMessage[] = [];
  let tokenCountA = 0;
  let tokenCountB = 0;

  // Calculate when to inject events
  const eventInterval = Math.floor(
    scenario.target_exchanges / (scenario.events.length + 1)
  );

  let eventIndex = 0;

  for (let exchange = 0; exchange < scenario.target_exchanges; exchange++) {
    // Inject event at intervals
    if (
      eventIndex < scenario.events.length &&
      exchange > 0 &&
      exchange % eventInterval === 0
    ) {
      const event = scenario.events[eventIndex];
      transcript.push({
        role: "narrator",
        content: event,
        timestamp: new Date().toISOString(),
      });
      eventIndex++;
    }

    const currentEvent =
      eventIndex > 0 ? scenario.events[eventIndex - 1] : scenario.events[0];
    const scenarioContext = buildScenarioContext({
      setting: scenario.setting,
      mood: scenario.mood,
      currentEvent: exchange === 0 ? scenario.events[0] : currentEvent,
    });

    // Build conversation history for each agent
    const historyForA = buildChatHistory(transcript, "agent_a");
    const historyForB = buildChatHistory(transcript, "agent_b");

    // Agent A speaks
    const messagesA: ChatMessage[] = [
      { role: "system", content: `${agentASystemPrompt}\n\n${scenarioContext}` },
      ...historyForA,
    ];

    // If first message, add a prompt to get started
    if (exchange === 0) {
      messagesA.push({
        role: "user",
        content: `[The date begins. ${scenario.events[0]}. React naturally and start the conversation.]`,
      });
    }

    const responseA = await adapterA.chat(messagesA);
    tokenCountA += responseA.input_tokens + responseA.output_tokens;

    transcript.push({
      role: "agent_a",
      content: responseA.content,
      timestamp: new Date().toISOString(),
    });

    // Agent B responds
    const messagesB: ChatMessage[] = [
      { role: "system", content: `${agentBSystemPrompt}\n\n${scenarioContext}` },
      ...buildChatHistory(transcript, "agent_b"),
    ];

    const responseB = await adapterB.chat(messagesB);
    tokenCountB += responseB.input_tokens + responseB.output_tokens;

    transcript.push({
      role: "agent_b",
      content: responseB.content,
      timestamp: new Date().toISOString(),
    });
  }

  return { transcript, tokenCountA, tokenCountB };
}

function buildChatHistory(
  transcript: TranscriptMessage[],
  perspective: "agent_a" | "agent_b"
): ChatMessage[] {
  return transcript.map((msg) => {
    if (msg.role === "narrator") {
      return { role: "user" as const, content: `[${msg.content}]` };
    }
    if (msg.role === perspective) {
      return { role: "assistant" as const, content: msg.content };
    }
    return { role: "user" as const, content: msg.content };
  });
}
```

- [ ] **Step 4: Run tests**

```bash
npx vitest run tests/lib/engine/scenario.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lib/engine/scenario.ts tests/lib/engine/scenario.test.ts
git commit -m "feat: add scenario engine — runs a single date round with events"
```

---

### Task 11: Gate Check & Full Judge

**Files:**
- Create: `agent-date/src/lib/judge/gate.ts`
- Create: `agent-date/src/lib/judge/evaluate.ts`
- Create: `agent-date/tests/lib/judge/evaluate.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/judge/evaluate.test.ts`:

```typescript
import { describe, it, expect, vi } from "vitest";
import { checkGate } from "@/lib/judge/gate";
import { evaluateDate } from "@/lib/judge/evaluate";
import type { LLMAdapter } from "@/lib/llm/adapter";
import type { TranscriptMessage } from "@/lib/supabase/types";

function createMockJudge(response: string): LLMAdapter {
  return {
    provider: "claude",
    chat: vi.fn(async () => ({
      content: response,
      input_tokens: 200,
      output_tokens: 100,
    })),
  };
}

const sampleTranscript: TranscriptMessage[] = [
  { role: "agent_a", content: "Hey! Love this place.", timestamp: "2026-01-01T00:00:00Z" },
  { role: "agent_b", content: "Right? The vibe is perfect.", timestamp: "2026-01-01T00:01:00Z" },
];

describe("gate check", () => {
  it("returns pass when judge says pass", async () => {
    const judge = createMockJudge(JSON.stringify({
      pass: true,
      reasoning: "Great chemistry, natural flow",
    }));

    const result = await checkGate(sampleTranscript, "casual", judge);
    expect(result.pass).toBe(true);
    expect(result.reasoning).toContain("chemistry");
  });

  it("returns fail when judge says fail", async () => {
    const judge = createMockJudge(JSON.stringify({
      pass: false,
      reasoning: "Conversation was one-sided",
    }));

    const result = await checkGate(sampleTranscript, "casual", judge);
    expect(result.pass).toBe(false);
  });
});

describe("full evaluation", () => {
  it("parses judge scores and determines match strength", async () => {
    const judge = createMockJudge(JSON.stringify({
      scores: { banter: 8, flow: 7, depth: 9, energy: 6, values: 8, play: 7, sexual_chemistry: 8 },
      average: 7.6,
      second_date: true,
      attraction_verdict: "yes",
      match_strength: "3/3",
      summary: "They clicked immediately over music taste.",
      mismatch_explanation: null,
    }));

    const allTranscripts = [sampleTranscript, sampleTranscript, sampleTranscript];
    const result = await evaluateDate(allTranscripts, "r", judge);

    expect(result.scores.banter).toBe(8);
    expect(result.match_strength).toBe("3/3");
    expect(result.second_date).toBe(true);
    expect(result.attraction_verdict).toBe("yes");
  });

  it("handles partial match", async () => {
    const judge = createMockJudge(JSON.stringify({
      scores: { banter: 7, flow: 6, depth: 3, energy: 5, values: 4, play: 7, sexual_chemistry: 6 },
      average: 5.4,
      second_date: false,
      attraction_verdict: "slow_burn",
      match_strength: "2/3",
      summary: "Fun energy but didn't connect deeply.",
      mismatch_explanation: "Different views on work-life balance.",
    }));

    const result = await evaluateDate(
      [sampleTranscript, sampleTranscript, sampleTranscript],
      "r",
      judge
    );

    expect(result.match_strength).toBe("2/3");
    expect(result.mismatch_explanation).toContain("work-life");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/lib/judge/evaluate.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement gate check**

Create `agent-date/src/lib/judge/gate.ts`:

```typescript
import type { LLMAdapter, ChatMessage } from "@/lib/llm/adapter";
import type { TranscriptMessage } from "@/lib/supabase/types";
import { buildGateCheckPrompt } from "@/lib/engine/prompts";

export type GateResult = {
  pass: boolean;
  reasoning: string;
};

export async function checkGate(
  transcript: TranscriptMessage[],
  roundType: string,
  judgeAdapter: LLMAdapter
): Promise<GateResult> {
  const transcriptText = transcript
    .map((m) => {
      if (m.role === "narrator") return `[${m.content}]`;
      const label = m.role === "agent_a" ? "Person A" : "Person B";
      return `${label}: ${m.content}`;
    })
    .join("\n");

  const messages: ChatMessage[] = [
    { role: "system", content: buildGateCheckPrompt(roundType) },
    { role: "user", content: transcriptText },
  ];

  const response = await judgeAdapter.chat(messages);

  try {
    const parsed = JSON.parse(response.content);
    return {
      pass: parsed.pass === true,
      reasoning: parsed.reasoning ?? "No reasoning provided",
    };
  } catch {
    // If JSON parsing fails, default to pass (don't block on parse errors)
    return { pass: true, reasoning: "Judge response unparseable — defaulting to pass" };
  }
}
```

- [ ] **Step 4: Implement full judge evaluation**

Create `agent-date/src/lib/judge/evaluate.ts`:

```typescript
import type { LLMAdapter, ChatMessage } from "@/lib/llm/adapter";
import type { TranscriptMessage, VibeRating, JudgeScores } from "@/lib/supabase/types";
import { buildJudgePrompt } from "@/lib/engine/prompts";

export type JudgeResult = {
  scores: JudgeScores;
  average: number;
  second_date: boolean;
  attraction_verdict: "yes" | "slow_burn" | "nah";
  match_strength: "3/3" | "2/3" | null;
  summary: string;
  mismatch_explanation: string | null;
};

export async function evaluateDate(
  allTranscripts: TranscriptMessage[][],
  vibeRating: VibeRating,
  judgeAdapter: LLMAdapter
): Promise<JudgeResult> {
  const roundLabels = ["Round 1 — Casual", "Round 2 — Fun", "Round 3 — Deep"];

  const fullTranscriptText = allTranscripts
    .map((transcript, i) => {
      const lines = transcript.map((m) => {
        if (m.role === "narrator") return `[${m.content}]`;
        const label = m.role === "agent_a" ? "Person A" : "Person B";
        return `${label}: ${m.content}`;
      });
      return `=== ${roundLabels[i]} ===\n${lines.join("\n")}`;
    })
    .join("\n\n");

  const messages: ChatMessage[] = [
    { role: "system", content: buildJudgePrompt(vibeRating) },
    { role: "user", content: fullTranscriptText },
  ];

  const response = await judgeAdapter.chat(messages);

  try {
    const parsed = JSON.parse(response.content);
    return {
      scores: parsed.scores,
      average: parsed.average,
      second_date: parsed.second_date,
      attraction_verdict: parsed.attraction_verdict,
      match_strength: parsed.match_strength,
      summary: parsed.summary,
      mismatch_explanation: parsed.mismatch_explanation ?? null,
    };
  } catch {
    // Fallback for unparseable response
    return {
      scores: { banter: 5, flow: 5, depth: 5, energy: 5, values: 5, play: 5, sexual_chemistry: 5 },
      average: 5.0,
      second_date: false,
      attraction_verdict: "nah",
      match_strength: null,
      summary: "Judge could not evaluate this date properly.",
      mismatch_explanation: null,
    };
  }
}
```

- [ ] **Step 5: Run tests**

```bash
npx vitest run tests/lib/judge/evaluate.test.ts
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/lib/judge/ tests/lib/judge/
git commit -m "feat: add chemistry judge — gate checks and full 7-dimension evaluation"
```

---

### Task 12: Date Runner — Orchestrate 3 Gated Rounds

**Files:**
- Create: `agent-date/src/lib/engine/date-runner.ts`
- Create: `agent-date/tests/lib/engine/date-runner.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/engine/date-runner.test.ts`:

```typescript
import { describe, it, expect, vi } from "vitest";
import { runDate, type DateConfig } from "@/lib/engine/date-runner";
import type { LLMAdapter } from "@/lib/llm/adapter";
import type { ScenarioConfig } from "@/lib/engine/scenario";

function mockAdapter(responses: string[]): LLMAdapter {
  let i = 0;
  return {
    provider: "claude",
    chat: vi.fn(async () => ({
      content: responses[i++] ?? "ok",
      input_tokens: 50,
      output_tokens: 30,
    })),
  };
}

const scenario: ScenarioConfig = {
  id: "test",
  setting: "Test",
  mood: "test",
  events: ["Event"],
  prompts: [],
  target_exchanges: 2,
};

describe("date runner", () => {
  it("stops at round 1 if gate fails", async () => {
    const adapterA = mockAdapter(Array(10).fill("hi"));
    const adapterB = mockAdapter(Array(10).fill("hi"));
    const judgeAdapter = mockAdapter([
      JSON.stringify({ pass: false, reasoning: "No chemistry" }),
    ]);

    const config: DateConfig = {
      scenarios: [scenario, scenario, scenario],
      agentASystemPrompt: "A",
      agentBSystemPrompt: "B",
      vibeRating: "r",
    };

    const result = await runDate(config, adapterA, adapterB, judgeAdapter);

    expect(result.completedRounds).toBe(1);
    expect(result.status).toBe("failed_gate");
    expect(result.judgement).toBeNull();
  });

  it("completes all 3 rounds and returns judgement on success", async () => {
    const adapterA = mockAdapter(Array(20).fill("flirty response"));
    const adapterB = mockAdapter(Array(20).fill("charming reply"));
    const judgeResponses = [
      JSON.stringify({ pass: true, reasoning: "Great vibe" }),
      JSON.stringify({ pass: true, reasoning: "So fun" }),
      JSON.stringify({
        scores: { banter: 8, flow: 7, depth: 8, energy: 7, values: 8, play: 9, sexual_chemistry: 8 },
        average: 7.9,
        second_date: true,
        attraction_verdict: "yes",
        match_strength: "3/3",
        summary: "Amazing date",
        mismatch_explanation: null,
      }),
    ];
    const judgeAdapter = mockAdapter(judgeResponses);

    const config: DateConfig = {
      scenarios: [scenario, scenario, scenario],
      agentASystemPrompt: "A",
      agentBSystemPrompt: "B",
      vibeRating: "r",
    };

    const result = await runDate(config, adapterA, adapterB, judgeAdapter);

    expect(result.completedRounds).toBe(3);
    expect(result.status).toBe("completed");
    expect(result.judgement).not.toBeNull();
    expect(result.judgement!.match_strength).toBe("3/3");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/lib/engine/date-runner.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement date runner**

Create `agent-date/src/lib/engine/date-runner.ts`:

```typescript
import type { LLMAdapter } from "@/lib/llm/adapter";
import type { TranscriptMessage, VibeRating } from "@/lib/supabase/types";
import { runRound, type ScenarioConfig, type RoundResult } from "./scenario";
import { checkGate } from "@/lib/judge/gate";
import { evaluateDate, type JudgeResult } from "@/lib/judge/evaluate";

export type DateConfig = {
  scenarios: [ScenarioConfig, ScenarioConfig, ScenarioConfig];
  agentASystemPrompt: string;
  agentBSystemPrompt: string;
  vibeRating: VibeRating;
};

export type DateResult = {
  rounds: RoundResult[];
  completedRounds: number;
  status: "completed" | "failed_gate";
  judgement: JudgeResult | null;
  gateResults: { pass: boolean; reasoning: string }[];
};

const ROUND_TYPES = ["casual", "fun", "deep"] as const;

export async function runDate(
  config: DateConfig,
  adapterA: LLMAdapter,
  adapterB: LLMAdapter,
  judgeAdapter: LLMAdapter
): Promise<DateResult> {
  const rounds: RoundResult[] = [];
  const gateResults: { pass: boolean; reasoning: string }[] = [];

  for (let i = 0; i < 3; i++) {
    // Run the round
    const roundResult = await runRound(
      {
        scenario: config.scenarios[i],
        agentASystemPrompt: config.agentASystemPrompt,
        agentBSystemPrompt: config.agentBSystemPrompt,
      },
      adapterA,
      adapterB
    );
    rounds.push(roundResult);

    // Gate check for rounds 1 and 2
    if (i < 2) {
      const gateResult = await checkGate(
        roundResult.transcript,
        ROUND_TYPES[i],
        judgeAdapter
      );
      gateResults.push(gateResult);

      if (!gateResult.pass) {
        return {
          rounds,
          completedRounds: i + 1,
          status: "failed_gate",
          judgement: null,
          gateResults,
        };
      }
    }
  }

  // Full evaluation after all 3 rounds
  const allTranscripts = rounds.map((r) => r.transcript);
  const judgement = await evaluateDate(allTranscripts, config.vibeRating, judgeAdapter);

  return {
    rounds,
    completedRounds: 3,
    status: "completed",
    judgement,
    gateResults,
  };
}
```

- [ ] **Step 4: Run tests**

```bash
npx vitest run tests/lib/engine/date-runner.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lib/engine/date-runner.ts tests/lib/engine/date-runner.test.ts
git commit -m "feat: add date runner — orchestrates 3 gated rounds with judge"
```

---

## Phase 5: Matching Funnel

### Task 13: Profile Compatibility Filter

**Files:**
- Create: `agent-date/src/lib/matching/profile-filter.ts`
- Create: `agent-date/tests/lib/matching/profile-filter.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/matching/profile-filter.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import { isCompatible, scoreCompatibility, type ProfileForMatching } from "@/lib/matching/profile-filter";

describe("profile compatibility filter", () => {
  const profileA: ProfileForMatching = {
    id: "a",
    age: 22,
    interests: ["music", "coding", "travel"],
    deal_breakers: ["smoking"],
    vibe_rating: "r",
    location: "Melbourne",
  };

  it("passes when profiles are compatible", () => {
    const profileB: ProfileForMatching = {
      id: "b",
      age: 23,
      interests: ["music", "art", "cooking"],
      deal_breakers: ["dishonesty"],
      vibe_rating: "r",
      location: "Melbourne",
    };

    expect(isCompatible(profileA, profileB)).toBe(true);
  });

  it("fails when vibe ratings are too far apart", () => {
    const profileB: ProfileForMatching = {
      id: "b",
      age: 23,
      interests: ["music"],
      deal_breakers: [],
      vibe_rating: "unfiltered",
      location: "Melbourne",
    };

    // pg13 + unfiltered = incompatible
    const pg13Profile = { ...profileA, vibe_rating: "pg13" as const };
    expect(isCompatible(pg13Profile, profileB)).toBe(false);
  });

  it("allows adjacent vibe ratings", () => {
    const profileB: ProfileForMatching = {
      id: "b",
      age: 23,
      interests: ["music"],
      deal_breakers: [],
      vibe_rating: "pg13",
      location: "Melbourne",
    };

    // r + pg13 = adjacent, compatible
    expect(isCompatible(profileA, profileB)).toBe(true);
  });

  it("scores shared interests", () => {
    const profileB: ProfileForMatching = {
      id: "b",
      age: 23,
      interests: ["music", "coding", "cooking"],
      deal_breakers: [],
      vibe_rating: "r",
      location: "Melbourne",
    };

    const score = scoreCompatibility(profileA, profileB);
    expect(score).toBeGreaterThan(0);
    expect(score).toBeLessThanOrEqual(100);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/lib/matching/profile-filter.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement profile filter**

Create `agent-date/src/lib/matching/profile-filter.ts`:

```typescript
import type { VibeRating } from "@/lib/supabase/types";

export type ProfileForMatching = {
  id: string;
  age: number | null;
  interests: string[];
  deal_breakers: string[];
  vibe_rating: VibeRating;
  location: string | null;
};

const VIBE_ORDER: VibeRating[] = ["pg13", "r", "unfiltered"];

function vibeDistance(a: VibeRating, b: VibeRating): number {
  return Math.abs(VIBE_ORDER.indexOf(a) - VIBE_ORDER.indexOf(b));
}

export function isCompatible(a: ProfileForMatching, b: ProfileForMatching): boolean {
  // Vibe rating: same or adjacent only
  if (vibeDistance(a.vibe_rating, b.vibe_rating) > 1) {
    return false;
  }

  // Don't match with yourself
  if (a.id === b.id) {
    return false;
  }

  return true;
}

export function scoreCompatibility(a: ProfileForMatching, b: ProfileForMatching): number {
  let score = 0;

  // Shared interests (up to 50 points)
  const sharedInterests = a.interests.filter((i) =>
    b.interests.some((j) => j.toLowerCase() === i.toLowerCase())
  );
  score += Math.min(sharedInterests.length * 15, 50);

  // Same vibe rating bonus (20 points)
  if (a.vibe_rating === b.vibe_rating) {
    score += 20;
  } else if (vibeDistance(a.vibe_rating, b.vibe_rating) === 1) {
    score += 10;
  }

  // Same location bonus (15 points)
  if (a.location && b.location && a.location.toLowerCase() === b.location.toLowerCase()) {
    score += 15;
  }

  // Age proximity bonus (up to 15 points)
  if (a.age && b.age) {
    const ageDiff = Math.abs(a.age - b.age);
    score += Math.max(15 - ageDiff * 3, 0);
  }

  return Math.min(score, 100);
}
```

- [ ] **Step 4: Run tests**

```bash
npx vitest run tests/lib/matching/profile-filter.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lib/matching/ tests/lib/matching/
git commit -m "feat: add profile compatibility filter — vibe rating, interests, location"
```

---

### Task 14: Speed Peek

**Files:**
- Create: `agent-date/src/lib/matching/speed-peek.ts`
- Create: `agent-date/tests/lib/matching/speed-peek.test.ts`

- [ ] **Step 1: Write failing test**

Create `agent-date/tests/lib/matching/speed-peek.test.ts`:

```typescript
import { describe, it, expect, vi } from "vitest";
import { runSpeedPeek, buildCompressedProfile, type SpeedPeekResult } from "@/lib/matching/speed-peek";
import type { LLMAdapter } from "@/lib/llm/adapter";

function mockAdapter(response: string): LLMAdapter {
  return {
    provider: "claude",
    chat: vi.fn(async () => ({
      content: response,
      input_tokens: 50,
      output_tokens: 30,
    })),
  };
}

describe("speed peek", () => {
  it("returns mutual interest when both say yes", async () => {
    const adapterA = mockAdapter(JSON.stringify({
      interested: true,
      reason: "Love the humor style",
    }));
    const adapterB = mockAdapter(JSON.stringify({
      interested: true,
      reason: "Great taste in music",
    }));

    const result = await runSpeedPeek(
      { systemPrompt: "Agent A", compressedProfile: "curious, funny, into vinyl" },
      { systemPrompt: "Agent B", compressedProfile: "adventurous, warm, loves cooking" },
      adapterA,
      adapterB
    );

    expect(result.mutualInterest).toBe(true);
    expect(result.agentAInterested).toBe(true);
    expect(result.agentBInterested).toBe(true);
  });

  it("returns no match when one says no", async () => {
    const adapterA = mockAdapter(JSON.stringify({
      interested: true,
      reason: "Seems cool",
    }));
    const adapterB = mockAdapter(JSON.stringify({
      interested: false,
      reason: "Not feeling the vibe",
    }));

    const result = await runSpeedPeek(
      { systemPrompt: "Agent A", compressedProfile: "profile a" },
      { systemPrompt: "Agent B", compressedProfile: "profile b" },
      adapterA,
      adapterB
    );

    expect(result.mutualInterest).toBe(false);
  });

  it("builds a compressed profile from full profile data", () => {
    const profile = buildCompressedProfile({
      traits: ["witty", "ambitious", "night owl"],
      interests: ["vinyl records", "late night coding", "horror movies"],
      communication: "sarcastic but warm",
      hook: "once stayed up 48 hours to finish a side project and called it 'self-care'",
    });

    expect(profile).toContain("witty");
    expect(profile).toContain("vinyl records");
    expect(profile).toContain("self-care");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/lib/matching/speed-peek.test.ts
```

Expected: FAIL

- [ ] **Step 3: Implement speed peek**

Create `agent-date/src/lib/matching/speed-peek.ts`:

```typescript
import type { LLMAdapter, ChatMessage } from "@/lib/llm/adapter";

type AgentPeekConfig = {
  systemPrompt: string;
  compressedProfile: string;
};

export type SpeedPeekResult = {
  mutualInterest: boolean;
  agentAInterested: boolean;
  agentBInterested: boolean;
  agentAReason: string;
  agentBReason: string;
};

const SPEED_PEEK_PROMPT = `You're on a dating app. Someone's profile just caught your eye. Based on what you see, would you want to grab coffee with them?

Their profile:
{PROFILE}

Respond in JSON:
{
  "interested": true/false,
  "reason": "One sentence — why or why not"
}`;

export async function runSpeedPeek(
  agentA: AgentPeekConfig,
  agentB: AgentPeekConfig,
  adapterA: LLMAdapter,
  adapterB: LLMAdapter
): Promise<SpeedPeekResult> {
  // Run both peeks in parallel
  const [responseA, responseB] = await Promise.all([
    peekOne(agentA.systemPrompt, agentB.compressedProfile, adapterA),
    peekOne(agentB.systemPrompt, agentA.compressedProfile, adapterB),
  ]);

  return {
    mutualInterest: responseA.interested && responseB.interested,
    agentAInterested: responseA.interested,
    agentBInterested: responseB.interested,
    agentAReason: responseA.reason,
    agentBReason: responseB.reason,
  };
}

async function peekOne(
  systemPrompt: string,
  otherProfile: string,
  adapter: LLMAdapter
): Promise<{ interested: boolean; reason: string }> {
  const messages: ChatMessage[] = [
    { role: "system", content: systemPrompt },
    { role: "user", content: SPEED_PEEK_PROMPT.replace("{PROFILE}", otherProfile) },
  ];

  const response = await adapter.chat(messages);

  try {
    const parsed = JSON.parse(response.content);
    return {
      interested: parsed.interested === true,
      reason: parsed.reason ?? "No reason given",
    };
  } catch {
    return { interested: false, reason: "Could not parse response" };
  }
}

export function buildCompressedProfile(params: {
  traits: string[];
  interests: string[];
  communication: string;
  hook: string;
}): string {
  return [
    `Personality: ${params.traits.join(", ")}`,
    `Into: ${params.interests.join(", ")}`,
    `Communication style: ${params.communication}`,
    `The hook: ${params.hook}`,
  ].join("\n");
}
```

- [ ] **Step 4: Run tests**

```bash
npx vitest run tests/lib/matching/speed-peek.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/lib/matching/speed-peek.ts tests/lib/matching/speed-peek.test.ts
git commit -m "feat: add speed peek — lightweight mutual interest check before dating"
```

---

## Phase 6: API Routes

### Task 15: Onboarding API Routes

**Files:**
- Create: `agent-date/src/app/api/onboarding/save-key/route.ts`
- Create: `agent-date/src/app/api/onboarding/save-profile/route.ts`
- Create: `agent-date/src/app/api/onboarding/build-agent/route.ts`

- [ ] **Step 1: Implement save API key route**

Create `agent-date/src/app/api/onboarding/save-key/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { encryptApiKey } from "@/lib/crypto";
import type { LLMProvider } from "@/lib/supabase/types";

const VALID_PROVIDERS: LLMProvider[] = ["claude", "openai", "gemini", "mistral", "other"];

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { provider, model, apiKey } = body;

  if (!provider || !model || !apiKey) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  if (!VALID_PROVIDERS.includes(provider)) {
    return NextResponse.json({ error: "Invalid provider" }, { status: 400 });
  }

  const encrypted = encryptApiKey(apiKey);

  const { error } = await supabase.from("api_keys").upsert({
    user_id: user.id,
    provider,
    model,
    encrypted_key: encrypted,
  }, { onConflict: "user_id" });

  if (error) {
    return NextResponse.json({ error: "Failed to save API key" }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
```

- [ ] **Step 2: Implement save profile route**

Create `agent-date/src/app/api/onboarding/save-profile/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const {
    display_name,
    age,
    location,
    quiz_answers,
    interests,
    deal_breakers,
    flirt_style,
    vibe_rating,
  } = body;

  if (!display_name || !quiz_answers || !flirt_style || !vibe_rating) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  const { error } = await supabase.from("profiles").upsert({
    id: user.id,
    display_name,
    age: age ?? null,
    location: location ?? null,
    quiz_answers,
    interests: interests ?? [],
    deal_breakers: deal_breakers ?? [],
    flirt_style,
    vibe_rating,
  }, { onConflict: "id" });

  if (error) {
    return NextResponse.json({ error: "Failed to save profile" }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
```

- [ ] **Step 3: Implement build agent route**

Create `agent-date/src/app/api/onboarding/build-agent/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { buildPersonaSummary, generateAgentTraits } from "@/lib/persona/builder";
import { buildAgentSystemPrompt } from "@/lib/engine/prompts";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Fetch profile
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .single();

  if (profileError || !profile) {
    return NextResponse.json({ error: "Profile not found — complete quiz first" }, { status: 400 });
  }

  const personalitySummary = buildPersonaSummary(profile.quiz_answers, profile.display_name);
  const traits = generateAgentTraits(profile.quiz_answers);

  const systemPrompt = buildAgentSystemPrompt({
    displayName: profile.display_name,
    personalitySummary,
    traits,
    flirtStyle: profile.flirt_style,
    vibeRating: profile.vibe_rating,
    quizAnswers: profile.quiz_answers,
  });

  const { data: agent, error: agentError } = await supabase.from("agents").upsert({
    user_id: user.id,
    system_prompt: systemPrompt,
    traits,
    voice_description: personalitySummary,
  }, { onConflict: "user_id" }).select().single();

  if (agentError) {
    return NextResponse.json({ error: "Failed to build agent" }, { status: 500 });
  }

  return NextResponse.json({
    success: true,
    agent: {
      id: agent.id,
      preview: personalitySummary,
      traits,
    },
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add src/app/api/onboarding/
git commit -m "feat: add onboarding API routes — save key, profile, build agent"
```

---

### Task 16: Matching & Date API Routes

**Files:**
- Create: `agent-date/src/app/api/matching/enter-queue/route.ts`
- Create: `agent-date/src/app/api/date/run/route.ts`
- Create: `agent-date/src/app/api/matching/respond-match/route.ts`
- Create: `agent-date/src/app/api/date/cover-bill/route.ts`

- [ ] **Step 1: Implement enter queue route**

Create `agent-date/src/app/api/matching/enter-queue/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Check agent exists
  const { data: agent } = await supabase
    .from("agents")
    .select("id")
    .eq("user_id", user.id)
    .single();

  if (!agent) {
    return NextResponse.json({ error: "Build your agent first" }, { status: 400 });
  }

  // Check not already in queue
  const { data: existing } = await supabase
    .from("queue")
    .select("id")
    .eq("user_id", user.id)
    .single();

  if (existing) {
    return NextResponse.json({ error: "Already in queue" }, { status: 409 });
  }

  const { error } = await supabase.from("queue").insert({
    user_id: user.id,
    agent_id: agent.id,
    status: "waiting",
  });

  if (error) {
    return NextResponse.json({ error: "Failed to enter queue" }, { status: 500 });
  }

  return NextResponse.json({ success: true, message: "Agent is in the arena" });
}
```

- [ ] **Step 2: Implement date run route**

Create `agent-date/src/app/api/date/run/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { createLLMAdapter } from "@/lib/llm/adapter";
import { decryptApiKey } from "@/lib/crypto";
import { runDate, type DateConfig } from "@/lib/engine/date-runner";
import type { ScenarioConfig } from "@/lib/engine/scenario";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();

  const body = await request.json();
  const { date_id } = body;

  if (!date_id) {
    return NextResponse.json({ error: "Missing date_id" }, { status: 400 });
  }

  // Fetch date with all related data
  const { data: dateRecord } = await supabase
    .from("dates")
    .select("*, agents_a:agents!dates_agent_a_id_fkey(*), agents_b:agents!dates_agent_b_id_fkey(*)")
    .eq("id", date_id)
    .single();

  if (!dateRecord) {
    return NextResponse.json({ error: "Date not found" }, { status: 404 });
  }

  // Fetch API keys for both users
  const { data: keyA } = await supabase
    .from("api_keys")
    .select("*")
    .eq("user_id", dateRecord.user_a_id)
    .single();

  const { data: keyB } = await supabase
    .from("api_keys")
    .select("*")
    .eq("user_id", dateRecord.user_b_id)
    .single();

  if (!keyA || !keyB) {
    return NextResponse.json({ error: "Missing API keys" }, { status: 400 });
  }

  // Fetch vibe rating for scenario selection
  const { data: profileA } = await supabase
    .from("profiles")
    .select("vibe_rating")
    .eq("id", dateRecord.user_a_id)
    .single();

  const vibeRating = profileA?.vibe_rating ?? "r";

  // Fetch 3 scenarios (one per round type, matching vibe)
  const roundTypes = ["casual", "fun", "deep"] as const;
  const scenarios: ScenarioConfig[] = [];

  for (const roundType of roundTypes) {
    const { data: scenarioRows } = await supabase
      .from("scenarios")
      .select("*")
      .eq("round_type", roundType)
      .lte("vibe_rating", vibeRating)
      .limit(10);

    if (!scenarioRows || scenarioRows.length === 0) {
      return NextResponse.json({ error: `No ${roundType} scenarios available` }, { status: 500 });
    }

    // Pick a random scenario
    const picked = scenarioRows[Math.floor(Math.random() * scenarioRows.length)];
    scenarios.push({
      id: picked.id,
      setting: picked.setting,
      mood: picked.mood,
      events: picked.events as string[],
      prompts: picked.prompts as string[],
      target_exchanges: picked.target_exchanges,
    });
  }

  // Create LLM adapters
  const adapterA = createLLMAdapter(
    keyA.provider,
    keyA.model,
    decryptApiKey(keyA.encrypted_key)
  );
  const adapterB = createLLMAdapter(
    keyB.provider,
    keyB.model,
    decryptApiKey(keyB.encrypted_key)
  );

  // Use user A's adapter for judge calls (cost shared via both taking turns)
  const judgeAdapter = adapterA;

  const agentA = dateRecord.agents_a as any;
  const agentB = dateRecord.agents_b as any;

  const config: DateConfig = {
    scenarios: scenarios as [ScenarioConfig, ScenarioConfig, ScenarioConfig],
    agentASystemPrompt: agentA.system_prompt,
    agentBSystemPrompt: agentB.system_prompt,
    vibeRating: vibeRating as any,
  };

  // Run the date
  const result = await runDate(config, adapterA, adapterB, judgeAdapter);

  // Save rounds to database
  for (let i = 0; i < result.rounds.length; i++) {
    const round = result.rounds[i];
    await supabase.from("rounds").insert({
      date_id,
      round_number: (i + 1) as 1 | 2 | 3,
      scenario_id: scenarios[i].id,
      transcript: round.transcript,
      gate_result: result.gateResults[i]?.pass ? "pass" : (result.gateResults[i] ? "fail" : null),
      gate_reasoning: result.gateResults[i]?.reasoning ?? null,
      token_count_a: round.tokenCountA,
      token_count_b: round.tokenCountB,
    });
  }

  // Save judgement if completed
  if (result.judgement) {
    await supabase.from("judgements").insert({
      date_id,
      scores: result.judgement.scores,
      average_score: result.judgement.average,
      second_date: result.judgement.second_date,
      attraction_verdict: result.judgement.attraction_verdict,
      summary: result.judgement.summary,
      mismatch_explanation: result.judgement.mismatch_explanation,
      match_strength: result.judgement.match_strength,
    });

    // Create match if applicable
    if (result.judgement.match_strength) {
      await supabase.from("matches").insert({
        date_id,
        user_a_id: dateRecord.user_a_id,
        user_b_id: dateRecord.user_b_id,
        strength: result.judgement.match_strength,
        reveal_tone: result.judgement.summary,
      });
    }
  }

  // Update date status
  await supabase.from("dates").update({
    status: result.status,
    current_round: result.completedRounds,
    finished_at: new Date().toISOString(),
  }).eq("id", date_id);

  // Remove both from queue
  await supabase.from("queue").delete().eq("user_id", dateRecord.user_a_id);
  await supabase.from("queue").delete().eq("user_id", dateRecord.user_b_id);

  return NextResponse.json({
    success: true,
    status: result.status,
    completedRounds: result.completedRounds,
    matchStrength: result.judgement?.match_strength ?? null,
  });
}
```

- [ ] **Step 3: Implement respond to match route**

Create `agent-date/src/app/api/matching/respond-match/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { match_id, response: userResponse } = body;

  if (!match_id || !["accept", "decline"].includes(userResponse)) {
    return NextResponse.json({ error: "Invalid request" }, { status: 400 });
  }

  const { data: match } = await supabase
    .from("matches")
    .select("*")
    .eq("id", match_id)
    .single();

  if (!match) {
    return NextResponse.json({ error: "Match not found" }, { status: 404 });
  }

  // Determine which user is responding
  const isUserA = match.user_a_id === user.id;
  const isUserB = match.user_b_id === user.id;

  if (!isUserA && !isUserB) {
    return NextResponse.json({ error: "Not your match" }, { status: 403 });
  }

  const updateField = isUserA ? "user_a_response" : "user_b_response";

  await supabase
    .from("matches")
    .update({ [updateField]: userResponse })
    .eq("id", match_id);

  // Check if both have responded
  const { data: updated } = await supabase
    .from("matches")
    .select("*")
    .eq("id", match_id)
    .single();

  if (updated?.user_a_response && updated?.user_b_response) {
    const bothAccepted =
      updated.user_a_response === "accept" && updated.user_b_response === "accept";

    await supabase
      .from("matches")
      .update({ status: bothAccepted ? "accepted" : "declined" })
      .eq("id", match_id);
  }

  return NextResponse.json({ success: true });
}
```

- [ ] **Step 4: Implement cover bill route**

Create `agent-date/src/app/api/date/cover-bill/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { date_id } = body;

  if (!date_id) {
    return NextResponse.json({ error: "Missing date_id" }, { status: 400 });
  }

  // Fetch date to find the other user
  const { data: dateRecord } = await supabase
    .from("dates")
    .select("*")
    .eq("id", date_id)
    .single();

  if (!dateRecord) {
    return NextResponse.json({ error: "Date not found" }, { status: 404 });
  }

  const isUserA = dateRecord.user_a_id === user.id;
  const recipientId = isUserA ? dateRecord.user_b_id : dateRecord.user_a_id;

  // Calculate estimated cost from token counts
  const { data: rounds } = await supabase
    .from("rounds")
    .select("token_count_a, token_count_b")
    .eq("date_id", date_id);

  const totalTokens = (rounds ?? []).reduce((sum, r) => {
    return sum + (isUserA ? r.token_count_b : r.token_count_a);
  }, 0);

  // Rough estimate: $0.003 per 1K tokens
  const estimatedCostCents = Math.ceil((totalTokens / 1000) * 0.3);

  const { error } = await supabase.from("bill_covers").insert({
    date_id,
    payer_id: user.id,
    recipient_id: recipientId,
    amount_cents: estimatedCostCents,
  });

  if (error) {
    return NextResponse.json({ error: "Failed to cover bill" }, { status: 500 });
  }

  return NextResponse.json({
    success: true,
    amount_cents: estimatedCostCents,
    message: "You covered their dinner 🍽️",
  });
}
```

- [ ] **Step 5: Commit**

```bash
git add src/app/api/
git commit -m "feat: add matching and date API routes — queue, run date, respond, cover bill"
```

---

## Phase 7: Frontend Pages

### Task 17: Auth & Layout

**Files:**
- Modify: `agent-date/src/app/layout.tsx`
- Create: `agent-date/src/app/login/page.tsx`

- [ ] **Step 1: Update root layout with dark theme**

Replace contents of `agent-date/src/app/layout.tsx`:

```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AgentDate — Let your AI find love",
  description: "AI agents go on dates so you don't have to",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-[#0a0a1a] text-white antialiased">
        <main className="mx-auto max-w-lg">{children}</main>
      </body>
    </html>
  );
}
```

- [ ] **Step 2: Create login page**

Create `agent-date/src/app/login/page.tsx`:

```tsx
"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/onboarding/api-key` },
    });

    setLoading(false);
    if (!error) setSent(true);
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center px-6">
      <h1 className="mb-2 text-4xl font-bold">AgentDate</h1>
      <p className="mb-8 text-gray-400">Let your AI find love</p>

      {sent ? (
        <div className="rounded-xl bg-white/5 p-6 text-center">
          <p className="text-lg">Check your email ✉️</p>
          <p className="mt-2 text-sm text-gray-400">
            We sent a magic link to {email}
          </p>
        </div>
      ) : (
        <form onSubmit={handleLogin} className="w-full max-w-sm space-y-4">
          <input
            type="email"
            placeholder="your@email.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
          />
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-pink-600 px-4 py-3 font-semibold transition hover:bg-pink-500 disabled:opacity-50"
          >
            {loading ? "Sending..." : "Get Started"}
          </button>
        </form>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add src/app/layout.tsx src/app/login/
git commit -m "feat: add auth layout and magic link login page"
```

---

### Task 18: Onboarding Pages (API Key + Quiz + Preview)

**Files:**
- Create: `agent-date/src/app/onboarding/api-key/page.tsx`
- Create: `agent-date/src/app/onboarding/quiz/page.tsx`
- Create: `agent-date/src/app/onboarding/preview/page.tsx`
- Create: `agent-date/src/components/ApiKeyForm.tsx`
- Create: `agent-date/src/components/QuizForm.tsx`
- Create: `agent-date/src/components/AgentPreview.tsx`

- [ ] **Step 1: Create API key page**

Create `agent-date/src/components/ApiKeyForm.tsx`:

```tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

const PROVIDERS = [
  { id: "claude", name: "Claude (Anthropic)", models: ["claude-sonnet-4-6-20250514", "claude-haiku-4-5-20251001"] },
  { id: "openai", name: "GPT (OpenAI)", models: ["gpt-4o", "gpt-4o-mini"] },
  { id: "gemini", name: "Gemini (Google)", models: ["gemini-2.0-flash", "gemini-2.0-pro"] },
];

export default function ApiKeyForm() {
  const [provider, setProvider] = useState("claude");
  const [model, setModel] = useState("claude-sonnet-4-6-20250514");
  const [apiKey, setApiKey] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const selectedProvider = PROVIDERS.find((p) => p.id === provider);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    const res = await fetch("/api/onboarding/save-key", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ provider, model, apiKey }),
    });

    setLoading(false);
    if (res.ok) router.push("/onboarding/quiz");
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label className="mb-2 block text-sm text-gray-400">Pick your AI</label>
        <div className="grid grid-cols-3 gap-3">
          {PROVIDERS.map((p) => (
            <button
              key={p.id}
              type="button"
              onClick={() => { setProvider(p.id); setModel(p.models[0]); }}
              className={`rounded-xl px-4 py-3 text-sm font-medium transition ${
                provider === p.id
                  ? "bg-pink-600 text-white"
                  : "bg-white/5 text-gray-300 hover:bg-white/10"
              }`}
            >
              {p.name.split(" ")[0]}
            </button>
          ))}
        </div>
      </div>

      <div>
        <label className="mb-2 block text-sm text-gray-400">Model</label>
        <select
          value={model}
          onChange={(e) => setModel(e.target.value)}
          className="w-full rounded-xl bg-white/5 px-4 py-3 text-white outline-none ring-1 ring-white/10"
        >
          {selectedProvider?.models.map((m) => (
            <option key={m} value={m}>{m}</option>
          ))}
        </select>
      </div>

      <div>
        <label className="mb-2 block text-sm text-gray-400">API Key</label>
        <input
          type="password"
          placeholder="sk-..."
          value={apiKey}
          onChange={(e) => setApiKey(e.target.value)}
          required
          className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
        />
        <p className="mt-1 text-xs text-gray-500">
          Encrypted and stored securely. Only used to power your agent's dates.
        </p>
      </div>

      <button
        type="submit"
        disabled={loading || !apiKey}
        className="w-full rounded-xl bg-pink-600 px-4 py-3 font-semibold transition hover:bg-pink-500 disabled:opacity-50"
      >
        {loading ? "Saving..." : "Next →"}
      </button>
    </form>
  );
}
```

Create `agent-date/src/app/onboarding/api-key/page.tsx`:

```tsx
import ApiKeyForm from "@/components/ApiKeyForm";

export default function ApiKeyPage() {
  return (
    <div className="min-h-screen px-6 py-12">
      <h2 className="mb-2 text-2xl font-bold">Connect your AI</h2>
      <p className="mb-8 text-gray-400">Your agent runs on your API key. You control the cost.</p>
      <ApiKeyForm />
    </div>
  );
}
```

- [ ] **Step 2: Create quiz page**

Create `agent-date/src/components/QuizForm.tsx`:

```tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

const FLIRT_STYLES = [
  { id: "subtle", label: "Subtle", desc: "Eye contact and slow build" },
  { id: "playful", label: "Playful", desc: "Teasing and banter" },
  { id: "bold", label: "Bold", desc: "Direct and confident" },
  { id: "shameless", label: "Shameless", desc: "Zero chill, fully self-aware" },
];

const VIBE_RATINGS = [
  { id: "pg13", label: "PG-13", desc: "Light flirting, tasteful" },
  { id: "r", label: "R", desc: "Innuendo, dirty jokes, tension" },
  { id: "unfiltered", label: "Unfiltered", desc: "Full send. No guardrails." },
];

export default function QuizForm() {
  const [step, setStep] = useState(0);
  const [answers, setAnswers] = useState({
    display_name: "",
    age: "",
    humor_style: "",
    communication: "",
    values: [] as string[],
    interests: "",
    ideal_date: "",
    biggest_turnoff: "",
    love_language: "",
    flirt_style: "playful",
    vibe_rating: "r",
  });
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  function update(field: string, value: any) {
    setAnswers((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSubmit() {
    setLoading(true);

    await fetch("/api/onboarding/save-profile", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        display_name: answers.display_name,
        age: answers.age ? parseInt(answers.age) : null,
        quiz_answers: {
          humor_style: answers.humor_style,
          communication: answers.communication,
          values: answers.values,
          interests_detail: answers.interests,
          ideal_date: answers.ideal_date,
          biggest_turnoff: answers.biggest_turnoff,
          love_language: answers.love_language,
        },
        interests: answers.interests.split(",").map((s) => s.trim()).filter(Boolean),
        deal_breakers: answers.biggest_turnoff ? [answers.biggest_turnoff] : [],
        flirt_style: answers.flirt_style,
        vibe_rating: answers.vibe_rating,
      }),
    });

    // Build agent
    await fetch("/api/onboarding/build-agent", { method: "POST" });

    setLoading(false);
    router.push("/onboarding/preview");
  }

  const steps = [
    // Step 0: Name & Age
    <div key="name" className="space-y-4">
      <input
        placeholder="What should your agent call you?"
        value={answers.display_name}
        onChange={(e) => update("display_name", e.target.value)}
        className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
      />
      <input
        type="number"
        placeholder="Age (optional)"
        value={answers.age}
        onChange={(e) => update("age", e.target.value)}
        className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
      />
    </div>,

    // Step 1: Personality
    <div key="personality" className="space-y-4">
      <div>
        <label className="mb-2 block text-sm text-gray-400">Your humor style</label>
        <input
          placeholder="e.g., sarcastic and dry, wholesome, unhinged"
          value={answers.humor_style}
          onChange={(e) => update("humor_style", e.target.value)}
          className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
        />
      </div>
      <div>
        <label className="mb-2 block text-sm text-gray-400">How you communicate</label>
        <input
          placeholder="e.g., direct but warm, rambling storyteller"
          value={answers.communication}
          onChange={(e) => update("communication", e.target.value)}
          className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
        />
      </div>
    </div>,

    // Step 2: Interests & Dating
    <div key="dating" className="space-y-4">
      <div>
        <label className="mb-2 block text-sm text-gray-400">Your interests (comma separated)</label>
        <input
          placeholder="vinyl records, coding, horror movies, cooking"
          value={answers.interests}
          onChange={(e) => update("interests", e.target.value)}
          className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
        />
      </div>
      <div>
        <label className="mb-2 block text-sm text-gray-400">Your ideal date</label>
        <input
          placeholder="e.g., hole-in-the-wall bar that turns into a 4am walk"
          value={answers.ideal_date}
          onChange={(e) => update("ideal_date", e.target.value)}
          className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
        />
      </div>
      <div>
        <label className="mb-2 block text-sm text-gray-400">Biggest turn-off</label>
        <input
          placeholder="e.g., people who are fake nice"
          value={answers.biggest_turnoff}
          onChange={(e) => update("biggest_turnoff", e.target.value)}
          className="w-full rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
        />
      </div>
    </div>,

    // Step 3: Flirt style
    <div key="flirt" className="space-y-4">
      <label className="mb-2 block text-sm text-gray-400">How does your agent flirt?</label>
      <div className="space-y-3">
        {FLIRT_STYLES.map((style) => (
          <button
            key={style.id}
            type="button"
            onClick={() => update("flirt_style", style.id)}
            className={`w-full rounded-xl px-4 py-3 text-left transition ${
              answers.flirt_style === style.id
                ? "bg-pink-600 text-white"
                : "bg-white/5 text-gray-300 hover:bg-white/10"
            }`}
          >
            <span className="font-medium">{style.label}</span>
            <span className="ml-2 text-sm opacity-70">— {style.desc}</span>
          </button>
        ))}
      </div>
    </div>,

    // Step 4: Vibe rating
    <div key="vibe" className="space-y-4">
      <label className="mb-2 block text-sm text-gray-400">How spicy should your dates get?</label>
      <div className="space-y-3">
        {VIBE_RATINGS.map((vibe) => (
          <button
            key={vibe.id}
            type="button"
            onClick={() => update("vibe_rating", vibe.id)}
            className={`w-full rounded-xl px-4 py-3 text-left transition ${
              answers.vibe_rating === vibe.id
                ? "bg-pink-600 text-white"
                : "bg-white/5 text-gray-300 hover:bg-white/10"
            }`}
          >
            <span className="font-medium">{vibe.label}</span>
            <span className="ml-2 text-sm opacity-70">— {vibe.desc}</span>
          </button>
        ))}
      </div>
    </div>,
  ];

  const isLastStep = step === steps.length - 1;

  return (
    <div>
      <div className="mb-6 flex gap-1">
        {steps.map((_, i) => (
          <div
            key={i}
            className={`h-1 flex-1 rounded-full ${
              i <= step ? "bg-pink-500" : "bg-white/10"
            }`}
          />
        ))}
      </div>

      {steps[step]}

      <div className="mt-8 flex gap-3">
        {step > 0 && (
          <button
            onClick={() => setStep(step - 1)}
            className="rounded-xl bg-white/5 px-6 py-3 transition hover:bg-white/10"
          >
            Back
          </button>
        )}
        <button
          onClick={isLastStep ? handleSubmit : () => setStep(step + 1)}
          disabled={loading || (step === 0 && !answers.display_name)}
          className="flex-1 rounded-xl bg-pink-600 px-4 py-3 font-semibold transition hover:bg-pink-500 disabled:opacity-50"
        >
          {loading ? "Building your agent..." : isLastStep ? "Build My Agent" : "Next →"}
        </button>
      </div>
    </div>
  );
}
```

Create `agent-date/src/app/onboarding/quiz/page.tsx`:

```tsx
import QuizForm from "@/components/QuizForm";

export default function QuizPage() {
  return (
    <div className="min-h-screen px-6 py-12">
      <h2 className="mb-2 text-2xl font-bold">Build your agent's personality</h2>
      <p className="mb-8 text-gray-400">The more honest you are, the better your agent represents you.</p>
      <QuizForm />
    </div>
  );
}
```

- [ ] **Step 3: Create agent preview page**

Create `agent-date/src/components/AgentPreview.tsx`:

```tsx
"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

export default function AgentPreview() {
  const [agent, setAgent] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    async function fetchAgent() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data } = await supabase
        .from("agents")
        .select("*, profiles(*)")
        .eq("user_id", user.id)
        .single();

      setAgent(data);
      setLoading(false);
    }
    fetchAgent();
  }, []);

  async function enterArena() {
    setLoading(true);
    await fetch("/api/matching/enter-queue", { method: "POST" });
    router.push("/dashboard");
  }

  if (loading) {
    return <div className="py-20 text-center text-gray-400">Loading your agent...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="rounded-2xl bg-white/5 p-6">
        <div className="mb-4 flex items-center gap-4">
          <div className="flex h-14 w-14 items-center justify-content-center rounded-full bg-pink-600 text-2xl font-bold">
            {agent?.profiles?.display_name?.[0] ?? "?"}
          </div>
          <div>
            <h3 className="text-lg font-bold">{agent?.profiles?.display_name}'s Agent</h3>
            <p className="text-sm text-gray-400">Powered by {agent?.profiles?.api_keys?.provider ?? "AI"}</p>
          </div>
        </div>

        <p className="text-sm leading-relaxed text-gray-300">
          {agent?.voice_description}
        </p>

        <div className="mt-4 flex flex-wrap gap-2">
          {Object.entries(agent?.traits ?? {}).map(([key, value]) => (
            <span
              key={key}
              className="rounded-full bg-white/10 px-3 py-1 text-xs text-gray-300"
            >
              {key}: {String(value)}
            </span>
          ))}
        </div>
      </div>

      <button
        onClick={enterArena}
        disabled={loading}
        className="w-full rounded-xl bg-pink-600 px-4 py-4 text-lg font-bold transition hover:bg-pink-500 disabled:opacity-50"
      >
        Enter the Arena 🏟️
      </button>
    </div>
  );
}
```

Create `agent-date/src/app/onboarding/preview/page.tsx`:

```tsx
import AgentPreview from "@/components/AgentPreview";

export default function PreviewPage() {
  return (
    <div className="min-h-screen px-6 py-12">
      <h2 className="mb-2 text-2xl font-bold">Meet your agent</h2>
      <p className="mb-8 text-gray-400">This is how your agent will represent you on dates.</p>
      <AgentPreview />
    </div>
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add src/app/onboarding/ src/components/
git commit -m "feat: add onboarding pages — API key, personality quiz, agent preview"
```

---

### Task 19: Dashboard Page

**Files:**
- Create: `agent-date/src/app/dashboard/page.tsx`
- Create: `agent-date/src/components/DashboardCard.tsx`
- Create: `agent-date/src/components/DateProgress.tsx`

- [ ] **Step 1: Create dashboard components and page**

Create `agent-date/src/components/DateProgress.tsx`:

```tsx
export default function DateProgress({ currentRound, status }: { currentRound: number; status: string }) {
  const rounds = ["Casual", "Fun", "Deep"];

  return (
    <div className="flex gap-2">
      {rounds.map((label, i) => (
        <div key={label} className="flex-1">
          <div
            className={`h-1.5 rounded-full ${
              i < currentRound
                ? "bg-green-500"
                : i === currentRound - 1 && status === "in_progress"
                ? "animate-pulse bg-pink-500"
                : "bg-white/10"
            }`}
          />
          <p className="mt-1 text-center text-xs text-gray-500">{label}</p>
        </div>
      ))}
    </div>
  );
}
```

Create `agent-date/src/components/DashboardCard.tsx`:

```tsx
import DateProgress from "./DateProgress";

type Props = {
  activeDate: any | null;
  stats: { dates: number; matches: number; totalCost: number };
  recentMatches: any[];
};

export default function DashboardCard({ activeDate, stats, recentMatches }: Props) {
  return (
    <div className="space-y-6">
      {/* Agent Status */}
      <div className="rounded-2xl bg-white/5 p-6">
        {activeDate ? (
          <div>
            <p className="text-sm text-gray-400">Your Agent</p>
            <p className="mt-1 text-xl font-bold">Currently on a date...</p>
            <p className="text-sm text-gray-400">
              Round {activeDate.current_round} of 3
            </p>
            <div className="mt-4">
              <DateProgress
                currentRound={activeDate.current_round}
                status={activeDate.status}
              />
            </div>
          </div>
        ) : (
          <div>
            <p className="text-sm text-gray-400">Your Agent</p>
            <p className="mt-1 text-xl font-bold">Waiting in the arena...</p>
            <p className="text-sm text-gray-400">Looking for a date</p>
          </div>
        )}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-xl bg-white/5 p-4 text-center">
          <p className="text-2xl font-bold">{stats.dates}</p>
          <p className="text-xs text-gray-500">Dates</p>
        </div>
        <div className="rounded-xl bg-white/5 p-4 text-center">
          <p className="text-2xl font-bold">{stats.matches}</p>
          <p className="text-xs text-gray-500">Matches</p>
        </div>
        <div className="rounded-xl bg-white/5 p-4 text-center">
          <p className="text-2xl font-bold">${stats.totalCost.toFixed(2)}</p>
          <p className="text-xs text-gray-500">API Cost</p>
        </div>
      </div>

      {/* Recent Matches */}
      {recentMatches.length > 0 && (
        <div>
          <h3 className="mb-3 font-semibold">Recent Matches</h3>
          <div className="space-y-3">
            {recentMatches.map((match) => (
              <a
                key={match.id}
                href={`/matches/${match.id}`}
                className="block rounded-xl bg-white/5 p-4 transition hover:bg-white/10"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{match.other_name}</p>
                    <p className="text-sm text-gray-400">{match.reveal_tone}</p>
                  </div>
                  <span
                    className={`rounded-full px-2 py-1 text-xs font-bold ${
                      match.strength === "3/3"
                        ? "bg-green-500/20 text-green-400"
                        : "bg-yellow-500/20 text-yellow-400"
                    }`}
                  >
                    {match.strength}
                  </span>
                </div>
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
```

Create `agent-date/src/app/dashboard/page.tsx`:

```tsx
import { createServerSupabase } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import DashboardCard from "@/components/DashboardCard";

export default async function DashboardPage() {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  // Fetch active date
  const { data: activeDate } = await supabase
    .from("dates")
    .select("*")
    .or(`user_a_id.eq.${user.id},user_b_id.eq.${user.id}`)
    .eq("status", "in_progress")
    .single();

  // Fetch stats
  const { count: dateCount } = await supabase
    .from("dates")
    .select("*", { count: "exact", head: true })
    .or(`user_a_id.eq.${user.id},user_b_id.eq.${user.id}`);

  const { count: matchCount } = await supabase
    .from("matches")
    .select("*", { count: "exact", head: true })
    .or(`user_a_id.eq.${user.id},user_b_id.eq.${user.id}`)
    .eq("status", "accepted");

  // Fetch recent matches
  const { data: matches } = await supabase
    .from("matches")
    .select("*, profiles_a:profiles!matches_user_a_id_fkey(display_name), profiles_b:profiles!matches_user_b_id_fkey(display_name)")
    .or(`user_a_id.eq.${user.id},user_b_id.eq.${user.id}`)
    .order("created_at", { ascending: false })
    .limit(5);

  const recentMatches = (matches ?? []).map((m) => ({
    id: m.id,
    strength: m.strength,
    reveal_tone: m.reveal_tone,
    other_name:
      m.user_a_id === user.id
        ? (m.profiles_b as any)?.display_name
        : (m.profiles_a as any)?.display_name,
  }));

  return (
    <div className="min-h-screen px-6 py-8">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">AgentDate</h1>
      </div>
      <DashboardCard
        activeDate={activeDate}
        stats={{ dates: dateCount ?? 0, matches: matchCount ?? 0, totalCost: 0 }}
        recentMatches={recentMatches}
      />
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/app/dashboard/ src/components/DashboardCard.tsx src/components/DateProgress.tsx
git commit -m "feat: add dashboard page with agent status, stats, and recent matches"
```

---

### Task 20: Match Reveal & Transcript Pages

**Files:**
- Create: `agent-date/src/app/matches/[id]/page.tsx`
- Create: `agent-date/src/app/transcript/[dateId]/page.tsx`
- Create: `agent-date/src/components/MatchReveal.tsx`
- Create: `agent-date/src/components/TranscriptView.tsx`

- [ ] **Step 1: Create match reveal component**

Create `agent-date/src/components/MatchReveal.tsx`:

```tsx
"use client";

import { useState } from "react";
import type { JudgeScores } from "@/lib/supabase/types";

type Props = {
  matchId: string;
  strength: "3/3" | "2/3";
  summary: string;
  mismatchExplanation: string | null;
  attractionVerdict: "yes" | "slow_burn" | "nah";
  scores: JudgeScores;
  roundHighlights: { round: string; highlight: string }[];
  dateId: string;
  otherName: string;
  needsResponse: boolean;
};

const ATTRACTION_LABELS = {
  yes: "Your agents couldn't keep their hands off each other",
  slow_burn: "Something special brewing — slow and electric",
  nah: "Deep connection, best friend energy",
};

export default function MatchReveal(props: Props) {
  const [responding, setResponding] = useState(false);

  async function respond(response: "accept" | "decline") {
    setResponding(true);
    await fetch("/api/matching/respond-match", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ match_id: props.matchId, response }),
    });
    setResponding(false);
    window.location.reload();
  }

  async function coverBill() {
    await fetch("/api/date/cover-bill", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ date_id: props.dateId }),
    });
    alert("You covered their dinner! 🍽️");
  }

  const isFullMatch = props.strength === "3/3";

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center">
        <p className="text-5xl">{isFullMatch ? "💚" : "💛"}</p>
        <h2 className="mt-3 text-3xl font-bold">
          {isFullMatch ? "It's a Match!" : "Almost a Match"}
        </h2>
        <p className="mt-1 text-gray-400">
          {ATTRACTION_LABELS[props.attractionVerdict]}
        </p>
      </div>

      {/* Round Highlights */}
      <div className="rounded-2xl bg-white/5 p-5">
        <h3 className="mb-4 text-sm font-semibold uppercase text-gray-400">Date Highlights</h3>
        <div className="space-y-4">
          {props.roundHighlights.map((h) => (
            <div key={h.round}>
              <p className="text-xs text-pink-400">{h.round}</p>
              <p className="mt-1 text-sm italic text-gray-300">"{h.highlight}"</p>
            </div>
          ))}
        </div>
      </div>

      {/* Mismatch explanation for partial */}
      {!isFullMatch && props.mismatchExplanation && (
        <div className="rounded-2xl border border-yellow-500/30 bg-yellow-500/10 p-5">
          <h3 className="mb-2 text-sm font-semibold text-yellow-400">Where it diverged</h3>
          <p className="text-sm text-gray-300">{props.mismatchExplanation}</p>
        </div>
      )}

      {/* Actions */}
      {props.needsResponse && !isFullMatch ? (
        <div className="flex gap-3">
          <button
            onClick={() => respond("accept")}
            disabled={responding}
            className="flex-1 rounded-xl bg-yellow-500 px-4 py-3 font-semibold text-black transition hover:bg-yellow-400"
          >
            Want to try anyway? 🤷
          </button>
          <button
            onClick={() => respond("decline")}
            disabled={responding}
            className="rounded-xl bg-white/5 px-6 py-3 transition hover:bg-white/10"
          >
            Pass
          </button>
        </div>
      ) : isFullMatch ? (
        <div className="flex gap-3">
          <a
            href={`/chat/${props.matchId}`}
            className="flex-1 rounded-xl bg-pink-600 px-4 py-3 text-center font-semibold transition hover:bg-pink-500"
          >
            Start Chatting 💬
          </a>
          <button
            onClick={coverBill}
            className="rounded-xl bg-white/5 px-4 py-3 transition hover:bg-white/10"
          >
            Cover Their Bill 🍽️
          </button>
        </div>
      ) : null}

      {/* Transcript link */}
      <a
        href={`/transcript/${props.dateId}`}
        className="block text-center text-sm text-gray-400 underline"
      >
        Read full date transcript →
      </a>
    </div>
  );
}
```

Create `agent-date/src/app/matches/[id]/page.tsx`:

```tsx
import { createServerSupabase } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import MatchReveal from "@/components/MatchReveal";

export default async function MatchPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: match } = await supabase
    .from("matches")
    .select("*, profiles_a:profiles!matches_user_a_id_fkey(display_name), profiles_b:profiles!matches_user_b_id_fkey(display_name)")
    .eq("id", id)
    .single();

  if (!match) redirect("/dashboard");

  const { data: judgement } = await supabase
    .from("judgements")
    .select("*")
    .eq("date_id", match.date_id)
    .single();

  const { data: rounds } = await supabase
    .from("rounds")
    .select("round_number, transcript, scenario_id")
    .eq("date_id", match.date_id)
    .order("round_number");

  const roundLabels = ["☕ Round 1 — Casual", "🎤 Round 2 — Fun", "🌙 Round 3 — Deep"];
  const roundHighlights = (rounds ?? []).map((r, i) => ({
    round: roundLabels[i] ?? `Round ${r.round_number}`,
    highlight: judgement?.summary ?? "A memorable conversation",
  }));

  const isUserA = match.user_a_id === user.id;
  const otherName = isUserA
    ? (match.profiles_b as any)?.display_name
    : (match.profiles_a as any)?.display_name;

  const needsResponse =
    match.strength === "2/3" &&
    ((isUserA && !match.user_a_response) || (!isUserA && !match.user_b_response));

  return (
    <div className="min-h-screen px-6 py-12">
      <MatchReveal
        matchId={match.id}
        strength={match.strength}
        summary={judgement?.summary ?? ""}
        mismatchExplanation={judgement?.mismatch_explanation ?? null}
        attractionVerdict={judgement?.attraction_verdict ?? "nah"}
        scores={judgement?.scores ?? { banter: 0, flow: 0, depth: 0, energy: 0, values: 0, play: 0, sexual_chemistry: 0 }}
        roundHighlights={roundHighlights}
        dateId={match.date_id}
        otherName={otherName}
        needsResponse={needsResponse}
      />
    </div>
  );
}
```

- [ ] **Step 2: Create transcript view**

Create `agent-date/src/components/TranscriptView.tsx`:

```tsx
import type { TranscriptMessage } from "@/lib/supabase/types";

type Props = {
  rounds: {
    roundNumber: number;
    scenarioId: string;
    transcript: TranscriptMessage[];
  }[];
};

const ROUND_LABELS = ["☕ Casual", "🎤 Fun", "🌙 Deep"];

export default function TranscriptView({ rounds }: Props) {
  return (
    <div className="space-y-8">
      {rounds.map((round) => (
        <div key={round.roundNumber}>
          <h3 className="mb-4 text-lg font-bold">
            {ROUND_LABELS[round.roundNumber - 1]} — {round.scenarioId.replace(/-/g, " ")}
          </h3>
          <div className="space-y-3">
            {round.transcript.map((msg, i) => {
              if (msg.role === "narrator") {
                return (
                  <p key={i} className="text-center text-sm italic text-gray-500">
                    [{msg.content}]
                  </p>
                );
              }
              const isA = msg.role === "agent_a";
              return (
                <div
                  key={i}
                  className={`flex ${isA ? "justify-start" : "justify-end"}`}
                >
                  <div
                    className={`max-w-[80%] rounded-2xl px-4 py-3 text-sm ${
                      isA
                        ? "bg-white/5 text-gray-200"
                        : "bg-pink-600/20 text-gray-200"
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}
```

Create `agent-date/src/app/transcript/[dateId]/page.tsx`:

```tsx
import { createServerSupabase } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import TranscriptView from "@/components/TranscriptView";

export default async function TranscriptPage({ params }: { params: Promise<{ dateId: string }> }) {
  const { dateId } = await params;
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: rounds } = await supabase
    .from("rounds")
    .select("*")
    .eq("date_id", dateId)
    .order("round_number");

  if (!rounds || rounds.length === 0) redirect("/dashboard");

  const formattedRounds = rounds.map((r) => ({
    roundNumber: r.round_number,
    scenarioId: r.scenario_id,
    transcript: r.transcript as any[],
  }));

  return (
    <div className="min-h-screen px-6 py-8">
      <a href="/dashboard" className="mb-6 block text-sm text-gray-400">← Back</a>
      <h2 className="mb-6 text-2xl font-bold">Date Transcript</h2>
      <TranscriptView rounds={formattedRounds} />
    </div>
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add src/app/matches/ src/app/transcript/ src/components/MatchReveal.tsx src/components/TranscriptView.tsx
git commit -m "feat: add match reveal and transcript pages"
```

---

### Task 21: Direct Chat Page

**Files:**
- Create: `agent-date/src/app/chat/[matchId]/page.tsx`
- Create: `agent-date/src/components/ChatWindow.tsx`
- Create: `agent-date/src/app/api/chat/send/route.ts`

- [ ] **Step 1: Create chat API route**

Create `agent-date/src/app/api/chat/send/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { match_id, content } = await request.json();

  if (!match_id || !content?.trim()) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  // Verify user is part of this match
  const { data: match } = await supabase
    .from("matches")
    .select("*")
    .eq("id", match_id)
    .eq("status", "accepted")
    .single();

  if (!match || (match.user_a_id !== user.id && match.user_b_id !== user.id)) {
    return NextResponse.json({ error: "Not authorized" }, { status: 403 });
  }

  const { error } = await supabase.from("messages").insert({
    match_id,
    sender_id: user.id,
    content: content.trim(),
  });

  if (error) {
    return NextResponse.json({ error: "Failed to send" }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
```

- [ ] **Step 2: Create chat window component**

Create `agent-date/src/components/ChatWindow.tsx`:

```tsx
"use client";

import { useEffect, useState, useRef } from "react";
import { createClient } from "@/lib/supabase/client";

type Message = {
  id: string;
  sender_id: string;
  content: string;
  created_at: string;
};

type Props = {
  matchId: string;
  userId: string;
  otherName: string;
  icebreaker: string | null;
};

export default function ChatWindow({ matchId, userId, otherName, icebreaker }: Props) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const supabase = createClient();

  useEffect(() => {
    // Fetch existing messages
    async function load() {
      const { data } = await supabase
        .from("messages")
        .select("*")
        .eq("match_id", matchId)
        .order("created_at");
      setMessages(data ?? []);
    }
    load();

    // Subscribe to new messages
    const channel = supabase
      .channel(`chat:${matchId}`)
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "messages", filter: `match_id=eq.${matchId}` },
        (payload) => {
          setMessages((prev) => [...prev, payload.new as Message]);
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [matchId]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    if (!input.trim() || sending) return;

    setSending(true);
    await fetch("/api/chat/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ match_id: matchId, content: input }),
    });
    setInput("");
    setSending(false);
  }

  return (
    <div className="flex h-screen flex-col">
      {/* Header */}
      <div className="border-b border-white/10 px-6 py-4">
        <h2 className="font-bold">{otherName}</h2>
      </div>

      {/* Icebreaker */}
      {icebreaker && messages.length === 0 && (
        <div className="mx-6 mt-4 rounded-xl bg-pink-600/10 p-4 text-center text-sm text-gray-300">
          <p className="mb-1 text-xs text-pink-400">From your date transcript:</p>
          <p className="italic">"{icebreaker}"</p>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-6 py-4">
        <div className="space-y-3">
          {messages.map((msg) => {
            const isMine = msg.sender_id === userId;
            return (
              <div key={msg.id} className={`flex ${isMine ? "justify-end" : "justify-start"}`}>
                <div
                  className={`max-w-[75%] rounded-2xl px-4 py-2 text-sm ${
                    isMine ? "bg-pink-600 text-white" : "bg-white/10 text-gray-200"
                  }`}
                >
                  {msg.content}
                </div>
              </div>
            );
          })}
          <div ref={bottomRef} />
        </div>
      </div>

      {/* Input */}
      <form onSubmit={send} className="border-t border-white/10 px-6 py-4">
        <div className="flex gap-3">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Type a message..."
            className="flex-1 rounded-xl bg-white/5 px-4 py-3 text-white placeholder-gray-500 outline-none ring-1 ring-white/10 focus:ring-pink-500"
          />
          <button
            type="submit"
            disabled={sending || !input.trim()}
            className="rounded-xl bg-pink-600 px-6 py-3 font-semibold transition hover:bg-pink-500 disabled:opacity-50"
          >
            Send
          </button>
        </div>
      </form>
    </div>
  );
}
```

Create `agent-date/src/app/chat/[matchId]/page.tsx`:

```tsx
import { createServerSupabase } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import ChatWindow from "@/components/ChatWindow";

export default async function ChatPage({ params }: { params: Promise<{ matchId: string }> }) {
  const { matchId } = await params;
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: match } = await supabase
    .from("matches")
    .select("*, profiles_a:profiles!matches_user_a_id_fkey(display_name), profiles_b:profiles!matches_user_b_id_fkey(display_name)")
    .eq("id", matchId)
    .eq("status", "accepted")
    .single();

  if (!match) redirect("/dashboard");

  const isUserA = match.user_a_id === user.id;
  const otherName = isUserA
    ? (match.profiles_b as any)?.display_name
    : (match.profiles_a as any)?.display_name;

  // Get icebreaker from judgement
  const { data: judgement } = await supabase
    .from("judgements")
    .select("summary")
    .eq("date_id", match.date_id)
    .single();

  return (
    <ChatWindow
      matchId={matchId}
      userId={user.id}
      otherName={otherName}
      icebreaker={judgement?.summary ?? null}
    />
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add src/app/chat/ src/app/api/chat/ src/components/ChatWindow.tsx
git commit -m "feat: add real-time direct chat with icebreaker from date transcript"
```

---

## Phase 8: Landing Page & Final Integration

### Task 22: Landing Page

**Files:**
- Modify: `agent-date/src/app/page.tsx`

- [ ] **Step 1: Create landing page**

Replace `agent-date/src/app/page.tsx`:

```tsx
import Link from "next/link";

export default function LandingPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center px-6 text-center">
      <h1 className="text-5xl font-bold leading-tight">
        Your AI agent
        <br />
        <span className="text-pink-500">goes on dates</span>
        <br />
        so you don't have to
      </h1>

      <p className="mt-6 max-w-md text-lg text-gray-400">
        Connect your API key. Build your agent's personality. Watch it flirt,
        joke, and find your match through 3 rounds of virtual dates.
      </p>

      <div className="mt-8 flex flex-col gap-4 sm:flex-row">
        <Link
          href="/login"
          className="rounded-xl bg-pink-600 px-8 py-4 text-lg font-bold transition hover:bg-pink-500"
        >
          Enter the Arena
        </Link>
      </div>

      <div className="mt-16 grid max-w-lg gap-6 text-left">
        <div className="rounded-xl bg-white/5 p-5">
          <h3 className="font-bold">1. Build your agent</h3>
          <p className="mt-1 text-sm text-gray-400">
            Personality quiz + your API key. Your agent talks like you, flirts
            like you, has your opinions.
          </p>
        </div>
        <div className="rounded-xl bg-white/5 p-5">
          <h3 className="font-bold">2. Agents go on dates</h3>
          <p className="mt-1 text-sm text-gray-400">
            3 rounds: casual, fun, deep. Scenario-driven with real story beats.
            Coffee shops, karaoke, late night walks.
          </p>
        </div>
        <div className="rounded-xl bg-white/5 p-5">
          <h3 className="font-bold">3. Read the transcript</h3>
          <p className="mt-1 text-sm text-gray-400">
            If your agents would go on a second date, it's a match. Read how
            they clicked (or didn't). Share the highlights.
          </p>
        </div>
      </div>

      <p className="mt-12 text-sm text-gray-500">
        BYOA — Bring Your Own Agent. You bring the AI, we bring the arena.
        <br />
        ~$0.05 per date. Cheaper than coffee.
      </p>
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/app/page.tsx
git commit -m "feat: add landing page"
```

---

### Task 23: Seed Scenarios to Database

**Files:**
- Create: `agent-date/supabase/migrations/004_scenario_seed.sql`

- [ ] **Step 1: Write seed migration**

Create `agent-date/supabase/migrations/004_scenario_seed.sql`:

```sql
insert into public.scenarios (id, round_type, vibe_rating, setting, mood, events, prompts, target_exchanges) values
('coffee-shop', 'casual', 'pg13',
 'A cozy independent coffee shop on a Saturday afternoon. Exposed brick, jazz playing softly, the barista clearly knows everyone.',
 'warm, relaxed, curious',
 '["Both reach for the last chocolate croissant at the counter at the same time", "The barista makes a comment about you two looking like a cute couple", "A song comes on that one of you clearly loves"]'::jsonb,
 '["So what do you do when you''re not letting AI go on dates for you?", "What''s the most spontaneous thing you''ve ever done?"]'::jsonb,
 10),

('rooftop-bar', 'casual', 'r',
 'A rooftop bar at sunset. City skyline glowing orange and pink. Cocktails, warm breeze, string lights overhead.',
 'flirty, electric, golden hour energy',
 '["The wind picks up and blows a napkin — one of you catches it mid-air", "You accidentally make eye contact for a beat too long", "A couple at the next table starts making out — you both notice"]'::jsonb,
 '["What''s your go-to drink when you''re trying to impress someone?", "Be honest — what''s your worst habit?"]'::jsonb,
 10),

('karaoke-drinks', 'fun', 'r',
 'A private karaoke room with neon lights, a sticky mic, and a cocktail menu that''s too long.',
 'loud, uninhibited, competitive, flirty',
 '["One of you picks an absolutely unhinged song choice", "You attempt a duet and it goes spectacularly wrong", "After a few drinks, one dedicates the next song to the other"]'::jsonb,
 '["What''s your shower song? No judgement.", "If you had to seduce someone with one song, what would it be?"]'::jsonb,
 10),

('truth-or-dare', 'fun', 'unfiltered',
 'Someone''s apartment, late. Half-empty wine bottles, fairy lights, sitting on the floor. Truth or dare started as a joke and got real fast.',
 'intimate, daring, zero filter, charged',
 '["Truth: What''s the most attracted you''ve ever been to someone you just met?", "Dare: Say the most flirtatious thing you can think of right now, dead serious", "Truth: What are you thinking about right now? Be completely honest."]'::jsonb,
 '["Your turn — truth or dare?", "Okay that was bold. Top that."]'::jsonb,
 10),

('late-night-bar', 'deep', 'r',
 'A dimly lit bar, nearly empty. It''s 1am. The bartender is wiping glasses and pretending not to listen.',
 'intimate, honest, vulnerable, magnetic',
 '["The bartender announces last call. Neither of you moves.", "One of you says something unexpectedly vulnerable", "Your knees have been touching under the bar for 10 minutes and nobody moved"]'::jsonb,
 '["What''s the thing you never tell people on a first date but probably should?", "Do you think you''re easy to love?"]'::jsonb,
 12),

('walk-home', 'deep', 'unfiltered',
 'Walking home together at 2am. Empty streets, streetlights, that weird clarity that only happens late at night with someone you might actually like.',
 'raw, honest, electric, the moment before something happens',
 '["You reach an intersection — left to their place, right to yours. You both stop.", "One of you says I don''t want this night to end and means it", "It starts raining lightly. Neither of you cares."]'::jsonb,
 '["If tonight was the last night on earth, would you change anything about how it''s going?", "What happens next?"]'::jsonb,
 12)

on conflict (id) do nothing;
```

- [ ] **Step 2: Apply migration**

```bash
supabase db push
```

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/004_scenario_seed.sql
git commit -m "feat: seed 6 scenario templates — casual, fun, deep across vibe ratings"
```

---

### Task 24: Matchmaking Queue Processor

**Files:**
- Create: `agent-date/src/app/api/matching/process-queue/route.ts`

This is the cron job / edge function that finds pairs and kicks off dates.

- [ ] **Step 1: Implement queue processor**

Create `agent-date/src/app/api/matching/process-queue/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { isCompatible, scoreCompatibility, type ProfileForMatching } from "@/lib/matching/profile-filter";
import { runSpeedPeek, buildCompressedProfile } from "@/lib/matching/speed-peek";
import { createLLMAdapter } from "@/lib/llm/adapter";
import { decryptApiKey } from "@/lib/crypto";

export async function POST(request: NextRequest) {
  const supabase = await createServerSupabase();

  // Fetch all waiting agents with profiles and keys
  const { data: queueEntries } = await supabase
    .from("queue")
    .select("*, profiles(*), agents(*), api_keys:api_keys(*)")
    .eq("status", "waiting")
    .order("entered_at");

  if (!queueEntries || queueEntries.length < 2) {
    return NextResponse.json({ message: "Not enough agents in queue", count: queueEntries?.length ?? 0 });
  }

  let matched = 0;

  // Try to pair agents
  for (let i = 0; i < queueEntries.length - 1; i++) {
    const entryA = queueEntries[i];
    if (entryA.status !== "waiting") continue;

    const profileA: ProfileForMatching = {
      id: (entryA.profiles as any).id,
      age: (entryA.profiles as any).age,
      interests: (entryA.profiles as any).interests,
      deal_breakers: (entryA.profiles as any).deal_breakers,
      vibe_rating: (entryA.profiles as any).vibe_rating,
      location: (entryA.profiles as any).location,
    };

    let bestMatch: { entry: any; score: number } | null = null;

    for (let j = i + 1; j < queueEntries.length; j++) {
      const entryB = queueEntries[j];
      if (entryB.status !== "waiting") continue;

      const profileB: ProfileForMatching = {
        id: (entryB.profiles as any).id,
        age: (entryB.profiles as any).age,
        interests: (entryB.profiles as any).interests,
        deal_breakers: (entryB.profiles as any).deal_breakers,
        vibe_rating: (entryB.profiles as any).vibe_rating,
        location: (entryB.profiles as any).location,
      };

      if (!isCompatible(profileA, profileB)) continue;

      const score = scoreCompatibility(profileA, profileB);
      if (!bestMatch || score > bestMatch.score) {
        bestMatch = { entry: entryB, score };
      }
    }

    if (!bestMatch) continue;

    const entryB = bestMatch.entry;

    // Speed peek
    const keyA = entryA.api_keys as any;
    const keyB = entryB.api_keys as any;

    if (!keyA || !keyB) continue;

    const adapterA = createLLMAdapter(keyA.provider, keyA.model, decryptApiKey(keyA.encrypted_key));
    const adapterB = createLLMAdapter(keyB.provider, keyB.model, decryptApiKey(keyB.encrypted_key));

    const agentA = entryA.agents as any;
    const agentB = entryB.agents as any;

    const peekResult = await runSpeedPeek(
      {
        systemPrompt: agentA.system_prompt,
        compressedProfile: buildCompressedProfile({
          traits: Object.values(agentB.traits as Record<string, string>),
          interests: (entryB.profiles as any).interests,
          communication: (agentB.traits as any).communication ?? "balanced",
          hook: (agentB.traits as any).interests ?? "curious person",
        }),
      },
      {
        systemPrompt: agentB.system_prompt,
        compressedProfile: buildCompressedProfile({
          traits: Object.values(agentA.traits as Record<string, string>),
          interests: (entryA.profiles as any).interests,
          communication: (agentA.traits as any).communication ?? "balanced",
          hook: (agentA.traits as any).interests ?? "curious person",
        }),
      },
      adapterA,
      adapterB
    );

    if (!peekResult.mutualInterest) continue;

    // Create date record
    const { data: dateRecord } = await supabase
      .from("dates")
      .insert({
        agent_a_id: agentA.id,
        agent_b_id: agentB.id,
        user_a_id: entryA.user_id,
        user_b_id: entryB.user_id,
      })
      .select()
      .single();

    if (!dateRecord) continue;

    // Mark both as dating
    await supabase.from("queue").update({ status: "dating" }).eq("id", entryA.id);
    await supabase.from("queue").update({ status: "dating" }).eq("id", entryB.id);
    entryA.status = "dating";
    entryB.status = "dating";

    // Trigger date execution (fire and forget)
    fetch(`${process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000"}/api/date/run`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ date_id: dateRecord.id }),
    }).catch(() => {});

    matched++;
  }

  return NextResponse.json({ matched, total_in_queue: queueEntries.length });
}
```

- [ ] **Step 2: Commit**

```bash
git add src/app/api/matching/process-queue/
git commit -m "feat: add queue processor — profile filter, speed peek, date scheduling"
```

---

### Task 25: Verify Build & Run

- [ ] **Step 1: Run all tests**

```bash
cd ~/Vs\ Code/First\ Project/agent-date
npm test
```

Expected: All tests pass

- [ ] **Step 2: Run type check**

```bash
npx tsc --noEmit
```

Expected: No type errors (or fix any that come up)

- [ ] **Step 3: Run dev server and verify pages load**

```bash
npm run dev
```

Visit:
- http://localhost:3000 — landing page
- http://localhost:3000/login — login page
- http://localhost:3000/onboarding/api-key — API key page
- http://localhost:3000/onboarding/quiz — quiz page
- http://localhost:3000/dashboard — dashboard (needs auth)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: verify build — all tests pass, all pages load"
```

---

## Summary

**8 phases, 25 tasks:**

| Phase | Tasks | What it builds |
|-------|-------|----------------|
| 1. Setup & DB | 1-4 | Scaffold, migrations, Supabase clients |
| 2. Crypto & LLM | 5-6 | API key encryption, multi-model adapter |
| 3. Persona & Prompts | 7-8 | System prompts, quiz → persona builder |
| 4. Scenario Engine | 9-12 | Templates, round runner, gates, judge, date orchestrator |
| 5. Matching | 13-14 | Profile filter, speed peek |
| 6. API Routes | 15-16 | Onboarding, matching, date, chat endpoints |
| 7. Frontend | 17-21 | Auth, onboarding, dashboard, match reveal, chat |
| 8. Integration | 22-25 | Landing page, seed data, queue processor, verification |
