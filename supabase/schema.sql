-- USCW Seminar Check-In — Supabase schema
-- Mirrors the app's former IndexedDB stores (attendees, scheduledCalls,
-- messageQueue, settings). Column names are quoted camelCase so they match the
-- JS record fields exactly, keeping the client a drop-in replacement for the
-- old DB layer. Apply via the Management API or the SQL editor.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.attendees (
  "id"                 text primary key,
  "firstName"          text,
  "lastName"           text,
  "searchName"         text,
  "phone"              text,
  "email"              text,
  "company"            text,
  "retirementDate"     text,
  "investableAssets"   text,
  "checkInStatus"      text default 'not_checked_in',
  "checkInTimestamp"   text,
  "source"             text,
  "isWalkIn"           boolean,
  "isAdditionalGuest"  boolean default false,
  "partyId"            text,
  "primaryAttendeeId"  text,
  "relationship"       text default '',
  "assignedTeamMember" text,
  "scheduledCallId"    text,
  "wantsCall"          boolean default false,
  "followUpMemberIds"  jsonb,
  "followUpChosen"     boolean default false,
  "updatedAt"          text,
  "createdAt"          timestamptz default now()
);
create index if not exists attendees_searchname_idx    on public.attendees ("searchName");
create index if not exists attendees_checkinstatus_idx on public.attendees ("checkInStatus");
create index if not exists attendees_partyid_idx       on public.attendees ("partyId");

create table if not exists public."scheduledCalls" (
  "id"                 text primary key,
  "attendeeId"         text,
  "date"               text,
  "window"             text,
  "status"             text,
  "source"             text,
  "startTime"          text,
  "assignedTeamMember" text,
  "createdAt"          text
);
create index if not exists scheduledcalls_attendeeid_idx on public."scheduledCalls" ("attendeeId");

create table if not exists public."messageQueue" (
  "id"             text primary key,
  "attendeeId"     text,
  "messageType"    text,
  "recipientName"  text,
  "recipientPhone" text,
  "recipientEmail" text,
  "content"        text,
  "status"         text default 'pending',
  "createdAt"      text,
  "exportedAt"     text,
  "channel"        text
);
create index if not exists messagequeue_attendeeid_idx on public."messageQueue" ("attendeeId");
create index if not exists messagequeue_status_idx     on public."messageQueue" ("status");

create table if not exists public.settings (
  "key"   text primary key,
  "value" jsonb
);

-- ---------------------------------------------------------------------------
-- Row-level security
-- Model: any authenticated (signed-in) staff device has full access. Anonymous
-- visitors who merely load the app URL get nothing — no PII leaks. The admin
-- passcode (stored in settings) remains a soft in-app gate on top of this.
-- ---------------------------------------------------------------------------

alter table public.attendees        enable row level security;
alter table public."scheduledCalls" enable row level security;
alter table public."messageQueue"   enable row level security;
alter table public.settings         enable row level security;

drop policy if exists auth_all on public.attendees;
create policy auth_all on public.attendees
  for all to authenticated using (true) with check (true);

drop policy if exists auth_all on public."scheduledCalls";
create policy auth_all on public."scheduledCalls"
  for all to authenticated using (true) with check (true);

drop policy if exists auth_all on public."messageQueue";
create policy auth_all on public."messageQueue"
  for all to authenticated using (true) with check (true);

drop policy if exists auth_all on public.settings;
create policy auth_all on public.settings
  for all to authenticated using (true) with check (true);
