-- ============================================================
-- FRITURISME — Complete Database Schema
-- Run this in the Supabase SQL Editor (single execution)
-- ============================================================

-- ============================================================
-- 1. ENUMS
-- ============================================================

CREATE TYPE rating_category AS ENUM (
  'friturisme',
  'service',
  'prijs_kwaliteit',
  'friet',
  'bicky',
  'snacks',
  'sauzen'
);

CREATE TYPE frituur_plan AS ENUM ('free', 'premium');

-- ============================================================
-- 2. TABLES
-- ============================================================

-- Users (extends Supabase auth.users)
-- NOTE: No FK to auth.users so seed data works in SQL editor.
-- The handle_new_user trigger handles the real auth link in production.
CREATE TABLE public.users (
  id          UUID PRIMARY KEY,
  email       TEXT NOT NULL UNIQUE,
  name        TEXT NOT NULL,
  avatar_url  TEXT,
  favorite_snacks TEXT[] DEFAULT '{}',
  reviewer_type TEXT DEFAULT 'Nieuweling',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Frituren (fry shops)
CREATE TABLE public.frituren (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  address         TEXT NOT NULL,
  city            TEXT NOT NULL,
  latitude        DOUBLE PRECISION NOT NULL,
  longitude       DOUBLE PRECISION NOT NULL,
  google_place_id TEXT UNIQUE,
  phone           TEXT,
  opening_hours   JSONB DEFAULT '{}',
  claimed         BOOLEAN NOT NULL DEFAULT false,
  claimed_by      UUID REFERENCES public.users(id) ON DELETE SET NULL,
  plan            frituur_plan NOT NULL DEFAULT 'free',
  verified        BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Check-ins
CREATE TABLE public.check_ins (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  frituur_id  UUID NOT NULL REFERENCES public.frituren(id) ON DELETE CASCADE,
  snacks      TEXT[] DEFAULT '{}',
  sauces      TEXT[] DEFAULT '{}',
  text        TEXT,
  photo_url   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ratings (per check-in, per category)
CREATE TABLE public.ratings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  check_in_id UUID NOT NULL REFERENCES public.check_ins(id) ON DELETE CASCADE,
  category    rating_category NOT NULL,
  score       SMALLINT NOT NULL CHECK (score >= 1 AND score <= 5),
  UNIQUE (check_in_id, category)
);

-- Owner replies
CREATE TABLE public.owner_replies (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  check_in_id UUID NOT NULL REFERENCES public.check_ins(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  text        TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 3. INDEXES
-- ============================================================

CREATE INDEX idx_frituren_city ON public.frituren(city);
CREATE INDEX idx_frituren_location ON public.frituren(latitude, longitude);
CREATE INDEX idx_frituren_claimed_by ON public.frituren(claimed_by) WHERE claimed_by IS NOT NULL;

CREATE INDEX idx_check_ins_user_id ON public.check_ins(user_id);
CREATE INDEX idx_check_ins_frituur_id ON public.check_ins(frituur_id);
CREATE INDEX idx_check_ins_created_at ON public.check_ins(created_at DESC);

CREATE INDEX idx_ratings_check_in_id ON public.ratings(check_in_id);
CREATE INDEX idx_ratings_category ON public.ratings(category);

CREATE INDEX idx_owner_replies_check_in_id ON public.owner_replies(check_in_id);

-- ============================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.frituren ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.owner_replies ENABLE ROW LEVEL SECURITY;

-- ---- USERS ----
CREATE POLICY "Users are viewable by everyone"
  ON public.users FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile"
  ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- ---- FRITUREN ----
CREATE POLICY "Frituren are viewable by everyone"
  ON public.frituren FOR SELECT USING (true);

CREATE POLICY "Authenticated users can add frituren"
  ON public.frituren FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Owners can update own frituur"
  ON public.frituren FOR UPDATE
  USING (auth.uid() = claimed_by) WITH CHECK (auth.uid() = claimed_by);

-- ---- CHECK-INS ----
CREATE POLICY "Check-ins are viewable by everyone"
  ON public.check_ins FOR SELECT USING (true);

CREATE POLICY "Users can create own check-ins"
  ON public.check_ins FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own check-ins"
  ON public.check_ins FOR UPDATE
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own check-ins"
  ON public.check_ins FOR DELETE USING (auth.uid() = user_id);

-- ---- RATINGS ----
CREATE POLICY "Ratings are viewable by everyone"
  ON public.ratings FOR SELECT USING (true);

CREATE POLICY "Users can create ratings on own check-ins"
  ON public.ratings FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.check_ins
      WHERE check_ins.id = check_in_id AND check_ins.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update ratings on own check-ins"
  ON public.ratings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.check_ins
      WHERE check_ins.id = check_in_id AND check_ins.user_id = auth.uid()
    )
  );

-- ---- OWNER REPLIES ----
CREATE POLICY "Owner replies are viewable by everyone"
  ON public.owner_replies FOR SELECT USING (true);

CREATE POLICY "Owners can reply on own frituur check-ins"
  ON public.owner_replies FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.check_ins ci
      JOIN public.frituren f ON f.id = ci.frituur_id
      WHERE ci.id = check_in_id AND f.claimed = true AND f.claimed_by = auth.uid()
    )
  );

CREATE POLICY "Owners can update own replies"
  ON public.owner_replies FOR UPDATE
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Owners can delete own replies"
  ON public.owner_replies FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- 5. HELPER FUNCTIONS
-- ============================================================

-- Auto-create a public.users row when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Try to create the trigger. If it fails (permissions), create it manually
-- via Supabase Dashboard → Database → Triggers, or run this in the
-- Supabase Dashboard SQL editor with "Run as" set to "postgres" role.
DO $$
BEGIN
  CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE 'Could not create trigger on auth.users. Create it manually in Supabase Dashboard → Database → Hooks/Triggers.';
END $$;

-- Average rating per frituur
CREATE OR REPLACE FUNCTION public.get_frituur_avg_ratings(frituur_uuid UUID)
RETURNS TABLE (
  category rating_category,
  avg_score NUMERIC,
  total_ratings BIGINT
) AS $$
  SELECT
    r.category,
    ROUND(AVG(r.score), 1) AS avg_score,
    COUNT(*) AS total_ratings
  FROM public.ratings r
  JOIN public.check_ins ci ON ci.id = r.check_in_id
  WHERE ci.frituur_id = frituur_uuid
  GROUP BY r.category
  ORDER BY r.category;
$$ LANGUAGE sql STABLE;

-- ============================================================
-- 6. SEED DATA
-- ============================================================

-- 6a. Seed 5 test users (directly in public.users, no auth.users needed)
-- In production, the handle_new_user trigger creates these automatically on signup.
-- For testing login, create users via Supabase Dashboard → Authentication → Users.
INSERT INTO public.users (id, email, name, avatar_url, favorite_snacks, reviewer_type) VALUES
  ('a1b2c3d4-0001-4000-a000-000000000001', 'jan@test.be',  'Jan De Fransen',  NULL, ARRAY['Bicky','Stoofvlees','Frikandel'],              'De Bicky Connaisseur'),
  ('a1b2c3d4-0001-4000-a000-000000000002', 'lies@test.be', 'Lies Van Hoeck',  NULL, ARRAY['Garnaalkroket','Kaaskroket','Loempia'],         'Krokettenkoningin'),
  ('a1b2c3d4-0001-4000-a000-000000000003', 'bram@test.be', 'Bram Peeters',    NULL, ARRAY['Mexicano','Hamburger','Mitraillette'],          'Sauzenspecialist'),
  ('a1b2c3d4-0001-4000-a000-000000000004', 'noor@test.be', 'Noor Claes',      NULL, ARRAY['Viandel','Kipnuggets','Gehaktbal'],             'Frietfluisteraar'),
  ('a1b2c3d4-0001-4000-a000-000000000005', 'wout@test.be', 'Wout Janssens',   NULL, ARRAY['Bicky','Mexicano','Stoofvlees','Frikandel'],    'Nieuweling');

-- 6b. Seed 20 frituren in Gent
INSERT INTO public.frituren (id, name, address, city, latitude, longitude, phone, claimed, verified, opening_hours) VALUES
  ('f0000000-0000-4000-a000-000000000001', 'Frituur ''t Gents Frietkot',    'Groentenmarkt 12',              'Gent', 51.05625, 3.72148, '09 223 44 01', false, true,  '{"ma":"11:30-22:00","di":"gesloten","wo":"11:30-22:00","do":"11:30-22:00","vr":"11:30-23:00","za":"11:30-23:00","zo":"12:00-21:00"}'),
  ('f0000000-0000-4000-a000-000000000002', 'Frietketel Overpoort',          'Overpoortstraat 67',            'Gent', 51.04201, 3.72630, '09 265 11 22', false, true,  '{"ma":"16:00-03:00","di":"16:00-03:00","wo":"16:00-03:00","do":"16:00-04:00","vr":"16:00-05:00","za":"16:00-05:00","zo":"16:00-01:00"}'),
  ('f0000000-0000-4000-a000-000000000003', 'Frituur De Papzak',             'Vrijdagmarkt 3',                'Gent', 51.05773, 3.72542, '09 233 55 77', false, true,  '{"ma":"11:00-21:30","di":"11:00-21:30","wo":"11:00-21:30","do":"11:00-21:30","vr":"11:00-22:30","za":"11:00-22:30","zo":"12:00-21:00"}'),
  ('f0000000-0000-4000-a000-000000000004', 'Bij Martine',                   'Brabantdam 135',                'Gent', 51.04853, 3.73401, '09 224 88 10', true,  true,  '{"ma":"11:00-21:00","di":"11:00-21:00","wo":"11:00-21:00","do":"11:00-21:00","vr":"11:00-22:00","za":"11:00-22:00","zo":"gesloten"}'),
  ('f0000000-0000-4000-a000-000000000005', 'Frituur Sint-Jacobs',           'Sint-Jacobsnieuwstraat 2',      'Gent', 51.05490, 3.72810, '09 225 60 03', false, false, '{"ma":"11:30-21:00","di":"gesloten","wo":"11:30-21:00","do":"11:30-21:00","vr":"11:30-22:00","za":"11:30-22:00","zo":"12:00-20:00"}'),
  ('f0000000-0000-4000-a000-000000000006', 'Frietje van ''t Zuid',          'Vlaamsekaai 8',                 'Gent', 51.04389, 3.72890, '09 267 33 21', false, true,  '{"ma":"11:30-21:30","di":"11:30-21:30","wo":"11:30-21:30","do":"11:30-21:30","vr":"11:30-22:30","za":"11:30-22:30","zo":"12:00-21:00"}'),
  ('f0000000-0000-4000-a000-000000000007', 'Frituur De Vlaamse Leeuw',      'Veldstraat 98',                 'Gent', 51.05132, 3.72120, '09 228 41 55', false, true,  '{"ma":"11:00-21:30","di":"11:00-21:30","wo":"11:00-21:30","do":"11:00-21:30","vr":"11:00-22:30","za":"11:00-23:00","zo":"12:00-21:00"}'),
  ('f0000000-0000-4000-a000-000000000008', 'Den Bansen',                    'Sleepstraat 44',                'Gent', 51.06131, 3.72870, '09 233 17 88', false, false, '{"ma":"gesloten","di":"11:30-21:00","wo":"11:30-21:00","do":"11:30-21:00","vr":"11:30-22:00","za":"11:30-22:00","zo":"12:00-20:00"}'),
  ('f0000000-0000-4000-a000-000000000009', '''t Frituurke',                 'Coupure Links 155',             'Gent', 51.05340, 3.71530, '09 221 90 44', false, true,  '{"ma":"11:30-21:30","di":"11:30-21:30","wo":"11:30-21:30","do":"11:30-21:30","vr":"11:30-22:30","za":"11:30-22:30","zo":"12:00-21:00"}'),
  ('f0000000-0000-4000-a000-000000000010', 'Frituur Gentbrugge',            'Braemkasteelstraat 1',          'Gent', 51.03872, 3.74520, '09 230 28 77', false, false, '{"ma":"11:30-21:00","di":"gesloten","wo":"11:30-21:00","do":"11:30-21:00","vr":"11:30-22:00","za":"11:30-22:00","zo":"12:00-20:30"}'),
  ('f0000000-0000-4000-a000-000000000011', 'Chez Fernand',                  'Antwerpsesteenweg 18',          'Gent', 51.06500, 3.74200, '09 226 45 33', false, true,  '{"ma":"11:00-21:00","di":"11:00-21:00","wo":"11:00-21:00","do":"11:00-21:00","vr":"11:00-22:00","za":"11:00-22:00","zo":"12:00-20:30"}'),
  ('f0000000-0000-4000-a000-000000000012', 'Frietstraat',                   'Dendermondsesteenweg 72',       'Gent', 51.06010, 3.74850, '09 252 11 64', false, false, '{"ma":"11:30-21:00","di":"11:30-21:00","wo":"gesloten","do":"11:30-21:00","vr":"11:30-22:00","za":"11:30-22:00","zo":"12:00-20:00"}'),
  ('f0000000-0000-4000-a000-000000000013', 'Frituur Muide',                 'Meulesteedsesteenweg 201',      'Gent', 51.06750, 3.73810, '09 259 87 23', false, false, '{"ma":"11:30-21:00","di":"11:30-21:00","wo":"11:30-21:00","do":"gesloten","vr":"11:30-22:00","za":"11:30-22:00","zo":"12:00-20:00"}'),
  ('f0000000-0000-4000-a000-000000000014', 'De Gouden Saté',                'Brugsepoortstraat 15',          'Gent', 51.05620, 3.71200, '09 234 56 78', false, true,  '{"ma":"11:30-21:30","di":"11:30-21:30","wo":"11:30-21:30","do":"11:30-21:30","vr":"11:30-22:30","za":"11:30-22:30","zo":"gesloten"}'),
  ('f0000000-0000-4000-a000-000000000015', 'Frituur Max',                   'Wondelgemstraat 88',            'Gent', 51.07210, 3.71900, '09 253 44 12', false, false, '{"ma":"11:00-21:00","di":"gesloten","wo":"11:00-21:00","do":"11:00-21:00","vr":"11:00-22:00","za":"11:00-22:00","zo":"12:00-20:00"}'),
  ('f0000000-0000-4000-a000-000000000016', 'Frituur Patje',                 'Lange Violettestraat 31',       'Gent', 51.05180, 3.71850, '09 222 03 91', false, true,  '{"ma":"11:30-21:00","di":"11:30-21:00","wo":"11:30-21:00","do":"11:30-21:00","vr":"11:30-22:30","za":"11:30-22:30","zo":"12:00-21:00"}'),
  ('f0000000-0000-4000-a000-000000000017', 'Het Bickyhuis',                 'Sint-Pietersnieuwstraat 112',   'Gent', 51.04450, 3.72350, '09 264 77 55', false, true,  '{"ma":"11:30-22:00","di":"11:30-22:00","wo":"11:30-22:00","do":"11:30-22:00","vr":"11:30-23:30","za":"11:30-23:30","zo":"12:00-22:00"}'),
  ('f0000000-0000-4000-a000-000000000018', 'Frituur De Kouter',             'Kouter 45',                     'Gent', 51.04890, 3.72380, '09 223 66 80', false, false, '{"ma":"11:30-21:00","di":"11:30-21:00","wo":"gesloten","do":"11:30-21:00","vr":"11:30-22:00","za":"11:30-22:00","zo":"12:00-20:30"}'),
  ('f0000000-0000-4000-a000-000000000019', 'Nen Dansen',                    'Nieuwpoort 4',                  'Gent', 51.05870, 3.72010, '09 233 22 49', false, true,  '{"ma":"11:00-21:30","di":"11:00-21:30","wo":"11:00-21:30","do":"11:00-21:30","vr":"11:00-22:30","za":"11:00-23:00","zo":"12:00-21:00"}'),
  ('f0000000-0000-4000-a000-000000000020', 'Frituur Ledeberg',              'Hoveniersstraat 62',            'Gent', 51.03680, 3.73950, '09 231 08 37', false, false, '{"ma":"11:30-21:00","di":"gesloten","wo":"11:30-21:00","do":"11:30-21:00","vr":"11:30-22:00","za":"11:30-22:00","zo":"12:00-20:00"}');

-- Set Bij Martine as claimed by Jan
UPDATE public.frituren
SET claimed_by = 'a1b2c3d4-0001-4000-a000-000000000001'
WHERE id = 'f0000000-0000-4000-a000-000000000004';

-- 6c. Seed 30 check-ins
INSERT INTO public.check_ins (id, user_id, frituur_id, snacks, sauces, text, created_at) VALUES
  ('c0000000-0000-4000-a000-000000000001', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000001', ARRAY['Bicky','Friet'],               ARRAY['Mayonaise','Ketchup'],       'Propere friet, krokant van buiten. Den bicky was legendarisch.',     now() - interval '2 days'),
  ('c0000000-0000-4000-a000-000000000002', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000003', ARRAY['Stoofvlees','Friet'],           ARRAY['Stoofvleessaus'],            'Stoofvlees zoals bij mijn bomma. Top.',                              now() - interval '5 days'),
  ('c0000000-0000-4000-a000-000000000003', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000007', ARRAY['Frikandel','Friet'],            ARRAY['Curryketchup'],              NULL,                                                                  now() - interval '8 days'),
  ('c0000000-0000-4000-a000-000000000004', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000017', ARRAY['Bicky','Bicky'],                ARRAY['Mayonaise','Pickles'],       'Twee bickys besteld want de eerste was te goed om alleen te staan.', now() - interval '12 days'),
  ('c0000000-0000-4000-a000-000000000005', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000009', ARRAY['Mexicano','Friet'],             ARRAY['Samoerai'],                  'Spicy mexicano, perfecte crunch.',                                   now() - interval '15 days'),
  ('c0000000-0000-4000-a000-000000000006', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000002', ARRAY['Mitraillette','Friet'],         ARRAY['Andalouse','Mayonaise'],     'Na een nachtje Overpoort moet dat.',                                 now() - interval '20 days'),
  ('c0000000-0000-4000-a000-000000000007', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000014', ARRAY['Bicky','Garnaalkroket'],        ARRAY['Cocktail'],                  'De garnaalkroket hier is echt de max.',                              now() - interval '25 days'),
  ('c0000000-0000-4000-a000-000000000008', 'a1b2c3d4-0001-4000-a000-000000000001', 'f0000000-0000-4000-a000-000000000006', ARRAY['Friet'],                        ARRAY['Mayonaise'],                 'Puur. Alleen friet. Meer hebt ge niet nodig.',                       now() - interval '30 days'),
  ('c0000000-0000-4000-a000-000000000009', 'a1b2c3d4-0001-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000001', ARRAY['Garnaalkroket','Friet'],        ARRAY['Cocktail'],                  'Perfecte garnaalkroket. Krokant, goed gevuld.',                     now() - interval '1 day'),
  ('c0000000-0000-4000-a000-000000000010', 'a1b2c3d4-0001-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000004', ARRAY['Kaaskroket','Loempia','Friet'], ARRAY['Zoete chili'],               'Kaaskroket was zalig, loempia iets te vettig.',                     now() - interval '4 days'),
  ('c0000000-0000-4000-a000-000000000011', 'a1b2c3d4-0001-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000011', ARRAY['Garnaalkroket','Friet'],        ARRAY['Tartaar'],                   'Chez Fernand doet een faire garnaalkroket.',                        now() - interval '9 days'),
  ('c0000000-0000-4000-a000-000000000012', 'a1b2c3d4-0001-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000016', ARRAY['Loempia','Friet'],              ARRAY['Zoete chili','Samoerai'],     NULL,                                                                  now() - interval '14 days'),
  ('c0000000-0000-4000-a000-000000000013', 'a1b2c3d4-0001-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000019', ARRAY['Kaaskroket','Friet'],           ARRAY['Mayonaise'],                 'Altijd goe hier. Snelle bediening ook.',                            now() - interval '18 days'),
  ('c0000000-0000-4000-a000-000000000014', 'a1b2c3d4-0001-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000003', ARRAY['Garnaalkroket','Kaaskroket'],   ARRAY['Cocktail','Tartaar'],        'Double kroket actie. Geen spijt.',                                  now() - interval '22 days'),
  ('c0000000-0000-4000-a000-000000000015', 'a1b2c3d4-0001-4000-a000-000000000002', 'f0000000-0000-4000-a000-000000000010', ARRAY['Loempia','Friet'],              ARRAY['Zoete chili'],               'Gentbrugge represent.',                                              now() - interval '28 days'),
  ('c0000000-0000-4000-a000-000000000016', 'a1b2c3d4-0001-4000-a000-000000000003', 'f0000000-0000-4000-a000-000000000002', ARRAY['Mexicano','Friet'],             ARRAY['Samoerai','Andalouse'],      '03:00 s nachts. Precies wat ge nodig hebt.',                        now() - interval '3 days'),
  ('c0000000-0000-4000-a000-000000000017', 'a1b2c3d4-0001-4000-a000-000000000003', 'f0000000-0000-4000-a000-000000000005', ARRAY['Hamburger','Friet'],            ARRAY['Ketchup','Mayonaise'],       'Eerlijke hamburger, goeie prijs.',                                  now() - interval '7 days'),
  ('c0000000-0000-4000-a000-000000000018', 'a1b2c3d4-0001-4000-a000-000000000003', 'f0000000-0000-4000-a000-000000000008', ARRAY['Mitraillette','Friet'],         ARRAY['Andalouse'],                 'Mitraillette zo groot als mijn onderarm.',                          now() - interval '11 days'),
  ('c0000000-0000-4000-a000-000000000019', 'a1b2c3d4-0001-4000-a000-000000000003', 'f0000000-0000-4000-a000-000000000012', ARRAY['Mexicano','Hamburger'],         ARRAY['Samoerai'],                  NULL,                                                                  now() - interval '16 days'),
  ('c0000000-0000-4000-a000-000000000020', 'a1b2c3d4-0001-4000-a000-000000000003', 'f0000000-0000-4000-a000-000000000017', ARRAY['Mitraillette','Friet'],         ARRAY['Samoerai','Ketchup'],        'Het Bickyhuis maakt ook mitraillettes. Goedgekeurd.',               now() - interval '21 days'),
  ('c0000000-0000-4000-a000-000000000021', 'a1b2c3d4-0001-4000-a000-000000000003', 'f0000000-0000-4000-a000-000000000015', ARRAY['Hamburger','Friet'],            ARRAY['Ketchup'],                   'Simpel maar proper.',                                                now() - interval '27 days'),
  ('c0000000-0000-4000-a000-000000000022', 'a1b2c3d4-0001-4000-a000-000000000004', 'f0000000-0000-4000-a000-000000000001', ARRAY['Viandel','Kipnuggets','Friet'], ARRAY['Mayonaise'],                 'Goeie kipnuggets, viandel was ok.',                                 now() - interval '2 days'),
  ('c0000000-0000-4000-a000-000000000023', 'a1b2c3d4-0001-4000-a000-000000000004', 'f0000000-0000-4000-a000-000000000006', ARRAY['Gehaktbal','Friet'],            ARRAY['Tomatensaus'],               'Gehaktbal in tomatensaus is de comfort food die ge nodig hebt.',    now() - interval '6 days'),
  ('c0000000-0000-4000-a000-000000000024', 'a1b2c3d4-0001-4000-a000-000000000004', 'f0000000-0000-4000-a000-000000000013', ARRAY['Kipnuggets','Friet'],           ARRAY['Curryketchup'],              NULL,                                                                  now() - interval '13 days'),
  ('c0000000-0000-4000-a000-000000000025', 'a1b2c3d4-0001-4000-a000-000000000004', 'f0000000-0000-4000-a000-000000000018', ARRAY['Viandel','Friet'],              ARRAY['Mayonaise','Ketchup'],       'Frituur De Kouter doet een deftige viandel.',                       now() - interval '19 days'),
  ('c0000000-0000-4000-a000-000000000026', 'a1b2c3d4-0001-4000-a000-000000000004', 'f0000000-0000-4000-a000-000000000009', ARRAY['Gehaktbal','Kipnuggets'],       ARRAY['Tomatensaus'],               'Iets te lang moeten wachten, maar het was het waard.',              now() - interval '24 days'),
  ('c0000000-0000-4000-a000-000000000027', 'a1b2c3d4-0001-4000-a000-000000000005', 'f0000000-0000-4000-a000-000000000007', ARRAY['Bicky','Mexicano','Friet'],     ARRAY['Samoerai','Mayonaise'],      'Eerste keer hier. Wa een ontdekking!',                              now() - interval '1 day'),
  ('c0000000-0000-4000-a000-000000000028', 'a1b2c3d4-0001-4000-a000-000000000005', 'f0000000-0000-4000-a000-000000000020', ARRAY['Stoofvlees','Friet'],           ARRAY['Stoofvleessaus'],            'Ledeberg heeft een hidden gem.',                                    now() - interval '10 days'),
  ('c0000000-0000-4000-a000-000000000029', 'a1b2c3d4-0001-4000-a000-000000000005', 'f0000000-0000-4000-a000-000000000004', ARRAY['Frikandel','Bicky'],            ARRAY['Curryketchup','Mayonaise'],  'Bij Martine is altijd gezellig.',                                   now() - interval '17 days'),
  ('c0000000-0000-4000-a000-000000000030', 'a1b2c3d4-0001-4000-a000-000000000005', 'f0000000-0000-4000-a000-000000000019', ARRAY['Mexicano','Friet'],             ARRAY['Samoerai'],                  NULL,                                                                  now() - interval '23 days');

-- 6d. Seed ratings
INSERT INTO public.ratings (check_in_id, category, score) VALUES
  ('c0000000-0000-4000-a000-000000000001', 'friturisme', 5), ('c0000000-0000-4000-a000-000000000001', 'service', 4), ('c0000000-0000-4000-a000-000000000001', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000001', 'friet', 5), ('c0000000-0000-4000-a000-000000000001', 'bicky', 5),
  ('c0000000-0000-4000-a000-000000000002', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000002', 'service', 4), ('c0000000-0000-4000-a000-000000000002', 'prijs_kwaliteit', 3), ('c0000000-0000-4000-a000-000000000002', 'friet', 4), ('c0000000-0000-4000-a000-000000000002', 'snacks', 5),
  ('c0000000-0000-4000-a000-000000000003', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000003', 'friet', 4), ('c0000000-0000-4000-a000-000000000003', 'snacks', 3),
  ('c0000000-0000-4000-a000-000000000004', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000004', 'service', 5), ('c0000000-0000-4000-a000-000000000004', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000004', 'bicky', 5),
  ('c0000000-0000-4000-a000-000000000005', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000005', 'service', 3), ('c0000000-0000-4000-a000-000000000005', 'friet', 4), ('c0000000-0000-4000-a000-000000000005', 'snacks', 4),
  ('c0000000-0000-4000-a000-000000000006', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000006', 'service', 3), ('c0000000-0000-4000-a000-000000000006', 'prijs_kwaliteit', 3), ('c0000000-0000-4000-a000-000000000006', 'friet', 3), ('c0000000-0000-4000-a000-000000000006', 'snacks', 3),
  ('c0000000-0000-4000-a000-000000000007', 'friturisme', 5), ('c0000000-0000-4000-a000-000000000007', 'service', 4), ('c0000000-0000-4000-a000-000000000007', 'snacks', 5), ('c0000000-0000-4000-a000-000000000007', 'sauzen', 4),
  ('c0000000-0000-4000-a000-000000000008', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000008', 'friet', 5), ('c0000000-0000-4000-a000-000000000008', 'sauzen', 4),
  ('c0000000-0000-4000-a000-000000000009', 'friturisme', 5), ('c0000000-0000-4000-a000-000000000009', 'service', 5), ('c0000000-0000-4000-a000-000000000009', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000009', 'snacks', 5),
  ('c0000000-0000-4000-a000-000000000010', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000010', 'service', 4), ('c0000000-0000-4000-a000-000000000010', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000010', 'snacks', 3), ('c0000000-0000-4000-a000-000000000010', 'sauzen', 4),
  ('c0000000-0000-4000-a000-000000000011', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000011', 'service', 3), ('c0000000-0000-4000-a000-000000000011', 'snacks', 4),
  ('c0000000-0000-4000-a000-000000000012', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000012', 'friet', 3), ('c0000000-0000-4000-a000-000000000012', 'snacks', 3), ('c0000000-0000-4000-a000-000000000012', 'sauzen', 4),
  ('c0000000-0000-4000-a000-000000000013', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000013', 'service', 5), ('c0000000-0000-4000-a000-000000000013', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000013', 'snacks', 4),
  ('c0000000-0000-4000-a000-000000000014', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000014', 'snacks', 5), ('c0000000-0000-4000-a000-000000000014', 'sauzen', 4),
  ('c0000000-0000-4000-a000-000000000015', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000015', 'service', 3), ('c0000000-0000-4000-a000-000000000015', 'friet', 3), ('c0000000-0000-4000-a000-000000000015', 'snacks', 2),
  ('c0000000-0000-4000-a000-000000000016', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000016', 'service', 4), ('c0000000-0000-4000-a000-000000000016', 'friet', 3), ('c0000000-0000-4000-a000-000000000016', 'snacks', 4), ('c0000000-0000-4000-a000-000000000016', 'sauzen', 5),
  ('c0000000-0000-4000-a000-000000000017', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000017', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000017', 'snacks', 3),
  ('c0000000-0000-4000-a000-000000000018', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000018', 'service', 3), ('c0000000-0000-4000-a000-000000000018', 'prijs_kwaliteit', 5), ('c0000000-0000-4000-a000-000000000018', 'friet', 4), ('c0000000-0000-4000-a000-000000000018', 'snacks', 4),
  ('c0000000-0000-4000-a000-000000000019', 'friturisme', 2), ('c0000000-0000-4000-a000-000000000019', 'snacks', 3), ('c0000000-0000-4000-a000-000000000019', 'sauzen', 3),
  ('c0000000-0000-4000-a000-000000000020', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000020', 'service', 5), ('c0000000-0000-4000-a000-000000000020', 'prijs_kwaliteit', 3), ('c0000000-0000-4000-a000-000000000020', 'friet', 4), ('c0000000-0000-4000-a000-000000000020', 'snacks', 4),
  ('c0000000-0000-4000-a000-000000000021', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000021', 'service', 3), ('c0000000-0000-4000-a000-000000000021', 'friet', 3),
  ('c0000000-0000-4000-a000-000000000022', 'friturisme', 5), ('c0000000-0000-4000-a000-000000000022', 'service', 4), ('c0000000-0000-4000-a000-000000000022', 'snacks', 4), ('c0000000-0000-4000-a000-000000000022', 'sauzen', 3),
  ('c0000000-0000-4000-a000-000000000023', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000023', 'service', 4), ('c0000000-0000-4000-a000-000000000023', 'prijs_kwaliteit', 3), ('c0000000-0000-4000-a000-000000000023', 'friet', 4), ('c0000000-0000-4000-a000-000000000023', 'snacks', 4),
  ('c0000000-0000-4000-a000-000000000024', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000024', 'friet', 3), ('c0000000-0000-4000-a000-000000000024', 'snacks', 2),
  ('c0000000-0000-4000-a000-000000000025', 'friturisme', 3), ('c0000000-0000-4000-a000-000000000025', 'service', 4), ('c0000000-0000-4000-a000-000000000025', 'prijs_kwaliteit', 3), ('c0000000-0000-4000-a000-000000000025', 'snacks', 3),
  ('c0000000-0000-4000-a000-000000000026', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000026', 'service', 2), ('c0000000-0000-4000-a000-000000000026', 'snacks', 4), ('c0000000-0000-4000-a000-000000000026', 'sauzen', 3),
  ('c0000000-0000-4000-a000-000000000027', 'friturisme', 5), ('c0000000-0000-4000-a000-000000000027', 'service', 4), ('c0000000-0000-4000-a000-000000000027', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000027', 'friet', 5), ('c0000000-0000-4000-a000-000000000027', 'bicky', 4), ('c0000000-0000-4000-a000-000000000027', 'snacks', 4), ('c0000000-0000-4000-a000-000000000027', 'sauzen', 5),
  ('c0000000-0000-4000-a000-000000000028', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000028', 'service', 4), ('c0000000-0000-4000-a000-000000000028', 'prijs_kwaliteit', 5), ('c0000000-0000-4000-a000-000000000028', 'friet', 4), ('c0000000-0000-4000-a000-000000000028', 'snacks', 5),
  ('c0000000-0000-4000-a000-000000000029', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000029', 'service', 5), ('c0000000-0000-4000-a000-000000000029', 'prijs_kwaliteit', 4), ('c0000000-0000-4000-a000-000000000029', 'bicky', 4), ('c0000000-0000-4000-a000-000000000029', 'snacks', 3),
  ('c0000000-0000-4000-a000-000000000030', 'friturisme', 4), ('c0000000-0000-4000-a000-000000000030', 'service', 3), ('c0000000-0000-4000-a000-000000000030', 'friet', 4), ('c0000000-0000-4000-a000-000000000030', 'snacks', 3), ('c0000000-0000-4000-a000-000000000030', 'sauzen', 4);

-- 6e. Owner replies
INSERT INTO public.owner_replies (check_in_id, user_id, text, created_at) VALUES
  ('c0000000-0000-4000-a000-000000000010', 'a1b2c3d4-0001-4000-a000-000000000001', 'Merci Lies! Die loempia gaan we verbeteren, beloofd!', now() - interval '3 days'),
  ('c0000000-0000-4000-a000-000000000029', 'a1b2c3d4-0001-4000-a000-000000000001', 'Altijd welkom Wout! Bedankt voor de mooie review.',    now() - interval '16 days');

-- ============================================================
-- Verify:
-- SELECT count(*) FROM public.users;         -- 5
-- SELECT count(*) FROM public.frituren;      -- 20
-- SELECT count(*) FROM public.check_ins;     -- 30
-- SELECT count(*) FROM public.ratings;       -- 126
-- SELECT count(*) FROM public.owner_replies; -- 2
-- ============================================================