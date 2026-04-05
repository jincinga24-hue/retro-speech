# AIPS Launchpad v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate AIPS Launchpad from localStorage single-file app to Supabase backend with Google/email auth and Resend email notifications.

**Architecture:** Supabase for Postgres DB, Auth, Edge Functions, and RLS. Frontend stays as a vanilla JS SPA split into modules. Resend for transactional email via Supabase Edge Function.

**Tech Stack:** Supabase (Postgres, Auth, Edge Functions), Resend, vanilla JS (ES modules), HTML/CSS

**Spec:** `docs/superpowers/specs/2026-04-05-aips-launchpad-v2-design.md`

---

## File Structure

```
aips-launchpad/
  index.html              — HTML shell with all page markup (no inline JS/CSS)
  css/
    style.css             — all styles extracted from v1 index.html
  js/
    supabase.js           — Supabase client singleton, config from window.__ENV
    auth.js               — login/signup/logout, session listener, auth UI
    app.js                — tab router, nav rendering, init orchestration
    submit.js             — submission form, validation, Supabase insert/update
    board.js              — board grid, filters, project detail modal
    admin.js              — admin panel, scoring sliders, approve/reject
    player-card.js        — card creator, radar SVG, trading card renderer
    my-submissions.js     — email lookup, owner view with applicant cards
    utils.js              — escapeHtml, renderRadarSvg, shared constants
  supabase/
    migrations/
      001_schema.sql      — tables, indexes, RLS, triggers
    functions/
      notify/
        index.ts          — Deno Edge Function for Resend email
  .env.example            — template
  .env                    — actual keys (gitignored)
  config.js               — reads .env or inline config, sets window.__ENV
```

---

## Task 1: Project Setup and Environment

**Files:**
- Create: `.env.example`
- Create: `.gitignore`
- Create: `config.js`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Create `.env.example`**

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
RESEND_API_KEY=re_your-key-here
RESEND_FROM_EMAIL=noreply@aips.club
```

- [ ] **Step 2: Create `.gitignore`**

```
.env
node_modules/
.DS_Store
```

- [ ] **Step 3: Create `config.js`**

This file is loaded first via `<script>` tag. It reads config from a global or can be manually set. Since we have no build tool, the user will copy `.env.example` to a `config.js` that sets `window.__ENV`.

```javascript
// config.js — Copy .env.example values here
// This file is gitignored via the values, but the template is committed
window.__ENV = {
  SUPABASE_URL: 'https://your-project.supabase.co',
  SUPABASE_ANON_KEY: 'your-anon-key-here',
};
```

- [ ] **Step 4: Update CLAUDE.md**

Add v2 context: Supabase backend, modular JS files, config.js for env vars.

- [ ] **Step 5: Commit**

```bash
git add .env.example .gitignore config.js CLAUDE.md
git commit -m "chore: v2 project setup with env config and gitignore"
```

---

## Task 2: Database Schema and RLS

**Files:**
- Create: `supabase/migrations/001_schema.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- =============================================
-- AIPS Launchpad v2 Schema
-- =============================================

-- profiles (auto-created on auth signup)
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  display_name text,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- projects
CREATE TABLE projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  track text NOT NULL CHECK (track IN ('idea', 'mvp')),
  name text NOT NULL,
  problem text NOT NULL,
  solution text NOT NULL,
  target_user text NOT NULL,
  mvp_scope text NOT NULL,
  roles_needed text[] NOT NULL DEFAULT '{}',
  contact_email text NOT NULL,
  contact_method text,
  demo_link text,
  video_link text,
  current_team text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'revision')),
  scores jsonb,
  total_score integer,
  feedback text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_user_id ON projects(user_id);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- player_cards
CREATE TABLE player_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  degree text NOT NULL,
  roles text[] NOT NULL DEFAULT '{}',
  superpower text NOT NULL,
  email text NOT NULL,
  abilities jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(project_id, user_id)
);

CREATE INDEX idx_player_cards_project ON player_cards(project_id);

-- =============================================
-- Row Level Security
-- =============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_cards ENABLE ROW LEVEL SECURITY;

-- Helper: check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- PROFILES policies
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (id = auth.uid() OR is_admin());

CREATE POLICY "Users can update own display_name"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- PROJECTS policies
CREATE POLICY "Anyone can read approved projects"
  ON projects FOR SELECT
  USING (status = 'approved' OR user_id = auth.uid() OR is_admin());

CREATE POLICY "Authenticated users can insert own projects"
  ON projects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Owners can update own revision projects"
  ON projects FOR UPDATE
  USING (user_id = auth.uid() AND status = 'revision')
  WITH CHECK (user_id = auth.uid() AND status = 'pending');

CREATE POLICY "Admins can update any project"
  ON projects FOR UPDATE
  USING (is_admin());

-- PLAYER_CARDS policies
-- Public view without email (use a view for this)
CREATE POLICY "Anyone can read player cards"
  ON player_cards FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert cards"
  ON player_cards FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Card owners can delete own cards"
  ON player_cards FOR DELETE
  USING (user_id = auth.uid());

-- View for public player cards (no email)
CREATE VIEW player_cards_public AS
  SELECT id, project_id, user_id, name, degree, roles, superpower, abilities, created_at
  FROM player_cards;

GRANT SELECT ON player_cards_public TO anon, authenticated;

-- =============================================
-- Notification trigger (calls Edge Function via pg_net)
-- =============================================

-- This trigger fires when project status changes to 'approved' or 'revision'
CREATE OR REPLACE FUNCTION notify_status_change()
RETURNS trigger AS $$
DECLARE
  payload jsonb;
  function_url text;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('approved', 'revision') THEN
    payload := jsonb_build_object(
      'project_id', NEW.id,
      'project_name', NEW.name,
      'contact_email', NEW.contact_email,
      'status', NEW.status,
      'feedback', NEW.feedback,
      'total_score', NEW.total_score
    );

    -- Call the Edge Function via pg_net (must be enabled in Supabase dashboard)
    PERFORM net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/notify',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := payload
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_project_status_change
  AFTER UPDATE OF status ON projects
  FOR EACH ROW EXECUTE FUNCTION notify_status_change();
```

- [ ] **Step 2: Run the migration in Supabase**

Go to Supabase Dashboard → SQL Editor → paste and run `supabase/migrations/001_schema.sql`.

Alternatively if using Supabase CLI:
```bash
supabase db push
```

- [ ] **Step 3: Enable pg_net extension**

In Supabase Dashboard → Database → Extensions → search "pg_net" → enable it. This is required for the notification trigger to call the Edge Function.

- [ ] **Step 4: Set app.settings for the trigger**

In Supabase Dashboard → SQL Editor, run:
```sql
ALTER DATABASE postgres SET app.settings.supabase_url = 'https://your-project.supabase.co';
ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key';
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/001_schema.sql
git commit -m "feat: add database schema, RLS policies, and notification trigger"
```

---

## Task 3: Extract CSS from v1

**Files:**
- Create: `css/style.css`
- Modify: `index.html`

- [ ] **Step 1: Extract all CSS from v1 `index.html`**

Copy everything between `<style>` and `</style>` in the current `index.html` into `css/style.css`. This is ~500 lines of CSS. Keep it exactly as-is — no changes to styles.

- [ ] **Step 2: Add auth-specific CSS to `css/style.css`**

Append these new styles for the auth UI:

```css
/* ─── AUTH ─────────────────────────────────────────────────────── */
.auth-container {
  max-width: 400px;
  margin: 60px auto;
  padding: 36px;
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
}

.auth-container h2 {
  text-align: center;
  margin-bottom: 24px;
}

.auth-divider {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 20px 0;
  color: var(--muted);
  font-size: 13px;
}

.auth-divider::before,
.auth-divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

.btn-google {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px;
  border: 1px solid var(--border);
  border-radius: 980px;
  background: var(--card);
  cursor: pointer;
  font-size: 15px;
  font-weight: 500;
  transition: background 0.15s;
}

.btn-google:hover { background: var(--bg); }

.auth-form { display: flex; flex-direction: column; gap: 12px; }

.auth-toggle {
  text-align: center;
  font-size: 13px;
  color: var(--muted);
  margin-top: 16px;
}

.auth-toggle a {
  color: var(--green);
  cursor: pointer;
  text-decoration: none;
  font-weight: 500;
}

.nav-user {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--muted);
  margin-left: auto;
  white-space: nowrap;
}

.nav-user-name { font-weight: 500; color: var(--text); }

.btn-logout {
  background: none;
  border: 1px solid var(--border);
  padding: 4px 12px;
  border-radius: 980px;
  font-size: 12px;
  cursor: pointer;
  color: var(--muted);
}

.btn-logout:hover { background: var(--bg); }

.login-prompt {
  text-align: center;
  padding: 40px 20px;
  color: var(--muted);
}

.login-prompt a {
  color: var(--green);
  cursor: pointer;
  font-weight: 500;
}
```

- [ ] **Step 3: Update `index.html` to link the external CSS**

Replace the entire `<style>...</style>` block in `index.html` with:
```html
<link rel="stylesheet" href="css/style.css" />
```

- [ ] **Step 4: Verify the page still looks the same**

Open `index.html` in browser. All styles should render identically.

- [ ] **Step 5: Commit**

```bash
git add css/style.css index.html
git commit -m "refactor: extract CSS into css/style.css"
```

---

## Task 4: Extract JS into Modules

**Files:**
- Create: `js/utils.js`
- Create: `js/supabase.js`
- Create: `js/auth.js`
- Create: `js/app.js`
- Create: `js/submit.js`
- Create: `js/board.js`
- Create: `js/admin.js`
- Create: `js/player-card.js`
- Create: `js/my-submissions.js`
- Modify: `index.html`

This is the largest task. We extract v1 JS logic into modules, then rewire each module to use Supabase instead of localStorage in subsequent tasks. For now, we keep the same localStorage logic but in separate files.

- [ ] **Step 1: Create `js/utils.js`**

```javascript
// js/utils.js — Shared utilities

export function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export const CRITERIA = [
  { key: 'problemClarity', label: 'Problem Clarity' },
  { key: 'solutionFeasibility', label: 'Solution Feasibility' },
  { key: 'targetUser', label: 'Target User' },
  { key: 'mvpScope', label: 'MVP Scope' },
  { key: 'teamNeeds', label: 'Team Needs' },
];

export const ROLE_COLORS = {
  Build: '#007AFF',
  Design: '#FF2D55',
  Research: '#5856D6',
  Grow: '#FF9500',
  Advise: '#34C759',
};

export const ABILITIES = [
  { id: 'coding', label: 'Coding' },
  { id: 'design', label: 'Design' },
  { id: 'research', label: 'Research' },
  { id: 'comm', label: 'Communication' },
  { id: 'domain', label: 'Domain' },
];

export function renderRadarSvg(svgId, values, color, cx, cy, maxR) {
  const svg = document.getElementById(svgId);
  if (!svg) return;
  const n = values.length;
  const angleStep = (2 * Math.PI) / n;
  const startAngle = -Math.PI / 2;

  let svgContent = '';
  // Grid rings
  [0.33, 0.66, 1].forEach(ring => {
    const r = maxR * ring;
    let points = '';
    for (let i = 0; i < n; i++) {
      const angle = startAngle + i * angleStep;
      points += `${cx + r * Math.cos(angle)},${cy + r * Math.sin(angle)} `;
    }
    svgContent += `<polygon points="${points.trim()}" fill="none" stroke="#e0e0e0" stroke-width="1"/>`;
  });
  // Axis lines
  for (let i = 0; i < n; i++) {
    const angle = startAngle + i * angleStep;
    svgContent += `<line x1="${cx}" y1="${cy}" x2="${cx + maxR * Math.cos(angle)}" y2="${cy + maxR * Math.sin(angle)}" stroke="#e0e0e0" stroke-width="1"/>`;
  }
  // Data polygon
  let dataPoints = '';
  for (let i = 0; i < n; i++) {
    const angle = startAngle + i * angleStep;
    const r = (values[i] / 10) * maxR;
    dataPoints += `${cx + r * Math.cos(angle)},${cy + r * Math.sin(angle)} `;
  }
  svgContent += `<polygon points="${dataPoints.trim()}" fill="${color}" fill-opacity="0.2" stroke="${color}" stroke-width="2"/>`;
  // Data points
  for (let i = 0; i < n; i++) {
    const angle = startAngle + i * angleStep;
    const r = (values[i] / 10) * maxR;
    svgContent += `<circle cx="${cx + r * Math.cos(angle)}" cy="${cy + r * Math.sin(angle)}" r="3" fill="${color}"/>`;
  }
  // Labels
  const labels = ABILITIES.map(a => a.label);
  for (let i = 0; i < n; i++) {
    const angle = startAngle + i * angleStep;
    const lx = cx + (maxR + 14) * Math.cos(angle);
    const ly = cy + (maxR + 14) * Math.sin(angle);
    const anchor = Math.abs(Math.cos(angle)) < 0.01 ? 'middle' : Math.cos(angle) > 0 ? 'start' : 'end';
    svgContent += `<text x="${lx}" y="${ly}" text-anchor="${anchor}" dominant-baseline="middle" font-size="9" fill="#86868b">${labels[i]}</text>`;
  }
  svg.innerHTML = svgContent;
}

export function renderMiniRadar(values, color) {
  const cx = 50, cy = 50, maxR = 40, n = values.length;
  const angleStep = (2 * Math.PI) / n;
  const startAngle = -Math.PI / 2;
  let svgContent = '';
  [0.5, 1].forEach(ring => {
    const r = maxR * ring;
    let points = '';
    for (let i = 0; i < n; i++) {
      const angle = startAngle + i * angleStep;
      points += `${cx + r * Math.cos(angle)},${cy + r * Math.sin(angle)} `;
    }
    svgContent += `<polygon points="${points.trim()}" fill="none" stroke="#e0e0e0" stroke-width="0.5"/>`;
  });
  let dataPoints = '';
  for (let i = 0; i < n; i++) {
    const angle = startAngle + i * angleStep;
    const r = (values[i] / 10) * maxR;
    dataPoints += `${cx + r * Math.cos(angle)},${cy + r * Math.sin(angle)} `;
  }
  svgContent += `<polygon points="${dataPoints.trim()}" fill="${color}" fill-opacity="0.25" stroke="${color}" stroke-width="1.5"/>`;
  return `<svg width="100" height="100" viewBox="0 0 100 100" class="mini-radar-svg">${svgContent}</svg>`;
}
```

- [ ] **Step 2: Create `js/supabase.js`**

```javascript
// js/supabase.js — Supabase client singleton
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const { SUPABASE_URL, SUPABASE_ANON_KEY } = window.__ENV;
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

- [ ] **Step 3: Create `js/auth.js`**

```javascript
// js/auth.js — Authentication
import { supabase } from './supabase.js';

let currentUser = null;
let currentProfile = null;

export function getUser() { return currentUser; }
export function getProfile() { return currentProfile; }
export function isAdmin() { return currentProfile?.role === 'admin'; }
export function isLoggedIn() { return currentUser !== null; }

export async function initAuth(onAuthChange) {
  supabase.auth.onAuthStateChange(async (event, session) => {
    currentUser = session?.user || null;
    if (currentUser) {
      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', currentUser.id)
        .single();
      currentProfile = data;
    } else {
      currentProfile = null;
    }
    onAuthChange(currentUser, currentProfile);
  });

  const { data: { session } } = await supabase.auth.getSession();
  currentUser = session?.user || null;
  if (currentUser) {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', currentUser.id)
      .single();
    currentProfile = data;
  }
  onAuthChange(currentUser, currentProfile);
}

export async function signInWithGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: window.location.origin + window.location.pathname }
  });
  if (error) throw error;
}

export async function signInWithEmail(email, password) {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
}

export async function signUpWithEmail(email, password, displayName) {
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: displayName } }
  });
  if (error) throw error;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}
```

- [ ] **Step 4: Create `js/app.js`**

```javascript
// js/app.js — Router, nav, init
import { initAuth, getUser, getProfile, isAdmin, isLoggedIn, signOut } from './auth.js';
import { renderBoard, initBoard } from './board.js';
import { renderAdmin, initAdmin } from './admin.js';
import { initSubmit } from './submit.js';
import { initMySubmissions } from './my-submissions.js';
import { initPlayerCard } from './player-card.js';
import { renderStats } from './board.js';

let currentTab = 'home';

export function showTab(tab) {
  // Auth guard — require login for submit, my-submissions
  if (['submit', 'my-submissions'].includes(tab) && !isLoggedIn()) {
    showTab('home');
    document.getElementById('auth-prompt').classList.add('visible');
    return;
  }
  if (tab === 'admin' && !isAdmin()) return;

  currentTab = tab;
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));

  const page = document.getElementById('page-' + tab);
  const tabBtn = document.getElementById('tab-' + tab);
  if (page) page.classList.add('active');
  if (tabBtn) tabBtn.classList.add('active');

  // Render dynamic content
  if (tab === 'board') renderBoard();
  if (tab === 'admin') renderAdmin();
}

function updateNav(user, profile) {
  const navUser = document.getElementById('nav-user');
  const adminTab = document.getElementById('admin-tab-btn');

  if (user && profile) {
    navUser.innerHTML = `
      <span class="nav-user-name">${profile.display_name || user.email}</span>
      <button class="btn-logout" id="btn-logout">Log out</button>
    `;
    navUser.style.display = 'flex';
    document.getElementById('btn-logout').addEventListener('click', async () => {
      await signOut();
    });
  } else {
    navUser.innerHTML = `<a href="#" class="nav-tab" onclick="window.__showTab('home'); return false;">Log in</a>`;
    navUser.style.display = 'flex';
  }

  if (profile?.role === 'admin') {
    adminTab.classList.add('visible');
  } else {
    adminTab.classList.remove('visible');
  }
}

// Global function for onclick handlers in HTML
window.__showTab = showTab;
window.__openProjectDetail = null; // set by board.js
window.__openPcModal = null; // set by player-card.js

async function init() {
  await initAuth((user, profile) => {
    updateNav(user, profile);
    renderStats();
    // Re-render current tab if needed
    if (currentTab === 'board') renderBoard();
    if (currentTab === 'admin' && isAdmin()) renderAdmin();
  });

  initSubmit();
  initBoard();
  initAdmin();
  initMySubmissions();
  initPlayerCard();

  showTab('home');
  renderStats();
}

document.addEventListener('DOMContentLoaded', init);
```

- [ ] **Step 5: Create `js/submit.js`**

```javascript
// js/submit.js — Project submission form
import { supabase } from './supabase.js';
import { getUser } from './auth.js';
import { escapeHtml } from './utils.js';

let currentTrack = 'idea';
let editingProjectId = null;

export function initSubmit() {
  const form = document.getElementById('submit-form');
  if (!form) return;

  form.addEventListener('submit', handleSubmit);

  // Track toggle
  document.getElementById('btn-track-idea')?.addEventListener('click', () => setTrack('idea'));
  document.getElementById('btn-track-mvp')?.addEventListener('click', () => setTrack('mvp'));

  // Role chips — event delegation
  document.getElementById('roles-grid')?.addEventListener('change', (e) => {
    if (e.target.type === 'checkbox') {
      const chip = e.target.closest('.role-chip');
      if (chip) chip.classList.toggle('selected', e.target.checked);
    }
  });
}

function setTrack(track) {
  currentTrack = track;
  document.getElementById('btn-track-idea')?.classList.toggle('active', track === 'idea');
  document.getElementById('btn-track-mvp')?.classList.toggle('active', track === 'mvp');
  const mvpFields = document.getElementById('mvp-fields');
  if (mvpFields) {
    if (track === 'mvp') mvpFields.classList.add('visible');
    else mvpFields.classList.remove('visible');
  }
}

function getSelectedRoles() {
  return Array.from(document.querySelectorAll('#roles-grid input:checked')).map(cb => cb.value);
}

async function handleSubmit(e) {
  e.preventDefault();
  const user = getUser();
  if (!user) return;

  const errorAlert = document.getElementById('submit-alert-error');
  const successAlert = document.getElementById('submit-alert-success');
  errorAlert.classList.remove('visible');
  successAlert.classList.remove('visible');

  // Validate
  const name = document.getElementById('f-name').value.trim();
  const problem = document.getElementById('f-problem').value.trim();
  const solution = document.getElementById('f-solution').value.trim();
  const targetUser = document.getElementById('f-target').value.trim();
  const mvpScope = document.getElementById('f-scope').value.trim();
  const roles = getSelectedRoles();
  const email = document.getElementById('f-email').value.trim();
  const contactMethod = document.getElementById('f-contact-method').value.trim();
  const demoLink = document.getElementById('f-demo')?.value.trim() || null;
  const videoLink = document.getElementById('f-video')?.value.trim() || null;
  const currentTeam = document.getElementById('f-team')?.value.trim() || null;

  if (!name || !problem || !solution || !targetUser || !mvpScope || roles.length === 0 || !email) {
    errorAlert.textContent = 'Please fill in all required fields and select at least one role.';
    errorAlert.classList.add('visible');
    return;
  }

  // URL validation for links
  const safeUrl = /^https?:\/\//i;
  if (demoLink && !safeUrl.test(demoLink)) {
    errorAlert.textContent = 'Demo link must start with http:// or https://';
    errorAlert.classList.add('visible');
    return;
  }
  if (videoLink && !safeUrl.test(videoLink)) {
    errorAlert.textContent = 'Video link must start with http:// or https://';
    errorAlert.classList.add('visible');
    return;
  }
  if (currentTrack === 'mvp' && !currentTeam) {
    errorAlert.textContent = 'Please describe your current team for MVP submissions.';
    errorAlert.classList.add('visible');
    return;
  }

  const projectData = {
    user_id: user.id,
    track: currentTrack,
    name, problem, solution, target_user: targetUser, mvp_scope: mvpScope,
    roles_needed: roles, contact_email: email, contact_method: contactMethod || null,
    demo_link: demoLink, video_link: videoLink, current_team: currentTeam,
  };

  let error;
  if (editingProjectId) {
    // Resubmission
    ({ error } = await supabase
      .from('projects')
      .update({ ...projectData, status: 'pending', scores: null, total_score: null, feedback: null })
      .eq('id', editingProjectId));
    editingProjectId = null;
  } else {
    // New submission
    ({ error } = await supabase.from('projects').insert(projectData));
  }

  if (error) {
    errorAlert.textContent = error.message || 'Something went wrong. Please try again.';
    errorAlert.classList.add('visible');
    return;
  }

  // Reset form
  document.getElementById('submit-form').reset();
  document.querySelectorAll('.role-chip').forEach(c => c.classList.remove('selected'));
  setTrack('idea');

  successAlert.innerHTML = 'Your submission has been received! Track your status in <strong>My Submissions</strong>.';
  successAlert.classList.add('visible');
  successAlert.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

export function prefillAndEdit(projectId, project) {
  editingProjectId = projectId;
  setTrack(project.track);
  document.getElementById('f-name').value = project.name || '';
  document.getElementById('f-problem').value = project.problem || '';
  document.getElementById('f-solution').value = project.solution || '';
  document.getElementById('f-target').value = project.target_user || '';
  document.getElementById('f-scope').value = project.mvp_scope || '';
  document.getElementById('f-email').value = project.contact_email || '';
  document.getElementById('f-contact-method').value = project.contact_method || '';
  document.getElementById('f-demo').value = project.demo_link || '';
  document.getElementById('f-video').value = project.video_link || '';
  document.getElementById('f-team').value = project.current_team || '';

  // Set roles
  document.querySelectorAll('#roles-grid .role-chip').forEach(chip => {
    const cb = chip.querySelector('input');
    const isSelected = (project.roles_needed || []).includes(cb.value);
    cb.checked = isSelected;
    chip.classList.toggle('selected', isSelected);
  });

  window.__showTab('submit');
  document.getElementById('submit-form').scrollIntoView({ behavior: 'smooth' });
}
```

- [ ] **Step 6: Create `js/board.js`**

```javascript
// js/board.js — Project board, filters, detail modal
import { supabase } from './supabase.js';
import { escapeHtml, ROLE_COLORS, CRITERIA } from './utils.js';
import { renderTradingCard } from './player-card.js';
import { isLoggedIn } from './auth.js';

let currentStageFilter = 'all';
let currentRoleFilter = 'all';

export function initBoard() {
  // Filter buttons — event delegation
  document.getElementById('stage-filters')?.addEventListener('click', (e) => {
    const btn = e.target.closest('button');
    if (!btn) return;
    currentStageFilter = btn.dataset.filter;
    document.querySelectorAll('#stage-filters button').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    renderBoard();
  });

  document.getElementById('role-filters')?.addEventListener('click', (e) => {
    const btn = e.target.closest('button');
    if (!btn) return;
    currentRoleFilter = btn.dataset.filter;
    document.querySelectorAll('#role-filters button').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    renderBoard();
  });

  // Modal close
  document.getElementById('project-modal')?.addEventListener('click', (e) => {
    if (e.target.id === 'project-modal') closeProjectModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeProjectModal();
  });

  // Board card clicks — event delegation
  document.getElementById('board-grid')?.addEventListener('click', (e) => {
    const card = e.target.closest('[data-project-id]');
    if (card) openProjectDetail(card.dataset.projectId);
  });
}

export async function renderBoard() {
  const grid = document.getElementById('board-grid');
  const empty = document.getElementById('board-empty');
  if (!grid) return;

  const { data: projects, error } = await supabase
    .from('projects')
    .select('*')
    .eq('status', 'approved')
    .order('created_at', { ascending: false });

  if (error || !projects) {
    grid.innerHTML = '';
    empty?.classList.add('visible');
    return;
  }

  let filtered = projects;
  if (currentStageFilter !== 'all') {
    filtered = filtered.filter(p => p.track === currentStageFilter);
  }
  if (currentRoleFilter !== 'all') {
    filtered = filtered.filter(p => (p.roles_needed || []).includes(currentRoleFilter));
  }

  if (filtered.length === 0) {
    grid.innerHTML = '';
    empty?.classList.add('visible');
    return;
  }

  empty?.classList.remove('visible');
  grid.innerHTML = filtered.map(p => `
    <div class="project-card" data-project-id="${p.id}">
      <div class="card-header">
        <span class="stage-tag ${p.track}">${p.track === 'mvp' ? 'MVP' : 'Idea'}</span>
        <span class="score-badge">${p.total_score}/100</span>
      </div>
      <h3>${escapeHtml(p.name)}</h3>
      <p class="card-pitch">${escapeHtml(p.problem).substring(0, 120)}${p.problem.length > 120 ? '...' : ''}</p>
      <div class="card-roles">
        ${(p.roles_needed || []).map(r => `<span class="role-tag">${r}</span>`).join('')}
      </div>
    </div>
  `).join('');
}

export async function renderStats() {
  const { count: projectCount } = await supabase
    .from('projects')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'approved');

  const { count: cardCount } = await supabase
    .from('player_cards')
    .select('*', { count: 'exact', head: true });

  const statProjects = document.getElementById('stat-projects');
  const statContributors = document.getElementById('stat-contributors');
  if (statProjects) statProjects.textContent = projectCount || 0;
  if (statContributors) statContributors.textContent = cardCount || 0;
}

async function openProjectDetail(projectId) {
  const { data: project } = await supabase.from('projects').select('*').eq('id', projectId).single();
  if (!project) return;

  // Get player cards (public view — no emails)
  const { data: cards } = await supabase.from('player_cards_public').select('*').eq('project_id', projectId);

  const scoreBreakdown = project.scores ? `
    <div class="score-breakdown-grid">
      ${CRITERIA.map(c => `
        <div class="score-cell">
          <div class="score-cell-label">${c.label}</div>
          <div class="score-cell-value">${project.scores[c.key] || 0}<span>/20</span></div>
        </div>
      `).join('')}
    </div>
  ` : '';

  const content = `
    <div class="stage-tag ${project.track}">${project.track === 'mvp' ? 'MVP' : 'Idea'}</div>
    <h2>${escapeHtml(project.name)}</h2>
    ${project.total_score ? `<div class="score-badge-lg">Score: ${project.total_score}/100</div>` : ''}

    <div class="modal-section">
      <div class="modal-section-label">Problem</div>
      <div class="modal-section-text">${escapeHtml(project.problem)}</div>
    </div>
    <div class="modal-section">
      <div class="modal-section-label">Solution</div>
      <div class="modal-section-text">${escapeHtml(project.solution)}</div>
    </div>
    <div class="modal-section">
      <div class="modal-section-label">Target User</div>
      <div class="modal-section-text">${escapeHtml(project.target_user)}</div>
    </div>
    <div class="modal-section">
      <div class="modal-section-label">MVP Scope</div>
      <div class="modal-section-text">${escapeHtml(project.mvp_scope)}</div>
    </div>
    ${project.current_team ? `
      <div class="modal-section">
        <div class="modal-section-label">Current Team</div>
        <div class="modal-section-text">${escapeHtml(project.current_team)}</div>
      </div>
    ` : ''}

    ${scoreBreakdown}

    ${project.demo_link || project.video_link ? `
      <div class="modal-section">
        <div class="modal-section-label">Links</div>
        ${project.demo_link ? `<a href="${escapeHtml(project.demo_link)}" target="_blank" rel="noopener" class="modal-demo-link">View Demo</a>` : ''}
        ${project.video_link ? `<a href="${escapeHtml(project.video_link)}" target="_blank" rel="noopener" class="modal-demo-link">Watch Video</a>` : ''}
      </div>
    ` : ''}

    <div class="modal-footer-row">
      <div class="roles-needed">
        ${(project.roles_needed || []).map(r => `<span class="role-tag">${r}</span>`).join('')}
      </div>
      ${isLoggedIn() ? `<button class="btn btn-primary" onclick="window.__openPcModal('${project.id}')">Join This Team</button>` : `<div class="login-prompt">Log in to join this team</div>`}
    </div>

    ${(cards || []).length > 0 ? `
      <div class="player-cards-section">
        <h3>Team Applicants <span class="player-cards-count">${cards.length}</span></h3>
        <div class="player-cards-grid">
          ${cards.map(card => renderTradingCard(card, false)).join('')}
        </div>
      </div>
    ` : ''}

    ${project.contact_method ? `
      <div class="modal-section" style="margin-top: 16px;">
        <div class="modal-section-label">Want to connect?</div>
        <p style="color: var(--muted); font-size: 13px; margin-bottom: 8px;">Submit a player card above, then reach out to the founder:</p>
        <div style="background: var(--bg); padding: 12px 16px; border-radius: 10px; font-size: 14px; color: var(--text);">📱 ${escapeHtml(project.contact_method)}</div>
      </div>
    ` : ''}
  `;

  document.getElementById('modal-content').innerHTML = content;
  document.getElementById('project-modal').classList.add('open');
  document.body.style.overflow = 'hidden';
}

window.__openProjectDetail = openProjectDetail;

function closeProjectModal() {
  const modal = document.getElementById('project-modal');
  if (modal?.classList.contains('open')) {
    modal.classList.remove('open');
    document.body.style.overflow = '';
  }
}
```

- [ ] **Step 7: Create `js/admin.js`**

```javascript
// js/admin.js — Admin panel
import { supabase } from './supabase.js';
import { escapeHtml, CRITERIA } from './utils.js';
import { isAdmin } from './auth.js';

export function initAdmin() {
  // Nothing to init — renderAdmin is called on tab switch
}

export async function renderAdmin() {
  if (!isAdmin()) return;

  const list = document.getElementById('admin-pending-list');
  const empty = document.getElementById('admin-empty');
  if (!list) return;

  const { data: pending } = await supabase
    .from('projects')
    .select('*')
    .eq('status', 'pending')
    .order('created_at', { ascending: true });

  if (!pending || pending.length === 0) {
    list.innerHTML = '';
    empty?.classList.add('visible');
    return;
  }

  empty?.classList.remove('visible');
  list.innerHTML = pending.map(p => {
    const id = p.id;
    return `
      <div class="admin-item">
        <div class="admin-item-header">
          <h3 class="admin-item-title">${escapeHtml(p.name)}</h3>
          <span class="stage-tag ${p.track}">${p.track === 'mvp' ? 'MVP' : 'Idea'}</span>
        </div>
        <div class="admin-item-meta">${escapeHtml(p.contact_email)} · Submitted ${new Date(p.created_at).toLocaleDateString('en-AU', { day: 'numeric', month: 'short' })}</div>

        <div class="admin-item-field"><strong>Problem:</strong> ${escapeHtml(p.problem)}</div>
        <div class="admin-item-field"><strong>Solution:</strong> ${escapeHtml(p.solution)}</div>
        <div class="admin-item-field-sm"><strong>Target User:</strong> ${escapeHtml(p.target_user)}</div>
        <div class="admin-item-field"><strong>MVP Scope:</strong> ${escapeHtml(p.mvp_scope)}</div>
        ${p.current_team ? `<div class="admin-item-field-sm"><strong>Current Team:</strong> ${escapeHtml(p.current_team)}</div>` : ''}

        <div class="scoring-section">
          <h4>Score Each Criterion (0-20)</h4>
          ${CRITERIA.map(c => `
            <div class="scoring-row">
              <label>${c.label}</label>
              <input type="range" min="0" max="20" value="10" class="score-slider" data-id="${id}" data-key="${c.key}"
                oninput="this.nextElementSibling.textContent = this.value; window.__updateTotal('${id}')" />
              <span class="score-val">10</span>
            </div>
          `).join('')}
          <div class="score-total">Total Score: <span id="total-${id}" class="score-total-num">50</span>/100</div>
        </div>

        <div class="form-group">
          <label class="feedback-label">Written Feedback</label>
          <textarea id="feedback-${id}" rows="2" placeholder="Provide feedback for the team..."></textarea>
        </div>

        <div class="admin-actions">
          <button class="btn btn-primary" id="approve-${id}" onclick="window.__adminDecision('${id}', 'approved')">Approve & Publish</button>
          <button class="btn btn-secondary" onclick="window.__adminDecision('${id}', 'revision')">Return for Revision</button>
        </div>
        <div class="approval-error-msg" id="admin-error-${id}"></div>
      </div>
    `;
  }).join('');

  // Update totals and button states
  pending.forEach(p => window.__updateTotal(p.id));
}

window.__updateTotal = function(id) {
  const sliders = document.querySelectorAll(`.score-slider[data-id="${id}"]`);
  let total = 0;
  sliders.forEach(s => total += parseInt(s.value, 10));
  const el = document.getElementById('total-' + id);
  if (el) {
    el.textContent = total;
    el.className = total >= 60 ? 'score-total-num pass' : 'score-total-num fail';
  }
  const approveBtn = document.getElementById('approve-' + id);
  if (approveBtn) approveBtn.disabled = total < 60;
};

window.__adminDecision = async function(id, decision) {
  const sliders = document.querySelectorAll(`.score-slider[data-id="${id}"]`);
  const scores = {};
  let total = 0;
  sliders.forEach(s => {
    scores[s.dataset.key] = parseInt(s.value, 10);
    total += parseInt(s.value, 10);
  });
  const feedback = document.getElementById('feedback-' + id)?.value.trim() || '';
  const errEl = document.getElementById('admin-error-' + id);

  if (decision === 'revision' && !feedback) {
    errEl.textContent = 'Please provide feedback when returning for revision.';
    errEl.classList.add('visible');
    return;
  }

  const { error } = await supabase
    .from('projects')
    .update({
      status: decision,
      scores,
      total_score: total,
      feedback: feedback || null,
    })
    .eq('id', id);

  if (error) {
    errEl.textContent = error.message;
    errEl.classList.add('visible');
    return;
  }

  renderAdmin();
};
```

- [ ] **Step 8: Create `js/player-card.js`**

```javascript
// js/player-card.js — Player card creator and trading card display
import { supabase } from './supabase.js';
import { getUser } from './auth.js';
import { escapeHtml, ROLE_COLORS, ABILITIES, renderRadarSvg, renderMiniRadar } from './utils.js';

let currentPcProjectId = null;
let selectedPcRoles = [];

export function initPlayerCard() {
  // Role buttons — event delegation
  document.getElementById('pc-role-grid')?.addEventListener('click', (e) => {
    const btn = e.target.closest('.pc-role-btn');
    if (!btn) return;
    const role = btn.dataset.role;
    const idx = selectedPcRoles.indexOf(role);
    if (idx >= 0) {
      selectedPcRoles = selectedPcRoles.filter(r => r !== role);
      btn.className = 'pc-role-btn';
    } else {
      selectedPcRoles = [...selectedPcRoles, role];
      btn.className = 'pc-role-btn selected-' + role.toLowerCase();
    }
    updatePcRadar();
  });

  // Ability sliders
  ABILITIES.forEach(a => {
    document.getElementById('ab-' + a.id)?.addEventListener('input', updatePcRadar);
  });

  // Submit
  document.getElementById('pc-form')?.addEventListener('submit', handleSubmitCard);

  // Modal close
  document.getElementById('pc-modal')?.addEventListener('click', (e) => {
    if (e.target.id === 'pc-modal') closePcModal();
  });

  updatePcRadar();
}

function updatePcRadar() {
  ABILITIES.forEach(a => {
    const slider = document.getElementById('ab-' + a.id);
    const val = document.getElementById('abv-' + a.id);
    if (slider && val) val.textContent = slider.value;
  });
  const vals = ABILITIES.map(a => parseInt(document.getElementById('ab-' + a.id)?.value || 5, 10));
  const color = selectedPcRoles.length > 0 ? ROLE_COLORS[selectedPcRoles[0]] : '#2DB757';
  renderRadarSvg('pc-radar-preview', vals, color, 100, 100, 80);
}

export function openPcModal(projectId) {
  currentPcProjectId = projectId;
  selectedPcRoles = [];
  ['pc-name', 'pc-degree', 'pc-superpower', 'pc-email'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  ABILITIES.forEach(a => {
    const slider = document.getElementById('ab-' + a.id);
    const val = document.getElementById('abv-' + a.id);
    if (slider) slider.value = 5;
    if (val) val.textContent = '5';
  });
  document.querySelectorAll('.pc-role-btn').forEach(b => b.className = 'pc-role-btn');
  updatePcRadar();
  document.getElementById('pc-modal')?.classList.add('open');
  document.body.style.overflow = 'hidden';
}

window.__openPcModal = openPcModal;

function closePcModal() {
  document.getElementById('pc-modal')?.classList.remove('open');
  document.body.style.overflow = '';
}

async function handleSubmitCard(e) {
  e.preventDefault();
  const user = getUser();
  if (!user) return;

  const name = document.getElementById('pc-name').value.trim();
  const degree = document.getElementById('pc-degree').value.trim();
  const superpower = document.getElementById('pc-superpower').value.trim();
  const email = document.getElementById('pc-email').value.trim();
  const alertEl = document.getElementById('pc-alert');

  if (!name || !degree || !superpower || !email || selectedPcRoles.length === 0) {
    alertEl.className = 'alert alert-error visible';
    alertEl.textContent = 'Please fill in all fields and select at least one role.';
    return;
  }

  const abilities = {
    coding: parseInt(document.getElementById('ab-coding').value, 10),
    design: parseInt(document.getElementById('ab-design').value, 10),
    research: parseInt(document.getElementById('ab-research').value, 10),
    comm: parseInt(document.getElementById('ab-comm').value, 10),
    domain: parseInt(document.getElementById('ab-domain').value, 10),
  };

  const { error } = await supabase.from('player_cards').insert({
    project_id: currentPcProjectId,
    user_id: user.id,
    name, degree, roles: selectedPcRoles, superpower, email, abilities,
  });

  if (error) {
    if (error.code === '23505') {
      alertEl.className = 'alert alert-error visible';
      alertEl.textContent = 'You have already submitted a player card for this project.';
    } else {
      alertEl.className = 'alert alert-error visible';
      alertEl.textContent = error.message;
    }
    return;
  }

  closePcModal();
  // Reopen project detail to show the new card
  window.__openProjectDetail?.(currentPcProjectId);
}

export function renderTradingCard(card, showEmail) {
  const roles = card.roles || [];
  const primaryRole = roles[0] || 'Build';
  const color = ROLE_COLORS[primaryRole] || '#2DB757';
  const abilities = [card.abilities.coding, card.abilities.design, card.abilities.research, card.abilities.comm, card.abilities.domain];
  const miniRadar = renderMiniRadar(abilities, color);
  const roleBadges = roles.map(r => `<span class="tc-role-badge role-${escapeHtml(r)}">${escapeHtml(r)}</span>`).join(' ');
  return `
    <div class="trading-card role-${escapeHtml(primaryRole)}">
      <div class="tc-roles">${roleBadges}</div>
      <div class="tc-name">${escapeHtml(card.name)}</div>
      <div class="tc-degree">${escapeHtml(card.degree)}</div>
      <div class="tc-superpower">"${escapeHtml(card.superpower)}"</div>
      ${miniRadar}
      ${showEmail ? `<div class="tc-email">${escapeHtml(card.email)}</div>` : ''}
    </div>
  `;
}
```

- [ ] **Step 9: Create `js/my-submissions.js`**

```javascript
// js/my-submissions.js — Status lookup for project owners
import { supabase } from './supabase.js';
import { getUser, isLoggedIn } from './auth.js';
import { escapeHtml } from './utils.js';
import { renderTradingCard } from './player-card.js';
import { prefillAndEdit } from './submit.js';

export function initMySubmissions() {
  document.getElementById('btn-lookup')?.addEventListener('click', lookupSubmissions);
}

async function lookupSubmissions() {
  const user = getUser();
  if (!user) return;

  const list = document.getElementById('my-submissions-list');
  const empty = document.getElementById('my-submissions-empty');
  if (!list) return;

  // Get all projects by this user
  const { data: projects } = await supabase
    .from('projects')
    .select('*')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false });

  if (!projects || projects.length === 0) {
    list.innerHTML = '';
    empty?.classList.add('visible');
    return;
  }

  empty?.classList.remove('visible');

  // For approved projects, get player cards WITH emails (owner view)
  const approvedIds = projects.filter(p => p.status === 'approved').map(p => p.id);
  let cardsByProject = {};
  if (approvedIds.length > 0) {
    const { data: cards } = await supabase
      .from('player_cards')
      .select('*')
      .in('project_id', approvedIds);
    (cards || []).forEach(c => {
      if (!cardsByProject[c.project_id]) cardsByProject[c.project_id] = [];
      cardsByProject[c.project_id].push(c);
    });
  }

  list.innerHTML = projects.map(p => {
    const date = new Date(p.created_at).toLocaleDateString('en-AU', { day: 'numeric', month: 'short', year: 'numeric' });
    const cards = cardsByProject[p.id] || [];
    return `
      <div class="submission-item">
        <div class="submission-item-header">
          <strong>${escapeHtml(p.name)}</strong>
          <span class="status-badge ${p.status}">${p.status}</span>
        </div>
        <div class="submission-meta">Track: ${p.track === 'mvp' ? 'MVP' : 'Idea'} · Submitted ${date}${p.total_score !== null ? ` · Score: ${p.total_score}/100` : ''}</div>
        ${p.status === 'revision' && p.feedback ? `
          <div class="revision-box">
            <div class="rev-label">Committee Feedback</div>
            <div class="rev-feedback">${escapeHtml(p.feedback)}</div>
            <button class="btn-resubmit" data-project-id="${p.id}">Edit & Resubmit</button>
          </div>
        ` : (p.feedback ? `<div class="feedback-box">${escapeHtml(p.feedback)}</div>` : '')}
        ${p.status === 'approved' && cards.length > 0 ? `
          <div class="applicants-section">
            <h4 style="font-size:14px; margin: 16px 0 8px;">People who want to join (${cards.length})</h4>
            <div class="player-cards-grid">
              ${cards.map(card => renderTradingCard(card, true)).join('')}
            </div>
          </div>
        ` : ''}
        ${p.status === 'approved' && cards.length === 0 ? `
          <div class="empty-applicants">No applicants yet. Share your project to attract teammates!</div>
        ` : ''}
      </div>
    `;
  }).join('');

  // Resubmit buttons — event delegation
  list.querySelectorAll('.btn-resubmit').forEach(btn => {
    btn.addEventListener('click', () => {
      const project = projects.find(p => p.id === btn.dataset.projectId);
      if (project) prefillAndEdit(project.id, project);
    });
  });
}
```

- [ ] **Step 10: Update `index.html`**

Strip all inline `<style>` and `<script>` blocks. Replace with external file references. Keep all HTML markup (pages, modals, forms) but add auth UI elements and `<div id="nav-user">`.

The `<head>` becomes:
```html
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AIPS Launchpad</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;500;600;700&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="css/style.css" />
</head>
```

Add to the nav (before closing `</nav>`):
```html
<div id="nav-user" class="nav-user" style="display:none;"></div>
```

Add auth container page before the home page:
```html
<div id="page-auth" class="page">
  <div class="auth-container">
    <h2>Welcome to AIPS Launchpad</h2>
    <button class="btn-google" id="btn-google-login">
      <svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>
      Continue with Google
    </button>
    <div class="auth-divider">or</div>
    <form class="auth-form" id="auth-email-form">
      <input type="text" id="auth-name" placeholder="Display name" style="display:none;" />
      <input type="email" id="auth-email" placeholder="Email" required />
      <input type="password" id="auth-password" placeholder="Password" required />
      <div id="auth-error" class="alert alert-error"></div>
      <button type="submit" class="btn btn-primary" id="auth-submit-btn">Log in</button>
    </form>
    <div class="auth-toggle">
      <span id="auth-toggle-text">Don't have an account?</span>
      <a id="auth-toggle-link">Sign up</a>
    </div>
  </div>
</div>
```

Add at bottom of `<body>`:
```html
<script src="config.js"></script>
<script type="module" src="js/app.js"></script>
```

Remove all inline `<script>` tags.

- [ ] **Step 11: Commit**

```bash
git add js/ css/ index.html config.js
git commit -m "refactor: split v1 into modular JS files with Supabase integration"
```

---

## Task 5: Resend Email Edge Function

**Files:**
- Create: `supabase/functions/notify/index.ts`

- [ ] **Step 1: Write the Edge Function**

```typescript
// supabase/functions/notify/index.ts
import { Resend } from 'npm:resend@4';

const resend = new Resend(Deno.env.get('RESEND_API_KEY'));
const fromEmail = Deno.env.get('RESEND_FROM_EMAIL') || 'AIPS Launchpad <noreply@aips.club>';

Deno.serve(async (req) => {
  try {
    const { project_name, contact_email, status, feedback, total_score } = await req.json();

    if (!contact_email || !project_name || !status) {
      return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400 });
    }

    let subject: string;
    let html: string;

    if (status === 'approved') {
      subject = `Your project "${project_name}" has been approved!`;
      html = `
        <div style="font-family: -apple-system, sans-serif; max-width: 500px; margin: 0 auto;">
          <h2 style="color: #2DB757;">Congratulations! 🎉</h2>
          <p>Your project <strong>${project_name}</strong> scored <strong>${total_score}/100</strong> and has been approved by the AIPS committee.</p>
          <p>It's now live on the AIPS Launchpad board. Others can browse it and apply to join your team.</p>
          <p style="color: #86868b; font-size: 13px;">— AIPS Committee</p>
        </div>
      `;
    } else if (status === 'revision') {
      subject = `Your project "${project_name}" needs some changes`;
      html = `
        <div style="font-family: -apple-system, sans-serif; max-width: 500px; margin: 0 auto;">
          <h2>Feedback on ${project_name}</h2>
          <p>The AIPS committee has reviewed your submission and has some feedback:</p>
          <div style="background: #f5f5f7; padding: 16px; border-radius: 8px; margin: 16px 0;">
            <p style="margin: 0;">${feedback || 'No specific feedback provided.'}</p>
          </div>
          <p>Please revise your submission and resubmit through the Launchpad.</p>
          <p style="color: #86868b; font-size: 13px;">— AIPS Committee</p>
        </div>
      `;
    } else {
      return new Response(JSON.stringify({ error: 'Unknown status' }), { status: 400 });
    }

    const { error } = await resend.emails.send({
      from: fromEmail,
      to: [contact_email],
      subject,
      html,
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
```

- [ ] **Step 2: Deploy the Edge Function**

```bash
supabase functions deploy notify --no-verify-jwt
```

- [ ] **Step 3: Set Edge Function secrets**

```bash
supabase secrets set RESEND_API_KEY=re_your-key-here RESEND_FROM_EMAIL="AIPS Launchpad <noreply@aips.club>"
```

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/notify/index.ts
git commit -m "feat: add Resend email notification Edge Function"
```

---

## Task 6: Configure Supabase Auth (Google OAuth)

This task is done in the Supabase Dashboard, not in code.

- [ ] **Step 1: Enable Google provider**

Supabase Dashboard → Authentication → Providers → Google → Enable.

You need a Google OAuth client ID and secret from [Google Cloud Console](https://console.cloud.google.com/apis/credentials):
1. Create OAuth 2.0 Client ID (Web application)
2. Authorized redirect URI: `https://your-project.supabase.co/auth/v1/callback`
3. Copy Client ID and Secret into Supabase

- [ ] **Step 2: Enable email/password provider**

Supabase Dashboard → Authentication → Providers → Email → ensure enabled (on by default).

- [ ] **Step 3: Set site URL**

Supabase Dashboard → Authentication → URL Configuration → Site URL: set to your app URL (or `http://localhost:8080` for dev).

- [ ] **Step 4: Seed admin users**

After you (and committee members) have signed up, run in SQL Editor:
```sql
UPDATE profiles SET role = 'admin' WHERE email IN ('AIPS10110@gmail.com');
```

---

## Task 7: Wire Auth UI in app.js

**Files:**
- Modify: `js/app.js`

- [ ] **Step 1: Add auth UI event listeners to `init()`**

Add these lines inside the `init()` function in `js/app.js`, after `document.addEventListener('DOMContentLoaded', init)`:

```javascript
// In init(), add:
import { signInWithGoogle, signInWithEmail, signUpWithEmail } from './auth.js';

let isSignUp = false;

document.getElementById('btn-google-login')?.addEventListener('click', async () => {
  await signInWithGoogle();
});

document.getElementById('auth-email-form')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('auth-email').value.trim();
  const password = document.getElementById('auth-password').value;
  const errEl = document.getElementById('auth-error');
  errEl.classList.remove('visible');

  try {
    if (isSignUp) {
      const name = document.getElementById('auth-name').value.trim();
      await signUpWithEmail(email, password, name);
      errEl.className = 'alert alert-success visible';
      errEl.textContent = 'Check your email to confirm your account!';
    } else {
      await signInWithEmail(email, password);
      showTab('home');
    }
  } catch (err) {
    errEl.className = 'alert alert-error visible';
    errEl.textContent = err.message;
  }
});

document.getElementById('auth-toggle-link')?.addEventListener('click', () => {
  isSignUp = !isSignUp;
  document.getElementById('auth-name').style.display = isSignUp ? 'block' : 'none';
  document.getElementById('auth-submit-btn').textContent = isSignUp ? 'Sign up' : 'Log in';
  document.getElementById('auth-toggle-text').textContent = isSignUp ? 'Already have an account?' : "Don't have an account?";
  document.getElementById('auth-toggle-link').textContent = isSignUp ? 'Log in' : 'Sign up';
});
```

- [ ] **Step 2: Update `updateNav` to show login link**

When not logged in, the nav login link should switch to the auth page:
```javascript
navUser.innerHTML = `<a href="#" class="nav-tab" onclick="window.__showTab('auth'); return false;">Log in</a>`;
```

- [ ] **Step 3: Commit**

```bash
git add js/app.js
git commit -m "feat: wire auth UI with Google and email/password login"
```

---

## Task 8: Update `.env.example` and Config, Final Wiring

**Files:**
- Modify: `config.js`
- Modify: `CLAUDE.md`
- Create: `.env` (user fills in)

- [ ] **Step 1: User fills in `config.js` with real Supabase credentials**

```javascript
window.__ENV = {
  SUPABASE_URL: 'https://your-actual-project.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
};
```

- [ ] **Step 2: Add `config.js` to `.gitignore`**

Since it contains credentials, add to `.gitignore`:
```
config.js
```

Create `config.example.js` as the committed template instead.

- [ ] **Step 3: Update CLAUDE.md for v2**

```markdown
# AIPS Launchpad v2

## Project
Multi-user web app for AIPS club at University of Melbourne. Supabase backend.

## Tech
- Frontend: vanilla JS ES modules, HTML, CSS
- Backend: Supabase (Postgres, Auth, Edge Functions)
- Email: Resend via Edge Function
- No build step — ES modules loaded via <script type="module">

## Key Files
- `index.html` — HTML shell
- `css/style.css` — all styles
- `js/` — modular JS (app, auth, supabase, submit, board, admin, player-card, my-submissions, utils)
- `supabase/migrations/001_schema.sql` — database schema
- `supabase/functions/notify/index.ts` — email notifications
- `config.js` — Supabase credentials (gitignored)
```

- [ ] **Step 4: Commit**

```bash
git add .gitignore config.example.js CLAUDE.md
git commit -m "chore: finalize v2 config and docs"
```

---

## Task 9: End-to-End Testing

- [ ] **Step 1: Start local server and open app**

```bash
python3 -m http.server 8080
open http://localhost:8080/aips-launchpad/index.html
```

- [ ] **Step 2: Test auth flow**

1. Click "Log in" → see auth page
2. Sign up with email/password → check email for confirmation
3. Sign in with Google → redirects back, nav shows name + logout
4. Log out → nav shows "Log in" again

- [ ] **Step 3: Test submit → admin → board flow**

1. Log in → go to Submit → fill form → submit
2. Log in as admin → Admin tab visible → see pending submission
3. Score it 60+ → Approve → check Board → project appears
4. Score another <60 → Return for Revision → check My Submissions → see feedback + resubmit button

- [ ] **Step 4: Test player cards**

1. Browse Board as a different user → click project → Join This Team
2. Fill player card with radar chart → submit
3. Card appears in project detail (no email visible)
4. Original project owner checks My Submissions → sees applicant card WITH email

- [ ] **Step 5: Test email notifications**

1. Approve a project → check the contact_email inbox for approval email
2. Return a project for revision → check inbox for revision email with feedback

- [ ] **Step 6: Test unauthenticated access**

1. Log out → Board tab still works (read-only)
2. Click "Join This Team" → shows login prompt instead
3. Submit tab → redirects to login

- [ ] **Step 7: Commit any fixes**

```bash
git add -A
git commit -m "fix: e2e testing fixes"
```
