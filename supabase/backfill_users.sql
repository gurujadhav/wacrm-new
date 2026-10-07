-- ============================================================
-- BACKFILL EXISTING USERS CREATED BEFORE MIGRATIONS
-- ============================================================
DO $$
DECLARE
  u RECORD;
  new_acc_id UUID;
BEGIN
  FOR u IN SELECT * FROM auth.users LOOP
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE user_id = u.id) THEN
      INSERT INTO public.accounts (name)
      VALUES (COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)) || '''s Account')
      RETURNING id INTO new_acc_id;

      INSERT INTO public.profiles (user_id, full_name, email, account_id, account_role)
      VALUES (
        u.id,
        COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
        u.email,
        new_acc_id,
        'owner'::account_role_enum
      );
    END IF;
  END LOOP;
END $$;
