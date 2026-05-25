-- Migration: Fix user metadata for existing users who don't have company_id in JWT claims
-- Note: auth.users columns are raw_app_meta_json/raw_user_meta_json in Supabase
-- Direct UPDATE via SQL requires service_role; use Edge Function instead.

-- Check which users need metadata updates (for manual Edge Function calls):
SELECT 
  u.id, 
  u.email,
  e.company_id,
  e.role
FROM auth.users u
JOIN public.employees e ON e.id = u.id::uuid
WHERE (u.raw_app_meta_json IS NULL OR (u.raw_app_meta_json::jsonb ? 'company_id') = false)
  AND e.company_id IS NOT NULL;

-- To fix: call update-employee Edge Function with service_role:
-- POST /functions/v1/update-employee
-- Headers: Authorization: Bearer <service_role_key>
-- Body: { "id": "user-uuid", "email": "user@example.com", "name": "Name", "lastName": "Last", "role": "EMPLOYEE", "companyId": "company-uuid" }

-- Example for user e4d003ca-8724-4ca9-9efe-45531b4cb85f:
-- curl -X POST https://YOUR-PROJECT.supabase.co/functions/v1/update-employee \
--   -H "Authorization: Bearer SERVICE_ROLE_KEY" \
--   -H "Content-Type: application/json" \
--   -d '{"id":"e4d003ca-8724-4ca9-9efe-45531b4cb85f","email":"user@example.com","name":"User","lastName":"Name","role":"EMPLOYEE","companyId":"a0000000-0000-0000-0000-000000000001"}'