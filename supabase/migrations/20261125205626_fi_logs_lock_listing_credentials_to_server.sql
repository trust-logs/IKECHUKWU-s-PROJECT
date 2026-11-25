-- Public listing cards are selectable, but private account credentials are not.
revoke select on public.listings from anon,authenticated;
grant select (id,seller_id,platform,category,title,description,followers,engagement_rate,niche,audience_country,monetized,price_ngn,status,created_at,updated_at) on public.listings to anon,authenticated;
revoke select(account_log) on public.listings from anon,authenticated;
