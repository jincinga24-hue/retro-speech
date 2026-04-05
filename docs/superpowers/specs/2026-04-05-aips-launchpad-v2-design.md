# AIPS Launchpad v2 — Design Spec

**Date:** 2026-04-05
**Status:** Approved
**Project:** aips-launchpad

## Overview

Migrate AIPS Launchpad from a localStorage single-file app to a real multi-user platform with Supabase backend, Google + email/password auth, and email notifications via Resend. Same UI, same features, but persistent and shared across devices/users.

## Architecture

- **Frontend:** Single-page app split into multiple JS modules. Same Apple white/grey UI.
- **Backend:** Supabase (Postgres DB + Auth + Edge Functions + Row Level Security)
- **Auth:** Supabase Auth with Google OAuth + email/password
- **Email:** Resend via Supabase Edge Function, triggered on project status change

## Database Schema

### profiles
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK, FK to auth.users |
| email | text | from auth |
| display_name | text | from auth or user-set |
| role | text | 'user' or 'admin', default 'user' |
| created_at | timestamptz | default now() |

Auto-created on signup via Postgres trigger on `auth.users`.

### projects
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK, default gen_random_uuid() |
| user_id | uuid | FK to profiles.id |
| track | text | 'idea' or 'mvp' |
| name | text | not null |
| problem | text | not null |
| solution | text | not null |
| target_user | text | not null |
| mvp_scope | text | not null |
| roles_needed | text[] | e.g. {'Build','Design'} |
| contact_email | text | not null |
| contact_method | text | nullable |
| demo_link | text | nullable, MVP only |
| video_link | text | nullable, MVP only |
| current_team | text | nullable, MVP only |
| status | text | 'pending', 'approved', 'revision', default 'pending' |
| scores | jsonb | nullable, e.g. {problemClarity: 16, ...} |
| total_score | integer | nullable |
| feedback | text | nullable |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

### player_cards
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK, default gen_random_uuid() |
| project_id | uuid | FK to projects.id |
| user_id | uuid | FK to profiles.id |
| name | text | not null |
| degree | text | not null |
| roles | text[] | e.g. {'Build','Research'} |
| superpower | text | not null |
| email | text | not null |
| abilities | jsonb | {coding, design, research, comm, domain} each 1-10 |
| created_at | timestamptz | default now() |

## Row Level Security (RLS)

### projects
- **SELECT:** anyone can read projects with status = 'approved'. Authenticated users can read their own projects (any status). Admins can read all.
- **INSERT:** authenticated users can insert with user_id = auth.uid()
- **UPDATE:** owners can update their own projects (for resubmission — only allowed when status = 'revision', resets to 'pending'). Admins can update any project (for scoring/approval).

### player_cards
- **SELECT:** public can read player cards but WITHOUT the email column. Project owners can read full cards (including email) for their own projects. Admins can read all.
- **INSERT:** authenticated users can insert. One card per user per project (unique constraint on project_id + user_id).
- **DELETE:** card owners can delete their own cards.

### profiles
- **SELECT:** users can read their own profile. Admins can read all.
- **UPDATE:** users can update their own display_name. Only admins can update role.

## Auth Flow

1. Landing page shows login/signup options when not authenticated
2. Google Sign-In button (primary) + email/password form (fallback)
3. On first login, Postgres trigger creates a profile row from auth.users metadata
4. Nav shows user avatar/name + logout button when logged in
5. Unauthenticated users can browse the board (read-only) but cannot submit or join
6. Admin role assigned by updating `profiles.role` in Supabase dashboard or via seed SQL

### Admin Access
- Based on `profiles.role = 'admin'`
- Admin tab visible only when logged-in user has admin role
- Committee emails whitelisted as admin via SQL seed:
  ```sql
  UPDATE profiles SET role = 'admin' WHERE email IN ('AIPS10110@gmail.com', ...);
  ```

## Email Notifications

Supabase Edge Function (`notify`) called via database webhook when `projects.status` changes.

### Triggers
- **Status changes to 'approved':**
  - To: project owner's contact_email
  - Subject: "Your project [name] has been approved!"
  - Body: "Congratulations! Your project is now live on the AIPS Launchpad board. Others can now browse it and apply to join your team."

- **Status changes to 'revision':**
  - To: project owner's contact_email
  - Subject: "Your project [name] needs some changes"
  - Body: "The AIPS committee has reviewed your submission and has some feedback: [feedback]. Please revise and resubmit."

### Implementation
- Supabase Edge Function written in TypeScript (Deno)
- Uses Resend SDK (`npm:resend`)
- Triggered by a Postgres trigger that calls `supabase.functions.invoke('notify')` via pg_net or a database webhook
- Environment variables: `RESEND_API_KEY`, `RESEND_FROM_EMAIL`

## File Structure
```
aips-launchpad/
  index.html              — main HTML shell
  css/
    style.css             — all styles (extracted from v1)
  js/
    supabase.js           — Supabase client init (reads .env at build or inline config)
    auth.js               — login/signup/logout, session state, auth UI
    app.js                — router, tab switching, init, nav rendering
    submit.js             — submission form logic
    board.js              — board rendering, filters, project detail modal
    admin.js              — admin panel, scoring, approve/reject
    player-card.js        — card creator, radar chart SVG, trading card display
    my-submissions.js     — status lookup, applicant cards for owners
    utils.js              — escapeHtml, shared helpers
  supabase/
    migrations/
      001_schema.sql      — tables, RLS policies, triggers
    functions/
      notify/
        index.ts          — Edge Function for Resend email
  .env.example            — template with required env vars
  .env                    — actual keys (gitignored)
```

## What Stays the Same
- Apple white/grey UI with AIPS green accents
- Rajdhani font for headings, system font for body
- 5 scoring criteria (Problem Clarity, Solution Feasibility, Target User, MVP Scope, Team Needs), 0-20 each, 60+ to approve
- Player cards with 5-axis radar chart
- 5 contributor roles (Build, Design, Research, Grow, Advise)
- Funding tab (Coming Soon)
- Contact method flow (shown after player card submission)
- Mobile responsive

## What Changes
- localStorage replaced with Supabase Postgres
- No more URL hash admin access — role-based via auth
- Users must log in to submit projects or create player cards
- Board browsing remains public (no login required)
- Email sent on approve/revision
- Single HTML file split into modular JS files
- Player card emails hidden from public, visible only to project owner

## Migration
- No data migration from v1 (localStorage was demo/testing only)
- Fresh database, clean start
- v1 can remain as a static demo/reference

## Environment Variables
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
RESEND_API_KEY=re_xxxxx
RESEND_FROM_EMAIL=noreply@aips.club
```
