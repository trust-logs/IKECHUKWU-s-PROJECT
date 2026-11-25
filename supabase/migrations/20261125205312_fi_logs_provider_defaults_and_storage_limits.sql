insert into public.provider_configs(key,label,enabled)
values ('logs','Logs Accounts API',true),('sms','SMS / Virtual Numbers API',true),('boosting','Social Boosting API',true)
on conflict(key) do nothing;
update storage.buckets set file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'] where id='avatars';
update storage.buckets set file_size_limit=10485760,allowed_mime_types=array['image/jpeg','image/png','image/webp','application/pdf'] where id='kyc-docs';
