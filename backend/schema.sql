-- GHOST RALLY backend starting point. Apply only to a dedicated Supabase project.
create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  handle text unique not null check (length(handle) between 3 and 20),
  friend_code text unique not null,
  country_code char(2),
  xp integer not null default 0 check (xp >= 0),
  created_at timestamptz not null default now()
);
create table if not exists friends (
  user_id uuid not null references profiles(id) on delete cascade,
  friend_id uuid not null references profiles(id) on delete cascade,
  status text not null check (status in ('pending','accepted','blocked')),
  created_at timestamptz not null default now(),
  primary key (user_id,friend_id),
  check (user_id <> friend_id)
);
create table if not exists cars (
  id text primary key,
  name text not null,
  class text not null check (class in ('C','B','A')),
  physics_version text not null,
  stats jsonb not null
);
create table if not exists player_cars (
  user_id uuid not null references profiles(id) on delete cascade,
  car_id text not null references cars(id),
  mastery integer not null default 0,
  livery_id text,
  primary key (user_id,car_id)
);
create table if not exists car_setups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  car_id text not null references cars(id),
  final_drive numeric not null default 0 check (final_drive between -1 and 1),
  brake_bias numeric not null default 0 check (brake_bias between -1 and 1),
  suspension numeric not null default 0 check (suspension between -1 and 1),
  steering_response numeric not null default 0 check (steering_response between -1 and 1),
  differential numeric not null default 0 check (differential between -1 and 1),
  tire_compound text not null default 'standard'
);
create table if not exists tracks (
  id text primary key,
  name text not null,
  surface text not null check (surface in ('ASPHALT','GRAVEL')),
  length_m numeric not null check (length_m > 0),
  data_version text not null,
  active boolean not null default true
);
create table if not exists track_sectors (
  track_id text not null references tracks(id),
  sector_number smallint not null check (sector_number between 1 and 3),
  checkpoint_m numeric not null,
  primary key (track_id,sector_number)
);
create table if not exists runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  track_id text not null references tracks(id),
  car_id text not null references cars(id),
  setup_id uuid references car_setups(id),
  time_ms integer not null check (time_ms between 1000 and 240000),
  sector_1_ms integer not null,
  sector_2_ms integer not null,
  sector_3_ms integer not null,
  valid boolean not null default false,
  game_version text not null,
  physics_version text not null,
  input_mode text not null check (input_mode in ('pro','casual')),
  ghost_path text,
  review_state text not null default 'pending' check (review_state in ('pending','verified','flagged','rejected')),
  created_at timestamptz not null default now(),
  check (sector_1_ms + sector_2_ms + sector_3_ms = time_ms)
);
create index if not exists runs_ranking_idx on runs (track_id,car_id,physics_version,input_mode,time_ms) where valid = true;
create table if not exists run_sectors (
  run_id uuid not null references runs(id) on delete cascade,
  sector_number smallint not null check (sector_number between 1 and 3),
  time_ms integer not null check (time_ms > 0),
  primary key (run_id,sector_number)
);
create table if not exists ghosts (
  run_id uuid primary key references runs(id) on delete cascade,
  storage_path text unique not null,
  byte_size integer not null check (byte_size between 1 and 200000),
  sample_hz integer not null check (sample_hz between 10 and 20),
  checksum text not null,
  created_at timestamptz not null default now()
);
create table if not exists daily_events (
  event_date date primary key,
  track_id text not null references tracks(id),
  car_id text not null references cars(id),
  physics_version text not null,
  weather text not null default 'dry'
);
create table if not exists friend_challenges (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references profiles(id),
  recipient_id uuid not null references profiles(id),
  run_id uuid not null references runs(id),
  status text not null default 'pending',
  response_run_id uuid references runs(id),
  created_at timestamptz not null default now()
);
create table if not exists seasons (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  physics_version text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null
);
create table if not exists season_progress (
  season_id uuid not null references seasons(id),
  user_id uuid not null references profiles(id),
  rating integer not null default 0,
  xp integer not null default 0,
  primary key (season_id,user_id)
);
create table if not exists achievements (id text primary key, name text not null, criteria jsonb not null);
create table if not exists cosmetics (id text primary key, name text not null, kind text not null, price_eur_cents integer);
create table if not exists inventory (
  user_id uuid not null references profiles(id),
  cosmetic_id text not null references cosmetics(id),
  acquired_at timestamptz not null default now(),
  primary key (user_id,cosmetic_id)
);
create table if not exists purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  store_product_id text not null,
  platform_token text unique not null,
  verified boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists entitlements (
  user_id uuid not null references profiles(id),
  entitlement_id text not null,
  source_purchase_id uuid references purchases(id),
  primary key (user_id,entitlement_id)
);
create table if not exists anti_cheat_flags (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references runs(id) on delete cascade,
  reason text not null check (reason in ('impossible_time','checkpoint_skip','speed_hack','teleport','invalid_car','modified_physics','ghost_mismatch')),
  details jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;
alter table friends enable row level security;
alter table player_cars enable row level security;
alter table car_setups enable row level security;
alter table runs enable row level security;
alter table run_sectors enable row level security;
alter table ghosts enable row level security;
alter table friend_challenges enable row level security;
alter table season_progress enable row level security;
alter table inventory enable row level security;
alter table purchases enable row level security;
alter table entitlements enable row level security;
alter table anti_cheat_flags enable row level security;

create policy profiles_read on profiles for select to authenticated using (true);
create policy profiles_own_update on profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy friends_read on friends for select to authenticated using (auth.uid() = user_id or auth.uid() = friend_id);
create policy player_cars_read on player_cars for select to authenticated using (auth.uid() = user_id);
create policy car_setups_owner on car_setups for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy verified_runs_read on runs for select to authenticated using (valid = true and review_state = 'verified' or auth.uid() = user_id);
create policy run_sectors_read on run_sectors for select to authenticated using (exists (select 1 from runs r where r.id = run_id and (r.user_id = auth.uid() or r.valid and r.review_state = 'verified')));
create policy ghosts_read on ghosts for select to authenticated using (exists (select 1 from runs r where r.id = run_id and (r.user_id = auth.uid() or r.valid and r.review_state = 'verified')));
create policy challenges_read on friend_challenges for select to authenticated using (auth.uid() = sender_id or auth.uid() = recipient_id);
create policy season_progress_read on season_progress for select to authenticated using (auth.uid() = user_id);
create policy inventory_read on inventory for select to authenticated using (auth.uid() = user_id);
create policy purchases_read on purchases for select to authenticated using (auth.uid() = user_id);
create policy entitlements_read on entitlements for select to authenticated using (auth.uid() = user_id);
-- Mutations of runs, rewards, purchases and challenges go through authenticated Edge Functions.
