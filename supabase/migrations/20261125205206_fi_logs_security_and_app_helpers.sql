-- F.I LOGS application hardening applied to the active project. Non-destructive.
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

-- Client apps cannot forge payments, orders, wallet balances, or supplier outcomes.
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

create or replace function public.notify_wallet_transaction_status() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$ begin
 if tg_op='INSERT' or new.status is distinct from old.status then perform public.create_notification(new.user_id,'funding','Wallet '||coalesce(new.status,'update'),'Amount: '||coalesce(new.amount::text,''),'/wallet','wallet_transactions',new.id::text,new.status); end if; return new; end; $$;
create or replace function public.notify_order_status() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$ begin
 if tg_op='INSERT' or new.status is distinct from old.status then perform public.create_notification(new.buyer_id,'order','Order '||coalesce(new.status::text,'update'),'Your order status changed to '||coalesce(new.status::text,''),'/orders/'||new.id::text,'orders',new.id::text,new.status::text); perform public.create_notification(new.seller_id,'order','Order '||coalesce(new.status::text,'update'),'A buyer order changed to '||coalesce(new.status::text,''),'/orders/'||new.id::text,'orders',new.id::text,new.status::text); end if; return new; end; $$;
create or replace function public.notify_smm_order_status() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$ begin
 if tg_op='INSERT' or new.status is distinct from old.status then perform public.create_notification(new.user_id,'smm_order','SMM order '||coalesce(new.status,'update'),'Your SMM order is now '||coalesce(new.status,''),'/smm','smm_orders',new.id::text,new.status); end if; return new; end; $$;
create or replace function public.notify_sms_order_status() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$ begin
 if tg_op='INSERT' or new.status is distinct from old.status then perform public.create_notification(new.user_id,'sms_order','SMS order '||coalesce(new.status,'update'),'Your number order is now '||coalesce(new.status,''),'/sms','sms_orders',new.id::text,new.status); end if; return new; end; $$;
create or replace function public.notify_bill_payment_status() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$ begin
 if tg_op='INSERT' or new.status is distinct from old.status then perform public.create_notification(new.user_id,'bill_payment','Bill '||coalesce(new.status::text,'update'),'Bill payment of '||coalesce(new.amount::text,'')||' is '||coalesce(new.status::text,''),'/bills','bill_payments',new.id::text,new.status::text); end if; return new; end; $$;
drop trigger if exists kyc_approval_trigger on public.kyc_submissions;
create trigger kyc_approval_trigger after update of status on public.kyc_submissions for each row execute function public.handle_kyc_approval();
drop trigger if exists trg_notify_wallet_tx on public.wallet_transactions;
create trigger trg_notify_wallet_tx after insert or update of status on public.wallet_transactions for each row execute function public.notify_wallet_transaction_status();
drop trigger if exists trg_notify_orders on public.orders;
create trigger trg_notify_orders after insert or update of status on public.orders for each row execute function public.notify_order_status();
drop trigger if exists trg_notify_smm_orders on public.smm_orders;
create trigger trg_notify_smm_orders after insert or update of status on public.smm_orders for each row execute function public.notify_smm_order_status();
drop trigger if exists trg_notify_sms_orders on public.sms_orders;
create trigger trg_notify_sms_orders after insert or update of status on public.sms_orders for each row execute function public.notify_sms_order_status();
drop trigger if exists trg_notify_bill_payments on public.bill_payments;
create trigger trg_notify_bill_payments after insert or update of status on public.bill_payments for each row execute function public.notify_bill_payment_status();
