-- Enable pg_cron extension (must be enabled in Supabase dashboard first)
-- Dashboard → Database → Extensions → search "pg_cron" → Enable
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule auto-approval every hour
-- Approves pending proofs older than 24h with no rejections
SELECT cron.schedule(
  'auto-approve-stale-proofs',
  '0 * * * *',  -- every hour at minute 0
  $$SELECT public.auto_approve_stale_proofs()$$
);
