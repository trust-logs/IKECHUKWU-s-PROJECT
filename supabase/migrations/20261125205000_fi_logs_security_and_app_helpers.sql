-- F.I LOGS application hardening; non-destructive.
create or replace function public.guard_profile_protected_columns()
returns trigger language plpgsql security invoker set search_path=pg_catalog,public as $$
declare request_role text;
begin
 request_role := coalesce((nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role'),'');
 if request_role <> 'service_role' and (
   new.wallet_balance is distinct from old.wallet_balance or
   new.kyc_verified is distinct from old.kyc_verified or
   new.virtual_account_number is distinct from old.virtual_account_number or
   new.virtual_bank_name is distinct from old.virtual_bank_name
 ) then raise exception 'Protected profile fields require trusted server operations'; end if;
 return new;
end; $$;

create or replace function public.get_purchased_account_log(p_listing_id uuid)
returns text language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare v_log text; v_uid uuid := auth.uid();
begin
 if v_uid is null then raise exception 'Not authenticated'; end if;
 if public.has_role(v_uid,'admin'::public.app_role)
   or exists(select 1 from public.orders where listing_id=p_listing_id and buyer_id=v_uid and status in ('paid','delivered'))
   or exists(select 1 from public.listings where id=p_listing_id and seller_id=v_uid)
 then select account_log into v_log from public.listings where id=p_listing_id; return v_log; end if;
 raise exception 'Not authorized to view credentials for this listing';
end; $$;
revoke all on function public.get_purchased_account_log(uuid) from public,anon;
grant execute on function public.get_purchased_account_log(uuid) to authenticated,service_role;

-- Only trusted server functions can mutate orders, payment records and balances.
drop policy if exists "buyer create order" on public.orders;
drop policy if exists "seller or admin update order" on public.orders;
revoke insert,update,delete on public.orders from anon,authenticated;
grant select on public.orders to authenticated;
drop policy if exists "bill owner create" on public.bill_payments;
drop policy if exists "admin update bills" on public.bill_payments;
revoke insert,update,delete on public.bill_payments from anon,authenticated;
grant select on public.bill_payments to authenticated;
drop policy if exists "smm order owner create" on public.smm_orders;
drop policy if exists "admin update smm orders" on public.smm_orders;
revoke insert,update,delete on public.smm_orders from anon,authenticated;
grant select on public.smm_orders to authenticated;
drop policy if exists "sms order owner create" on public.sms_orders;
drop policy if exists "admin update sms orders" on public.sms_orders;
revoke insert,update,delete on public.sms_orders from anon,authenticated;
grant select on public.sms_orders to authenticated;
revoke insert,update,delete on public.wallet_transactions,public.virtual_accounts,public.wallets from anon,authenticated;
grant select on public.wallet_transactions,public.virtual_accounts,public.wallets to authenticated;

create table if not exists public.feature_flags(key text primary key,coming_soon boolean not null default false,message text,updated_at timestamptz not null default now());
alter table public.feature_flags enable row level security;
grant select on public.feature_flags to anon,authenticated;
grant all on public.feature_flags to service_role;
drop policy if exists "Feature flags readable" on public.feature_flags;
create policy "Feature flags readable" on public.feature_flags for select to anon,authenticated using(true);
drop policy if exists "Admins manage feature flags" on public.feature_flags;
create policy "Admins manage feature flags" on public.feature_flags for all to authenticated using(public.has_role((select auth.uid()),'admin'::public.app_role)) with check(public.has_role((select auth.uid()),'admin'::public.app_role));

-- Storage size/type restrictions.
update storage.buckets set file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'] where id='avatars';
update storage.buckets set file_size_limit=10485760,allowed_mime_types=array['image/jpeg','image/png','image/webp','application/pdf'] where id='kyc-docs';
