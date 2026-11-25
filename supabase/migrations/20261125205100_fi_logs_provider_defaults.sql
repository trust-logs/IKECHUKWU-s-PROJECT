insert into public.provider_configs(key,label,enabled)
values ('logs','Logs Accounts API',true),('sms','SMS / Virtual Numbers API',true),('boosting','Social Boosting API',true)
on conflict(key) do nothing;
