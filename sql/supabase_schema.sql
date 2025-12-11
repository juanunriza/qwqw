-- Supabase / Postgres schema for an Expense Tracker app
-- Includes: profiles, accounts, categories, transactions, tags, receipts
-- RLS policies restrict rows to the authenticated user (auth.uid())

-- Enable extensions commonly used in Supabase
create extension if not exists "pgcrypto";

-- Profiles: link to Supabase Auth `auth.users`
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  avatar_url text,
  locale text,
  created_at timestamptz default now()
);

-- Accounts: wallets/banks/cards
create table if not exists accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  name text not null,
  currency text not null default 'USD',
  color text,
  initial_balance numeric(12,2) default 0,
  created_at timestamptz default now()
);

-- Categories: expense/income/transfer
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  name text not null,
  type text not null check (type in ('expense','income','transfer')),
  color text,
  icon text,
  created_at timestamptz default now()
);

-- Transactions
create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  account_id uuid references accounts(id) on delete set null,
  category_id uuid references categories(id) on delete set null,
  amount numeric(12,2) not null,
  currency text not null default 'USD',
  type text not null check (type in ('expense','income','transfer')),
  happened_at timestamptz not null default now(),
  merchant text,
  note text,
  is_recurring boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Tags and many-to-many join for transactions
create table if not exists tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  name text not null,
  created_at timestamptz default now()
);

create table if not exists transaction_tags (
  transaction_id uuid references transactions(id) on delete cascade,
  tag_id uuid references tags(id) on delete cascade,
  primary key (transaction_id, tag_id)
);

-- Receipts (file metadata stored in Storage; app keeps URL)
create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid references transactions(id) on delete cascade,
  file_url text not null,
  file_size bigint,
  file_type text,
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_transactions_user_happened_at on transactions (user_id, happened_at desc);

-- Trigger to update `updated_at` on transactions
create or replace function on_update_timestamp()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trigger_transactions_updated_at on transactions;
create trigger trigger_transactions_updated_at
before update on transactions
for each row execute function on_update_timestamp();

-- Row Level Security (RLS) policies
alter table profiles enable row level security;
create policy "Profiles: owner only" on profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

alter table accounts enable row level security;
create policy "Accounts: owner only" on accounts
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table categories enable row level security;
create policy "Categories: owner only" on categories
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table transactions enable row level security;
create policy "Transactions: owner only" on transactions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table tags enable row level security;
create policy "Tags: owner only" on tags
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table receipts enable row level security;
create policy "Receipts: owner only" on receipts
  for all using (exists (select 1 from transactions t where t.id = receipts.transaction_id and t.user_id = auth.uid()))
  with check (exists (select 1 from transactions t where t.id = receipts.transaction_id and t.user_id = auth.uid()));

alter table transaction_tags enable row level security;
create policy "TransactionTags: owner only" on transaction_tags
  for all using (exists (select 1 from transactions t where t.id = transaction_tags.transaction_id and t.user_id = auth.uid()))
  with check (exists (select 1 from transactions t where t.id = transaction_tags.transaction_id and t.user_id = auth.uid()));

-- Notes:
-- - Use Supabase Auth; `profiles` row id = auth.uid().
-- - Run this SQL in Supabase SQL editor or via psql connected to the Supabase database.
-- - Adjust fields (currency, balances, precision) to your app needs.
