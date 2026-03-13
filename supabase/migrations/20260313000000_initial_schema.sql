-- ═══════════════════════════════════════════════════════════
-- PROFILES (auto-synced from auth.users)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read profiles"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data ->> 'display_name',
      NEW.raw_user_meta_data ->> 'full_name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.raw_user_meta_data ->> 'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════
-- GROUPS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  invite_code TEXT NOT NULL UNIQUE DEFAULT substring(md5(random()::text) from 1 for 8),
  max_members INTEGER NOT NULL DEFAULT 20,
  created_by UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.group_members (
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read their groups"
  ON public.groups FOR SELECT
  USING (id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Authenticated users can create groups"
  ON public.groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Creator can update group"
  ON public.groups FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Creator can delete group"
  ON public.groups FOR DELETE
  USING (auth.uid() = created_by);

CREATE POLICY "Members can see co-members"
  ON public.group_members FOR SELECT
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can join groups"
  ON public.group_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave groups"
  ON public.group_members FOR DELETE
  USING (auth.uid() = user_id);

-- Auto-add creator as admin member
CREATE OR REPLACE FUNCTION public.auto_add_group_creator()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_group_created
  AFTER INSERT ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.auto_add_group_creator();

-- ═══════════════════════════════════════════════════════════
-- GROUP ITEMS (shared habits/goals within a group)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.group_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'habit' CHECK (type IN ('habit', 'goal')),
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT NOT NULL DEFAULT 'star',
  color BIGINT NOT NULL DEFAULT 4283215696,
  requires_proof BOOLEAN NOT NULL DEFAULT true,
  proof_type TEXT NOT NULL DEFAULT 'photo' CHECK (proof_type IN ('photo', 'screenshot', 'text', 'numeric')),
  proof_description TEXT DEFAULT 'Submit a photo as proof',
  sort_order INTEGER NOT NULL DEFAULT 0,
  added_by UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.group_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read group items"
  ON public.group_items FOR SELECT
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Members can add items"
  ON public.group_items FOR INSERT
  WITH CHECK (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Members can update items"
  ON public.group_items FOR UPDATE
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Adder or admin can delete items"
  ON public.group_items FOR DELETE
  USING (
    added_by = auth.uid() OR
    group_id IN (SELECT id FROM public.groups WHERE created_by = auth.uid())
  );

-- ═══════════════════════════════════════════════════════════
-- GROUP PROGRESS (daily completion tracking)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.group_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.group_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  completion_percent INTEGER NOT NULL DEFAULT 0 CHECK (completion_percent BETWEEN 0 AND 100),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (item_id, user_id, date)
);

ALTER TABLE public.group_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can see group progress"
  ON public.group_progress FOR SELECT
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own progress"
  ON public.group_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON public.group_progress FOR UPDATE
  USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════
-- PROOF SUBMISSIONS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.proof_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.group_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  proof_type TEXT NOT NULL CHECK (proof_type IN ('photo', 'screenshot', 'text', 'numeric')),
  image_url TEXT,
  caption TEXT,
  numeric_value DOUBLE PRECISION,
  numeric_unit TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  votes_approve INTEGER NOT NULL DEFAULT 0,
  votes_reject INTEGER NOT NULL DEFAULT 0,
  quorum_size INTEGER NOT NULL DEFAULT 1,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (item_id, user_id, date)
);

ALTER TABLE public.proof_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can see proofs in their groups"
  ON public.proof_submissions FOR SELECT
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));

CREATE POLICY "Members can submit proofs"
  ON public.proof_submissions FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Allow the trigger function to update proof status
CREATE POLICY "System can update proofs"
  ON public.proof_submissions FOR UPDATE
  USING (true);

-- ═══════════════════════════════════════════════════════════
-- PROOF VOTES
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.proof_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  proof_id UUID NOT NULL REFERENCES public.proof_submissions(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.profiles(id),
  vote BOOLEAN NOT NULL, -- true = approve, false = reject
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (proof_id, voter_id)
);

ALTER TABLE public.proof_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can see votes"
  ON public.proof_votes FOR SELECT
  USING (
    proof_id IN (
      SELECT id FROM public.proof_submissions
      WHERE group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can vote (not on own proofs)"
  ON public.proof_votes FOR INSERT
  WITH CHECK (
    auth.uid() = voter_id AND
    auth.uid() != (SELECT user_id FROM public.proof_submissions WHERE id = proof_id) AND
    'pending' = (SELECT status FROM public.proof_submissions WHERE id = proof_id)
  );

-- ═══════════════════════════════════════════════════════════
-- VOTE TALLY TRIGGER (auto-resolve proofs on quorum)
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.tally_proof_votes()
RETURNS TRIGGER AS $$
DECLARE
  v_approve_count INTEGER;
  v_reject_count INTEGER;
  v_proof RECORD;
BEGIN
  SELECT * INTO v_proof FROM public.proof_submissions WHERE id = NEW.proof_id;

  IF v_proof.status != 'pending' THEN
    RETURN NEW;
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE vote = true),
    COUNT(*) FILTER (WHERE vote = false)
  INTO v_approve_count, v_reject_count
  FROM public.proof_votes
  WHERE proof_id = NEW.proof_id;

  -- Update vote counts
  UPDATE public.proof_submissions
  SET votes_approve = v_approve_count, votes_reject = v_reject_count
  WHERE id = NEW.proof_id;

  -- Resolve if quorum reached
  IF v_approve_count >= v_proof.quorum_size THEN
    UPDATE public.proof_submissions
    SET status = 'approved', resolved_at = NOW()
    WHERE id = NEW.proof_id;

    -- Auto-set progress to 100%
    INSERT INTO public.group_progress (group_id, item_id, user_id, date, completion_percent)
    VALUES (v_proof.group_id, v_proof.item_id, v_proof.user_id, v_proof.date, 100)
    ON CONFLICT (item_id, user_id, date) DO UPDATE SET completion_percent = 100, updated_at = NOW();

  ELSIF v_reject_count >= v_proof.quorum_size THEN
    UPDATE public.proof_submissions
    SET status = 'rejected', resolved_at = NOW()
    WHERE id = NEW.proof_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_proof_vote
  AFTER INSERT ON public.proof_votes
  FOR EACH ROW EXECUTE FUNCTION public.tally_proof_votes();

-- ═══════════════════════════════════════════════════════════
-- AUTO-APPROVAL FUNCTION (called by pg_cron or edge function)
-- Proofs older than 24h with no rejections get auto-approved
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.auto_approve_stale_proofs()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
  v_proof RECORD;
BEGIN
  v_count := 0;

  FOR v_proof IN
    SELECT id, group_id, item_id, user_id, date
    FROM public.proof_submissions
    WHERE status = 'pending'
      AND created_at < NOW() - INTERVAL '24 hours'
      AND votes_reject = 0
  LOOP
    UPDATE public.proof_submissions
    SET status = 'approved', resolved_at = NOW()
    WHERE id = v_proof.id;

    INSERT INTO public.group_progress (group_id, item_id, user_id, date, completion_percent)
    VALUES (v_proof.group_id, v_proof.item_id, v_proof.user_id, v_proof.date, 100)
    ON CONFLICT (item_id, user_id, date) DO UPDATE SET completion_percent = 100, updated_at = NOW();

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- MILESTONE DEFINITIONS
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.milestone_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL DEFAULT 'emoji_events',
  color BIGINT NOT NULL DEFAULT 4294951175,
  category TEXT NOT NULL CHECK (category IN ('proof_count', 'streak', 'group_completion')),
  target_value INTEGER NOT NULL,
  coin_reward INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.milestone_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read milestone definitions"
  ON public.milestone_definitions FOR SELECT USING (true);

-- Seed milestone definitions
INSERT INTO public.milestone_definitions (name, description, icon, color, category, target_value, coin_reward, sort_order) VALUES
  -- Proof count milestones
  ('First Proof',       'Submit your first verified proof',           'verified',              4283215696, 'proof_count',      1,   25,  1),
  ('Getting Serious',   'Submit 7 verified proofs',                   'military_tech',         4284955319, 'proof_count',      7,   50,  2),
  ('Proof Machine',     'Submit 30 verified proofs',                  'workspace_premium',     4294940672, 'proof_count',      30,  150, 3),
  ('Century Club',      'Submit 100 verified proofs',                 'diamond',               4293467747, 'proof_count',      100, 500, 4),

  -- Streak milestones
  ('Hot Streak',        'Achieve a 7-day verified streak',            'local_fire_department', 4294944000, 'streak',           7,   50,  5),
  ('Iron Will',         'Achieve a 21-day verified streak',           'shield',                4284513675, 'streak',           21,  100, 6),
  ('Unstoppable',       'Achieve a 60-day verified streak',           'star',                  4294951175, 'streak',           60,  300, 7),
  ('Legendary',         'Achieve a 100-day verified streak',          'auto_awesome',          4290935012, 'streak',           100, 750, 8),

  -- Group completion milestones
  ('Team Player',       'Full group completion on a single day',      'groups',                4282339765, 'group_completion', 1,   75,  9),
  ('Squad Goals',       '10 full-group completion days',              'diversity_3',           4280391411, 'group_completion', 10,  200, 10),
  ('Unbreakable Bond',  '30 full-group completion days',              'handshake',             4283215696, 'group_completion', 30,  500, 11);

-- ═══════════════════════════════════════════════════════════
-- USER MILESTONES (progress tracking per user)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE public.user_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  milestone_id UUID NOT NULL REFERENCES public.milestone_definitions(id) ON DELETE CASCADE,
  current_value INTEGER NOT NULL DEFAULT 0,
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  coins_claimed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, milestone_id)
);

ALTER TABLE public.user_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own milestones"
  ON public.user_milestones FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own milestones"
  ON public.user_milestones FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own milestones"
  ON public.user_milestones FOR UPDATE
  USING (auth.uid() = user_id);

-- Group members can see each other's milestones
CREATE POLICY "Group members can see co-member milestones"
  ON public.user_milestones FOR SELECT
  USING (
    user_id IN (
      SELECT gm.user_id FROM public.group_members gm
      WHERE gm.group_id IN (
        SELECT group_id FROM public.group_members WHERE user_id = auth.uid()
      )
    )
  );

-- ═══════════════════════════════════════════════════════════
-- MILESTONE PROGRESS TRIGGER (update milestones on proof approval)
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.update_milestone_on_proof_approval()
RETURNS TRIGGER AS $$
DECLARE
  v_proof_count INTEGER;
  v_milestone RECORD;
BEGIN
  -- Only trigger when status changes to approved
  IF NEW.status != 'approved' OR OLD.status = 'approved' THEN
    RETURN NEW;
  END IF;

  -- Count total approved proofs for this user
  SELECT COUNT(*) INTO v_proof_count
  FROM public.proof_submissions
  WHERE user_id = NEW.user_id AND status = 'approved';

  -- Update proof_count milestones
  FOR v_milestone IN
    SELECT id, target_value FROM public.milestone_definitions WHERE category = 'proof_count'
  LOOP
    INSERT INTO public.user_milestones (user_id, milestone_id, current_value, completed, completed_at)
    VALUES (
      NEW.user_id,
      v_milestone.id,
      v_proof_count,
      v_proof_count >= v_milestone.target_value,
      CASE WHEN v_proof_count >= v_milestone.target_value THEN NOW() ELSE NULL END
    )
    ON CONFLICT (user_id, milestone_id) DO UPDATE SET
      current_value = v_proof_count,
      completed = v_proof_count >= v_milestone.target_value,
      completed_at = CASE
        WHEN v_proof_count >= v_milestone.target_value AND public.user_milestones.completed = false
        THEN NOW()
        ELSE public.user_milestones.completed_at
      END;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_proof_status_change
  AFTER UPDATE OF status ON public.proof_submissions
  FOR EACH ROW EXECUTE FUNCTION public.update_milestone_on_proof_approval();

-- ═══════════════════════════════════════════════════════════
-- HELPER VIEWS
-- ═══════════════════════════════════════════════════════════

-- Pending proofs for validation (excludes own submissions)
CREATE OR REPLACE VIEW public.pending_validations AS
SELECT
  ps.*,
  p.display_name AS submitter_name,
  p.avatar_url AS submitter_avatar,
  gi.title AS item_title,
  gi.icon AS item_icon,
  gi.color AS item_color,
  g.name AS group_name
FROM public.proof_submissions ps
JOIN public.profiles p ON ps.user_id = p.id
JOIN public.group_items gi ON ps.item_id = gi.id
JOIN public.groups g ON ps.group_id = g.id
WHERE ps.status = 'pending';

-- ═══════════════════════════════════════════════════════════
-- INDEXES for performance
-- ═══════════════════════════════════════════════════════════

CREATE INDEX idx_group_members_user ON public.group_members(user_id);
CREATE INDEX idx_group_items_group ON public.group_items(group_id);
CREATE INDEX idx_group_progress_item_date ON public.group_progress(item_id, date);
CREATE INDEX idx_group_progress_user_date ON public.group_progress(user_id, date);
CREATE INDEX idx_proof_submissions_group_status ON public.proof_submissions(group_id, status);
CREATE INDEX idx_proof_submissions_user_date ON public.proof_submissions(user_id, date);
CREATE INDEX idx_proof_submissions_status_created ON public.proof_submissions(status, created_at);
CREATE INDEX idx_proof_votes_proof ON public.proof_votes(proof_id);
CREATE INDEX idx_user_milestones_user ON public.user_milestones(user_id);
