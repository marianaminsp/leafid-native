/**
 * Ownership column on `public.scans`.
 *
 * Default `user_id` is added by `supabase/migrations/20260410_0002_scans_ownership_baseline.sql`.
 * If the console reports that column is missing, apply that migration (or run the SQL in the
 * Supabase SQL editor)—the remote schema is behind the repo.
 *
 * Optional override if your database uses another column name that stores the same auth user UUID
 * (e.g. legacy `profile_id` mapped to `auth.users.id`).
 */
export function getScansUserColumn(): string {
  const fromEnv = process.env.NEXT_PUBLIC_SCANS_USER_COLUMN?.trim()
  if (fromEnv && /^[a-z_][a-z0-9_]*$/i.test(fromEnv)) return fromEnv
  return 'user_id'
}
