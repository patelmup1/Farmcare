-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Farms Table
create table farms (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  name text not null,
  crop_type text not null,
  planting_date date not null,
  area real,
  area_unit text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table farms enable row level security;

-- Policy: Users can only see/edit their own farms
create policy "Users can view own farms" on farms for select using (auth.uid() = user_id);
create policy "Users can insert own farms" on farms for insert with check (auth.uid() = user_id);
create policy "Users can update own farms" on farms for update using (auth.uid() = user_id);
create policy "Users can delete own farms" on farms for delete using (auth.uid() = user_id);


-- Tasks Table
create table tasks (
  id uuid primary key default uuid_generate_v4(),
  farm_id uuid references farms(id) on delete cascade not null,
  date date not null,
  description text not null,
  is_completed boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table tasks enable row level security;

-- Policy: Users can only see/edit tasks for their farms (via join or simplified check)
-- Ideally check if farm belongs to user. For simplicity, we can rely on farm_id RLS if structured, 
-- or duplicate user_id column.
-- Adding user_id to tasks makes RLS easier:
alter table tasks add column user_id uuid references auth.users;

create policy "Users can view own tasks" on tasks for select using (auth.uid() = user_id);
create policy "Users can insert own tasks" on tasks for insert with check (auth.uid() = user_id);
create policy "Users can update own tasks" on tasks for update using (auth.uid() = user_id);
create policy "Users can delete own tasks" on tasks for delete using (auth.uid() = user_id);
