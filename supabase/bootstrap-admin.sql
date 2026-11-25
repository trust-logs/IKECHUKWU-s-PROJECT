-- Run only after signing up with the F.I LOGS website.
-- Replace the placeholder with the exact email address you control.
insert into public.user_roles (user_id, role)
select id, 'super_admin'::public.app_role
from auth.users
where lower(email) = lower('REPLACE_WITH_YOUR_LOGIN_EMAIL')
on conflict (user_id, role) do nothing;

select u.email, r.role
from auth.users u join public.user_roles r on r.user_id = u.id
where lower(u.email) = lower('REPLACE_WITH_YOUR_LOGIN_EMAIL');
