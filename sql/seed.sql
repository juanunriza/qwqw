-- sql/seed.sql
-- Ejemplo de seed para Expense Tracker (Supabase)
-- Antes de ejecutar: reemplaza el user_uuid con el UUID real del usuario (auth.uid())

-- Uso con psql (ejemplo):
-- psql "$DATABASE_URL" -f sql/seed.sql

-- Puedes usar psql variable substitution; por defecto este script usa \set user_uuid ...

BEGIN;

-- Reemplaza este UUID por el del usuario real
\set user_uuid '00000000-0000-0000-0000-000000000000'

-- Crear cuentas de ejemplo
insert into accounts (id, user_id, name, currency, color, initial_balance, created_at)
values (gen_random_uuid(), :'user_uuid', 'Wallet', 'USD', '#FFB86B', 100.00, now()),
       (gen_random_uuid(), :'user_uuid', 'Checking', 'USD', '#6BCBFF', 500.00, now())
on conflict do nothing;

-- Crear categorías de ejemplo
insert into categories (id, user_id, name, type, color, created_at)
values (gen_random_uuid(), :'user_uuid', 'Groceries', 'expense', '#FF6B6B', now()),
       (gen_random_uuid(), :'user_uuid', 'Salary', 'income', '#4CAF50', now())
on conflict do nothing;

-- Crear tags
insert into tags (id, user_id, name, created_at)
values (gen_random_uuid(), :'user_uuid', 'food', now()),
       (gen_random_uuid(), :'user_uuid', 'monthly', now())
on conflict do nothing;

-- Insertar una transacción de ejemplo (usa las cuentas y categorías previamente creadas)
insert into transactions (id, user_id, account_id, category_id, amount, currency, type, happened_at, merchant, note, created_at)
select gen_random_uuid(), a.user_id, a.id, c.id, 45.50, 'USD', 'expense', now(), 'Supermarket', 'Compra semanal', now()
from accounts a
join categories c on a.user_id = c.user_id
where a.name = 'Wallet' and c.name = 'Groceries'
limit 1
on conflict do nothing;

-- Asociar tag a la transacción insertada
insert into transaction_tags (transaction_id, tag_id)
select t.id, tg.id
from transactions t
join tags tg on tg.user_id = t.user_id
where t.user_id = :'user_uuid'
limit 1
on conflict do nothing;

COMMIT;

-- Nota: Si ejecutas con psql, reemplaza la variable antes de ejecutar:
-- \set user_uuid 'your-user-uuid'
