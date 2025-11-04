-- Y-Ultimate Platform Database Schema
-- Run this script in your Supabase SQL Editor
-- This will create all necessary tables, constraints, and policies

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Profiles Table (User accounts)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE NO ACTION,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    full_name TEXT DEFAULT 'New User',
    role TEXT NOT NULL CHECK (role IN ('player', 'team_manager', 'tournament_director', 'coach', 'volunteer', 'scoring_team', 'spectator', 'tournament_organizer')),
    phone TEXT,
    location TEXT,
    domain TEXT DEFAULT 'tournament',
    is_approved BOOLEAN DEFAULT false,
    approval_status TEXT DEFAULT 'pending',
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES profiles(id) ON DELETE NO ACTION,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teams Table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    manager_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    age_division TEXT NOT NULL,
    city TEXT,
    state TEXT,
    country TEXT DEFAULT 'India',
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team Players Table
CREATE TABLE team_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    player_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    player_name TEXT NOT NULL,
    jersey_number INTEGER,
    position TEXT,
    is_registered_user BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, player_id)
);

-- Tournaments Table
CREATE TABLE tournaments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    location TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMPTZ,
    max_teams INTEGER,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'registration_open', 'registration_closed', 'in_progress', 'completed', 'cancelled')),
    age_divisions TEXT[] DEFAULT '{}',
    format TEXT NOT NULL DEFAULT 'round_robin',
    tournament_format TEXT DEFAULT 'round_robin' CHECK (tournament_format IN ('round_robin', 'pool_play', 'single_elimination', 'double_elimination')),
    min_team_size INTEGER DEFAULT 7,
    max_team_size INTEGER DEFAULT 15,
    is_public BOOLEAN DEFAULT true,
    banner_url TEXT,
    rules TEXT,
    sponsor_info JSONB DEFAULT '[]',
    live_stream_url TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE NO ACTION,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournament Registrations Table
CREATE TABLE tournament_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn')),
    division TEXT DEFAULT 'Open',
    seed_number INTEGER,
    notes TEXT,
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES profiles(id) ON DELETE NO ACTION,
    withdrawn_at TIMESTAMPTZ,
    UNIQUE(tournament_id, team_id)
);

-- Fields Table
CREATE TABLE fields (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    field_number INTEGER,
    location TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tournament_id, field_number)
);

-- Matches Table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    round_name TEXT NOT NULL,
    round_number INTEGER,
    match_number INTEGER,
    field_id UUID REFERENCES fields(id) ON DELETE SET NULL,
    field_number TEXT,
    scheduled_time TIMESTAMPTZ,
    team1_id UUID,
    team2_id UUID,
    team1_score INTEGER DEFAULT 0,
    team2_score INTEGER DEFAULT 0,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    winner_id UUID,
    bracket_type TEXT CHECK (bracket_type IN ('winners', 'losers', 'championship')),
    pool_name TEXT,
    pool TEXT,
    bracket TEXT,
    is_final BOOLEAN DEFAULT false,
    spirit_score_submitted_team1 BOOLEAN DEFAULT false,
    spirit_score_submitted_team2 BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spirit Scores Table
CREATE TABLE spirit_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    scoring_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE NO ACTION,
    opponent_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE NO ACTION,
    submitted_by UUID NOT NULL REFERENCES profiles(id) ON DELETE NO ACTION,
    rules_knowledge INTEGER CHECK (rules_knowledge BETWEEN 0 AND 4),
    fouls_body_contact INTEGER CHECK (fouls_body_contact BETWEEN 0 AND 4),
    fair_mindedness INTEGER CHECK (fair_mindedness BETWEEN 0 AND 4),
    positive_attitude INTEGER CHECK (positive_attitude BETWEEN 0 AND 4),
    communication INTEGER CHECK (communication BETWEEN 0 AND 4),
    total_score INTEGER,
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(match_id, scoring_team_id)
);

-- ============================================================================
-- ENGAGEMENT FEATURES
-- ============================================================================

-- Team Followers Table
CREATE TABLE team_followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE NO ACTION,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Match Predictions Table
CREATE TABLE match_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE NO ACTION,
    predicted_winner_id UUID REFERENCES teams(id) ON DELETE NO ACTION,
    predicted_score_team1 INTEGER,
    predicted_score_team2 INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);

-- Announcements Table
CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT CHECK (type IN ('general', 'urgent', 'schedule_change', 'weather', 'important')),
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE NO ACTION,
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sponsors Table
CREATE TABLE sponsors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    logo_url TEXT,
    website_url TEXT,
    tier TEXT CHECK (tier IN ('title', 'platinum', 'gold', 'silver', 'bronze', 'partner')),
    description TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournament Media Table
CREATE TABLE tournament_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    media_type TEXT CHECK (media_type IN ('photo', 'video', 'live_stream')),
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    uploaded_by UUID NOT NULL REFERENCES profiles(id) ON DELETE NO ACTION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournament Photos Table (Legacy)
CREATE TABLE tournament_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    caption TEXT,
    uploaded_by UUID REFERENCES profiles(id) ON DELETE NO ACTION,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Visitors Table
CREATE TABLE visitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    organization TEXT,
    visitor_type TEXT CHECK (visitor_type IN ('media', 'sponsor', 'guest', 'volunteer', 'official', 'other')),
    checked_in BOOLEAN DEFAULT false,
    check_in_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Approval Requests Table
CREATE TABLE approval_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE NO ACTION,
    requested_role TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reason TEXT,
    reviewed_by UUID REFERENCES profiles(id) ON DELETE NO ACTION,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Attendance Table
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID,
    child_id UUID,
    player_id UUID REFERENCES team_players(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    present BOOLEAN DEFAULT false,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(session_id, child_id)
);

-- ============================================================================
-- COACHING PROGRAM TABLES
-- ============================================================================

-- Programmes Table
CREATE TABLE programmes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Communities Table
CREATE TABLE communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    type TEXT CHECK (type IN ('school', 'community_center', 'ngo', 'other')),
    address TEXT,
    programme_id UUID REFERENCES programmes(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Batches Table
CREATE TABLE batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    programme_id UUID REFERENCES programmes(id) ON DELETE CASCADE,
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    coach_id UUID,
    schedule TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Children Table
CREATE TABLE children (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    date_of_birth DATE,
    community TEXT,
    school TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Coaches Table
CREATE TABLE coaches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    role TEXT DEFAULT 'coach',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sessions Table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_name TEXT NOT NULL,
    location TEXT,
    session_date DATE NOT NULL,
    coach_id UUID REFERENCES coaches(id) ON DELETE SET NULL,
    community TEXT,
    duration INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Assessments Table
CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID NOT NULL,
    session_id UUID,
    assessor_id UUID REFERENCES coaches(id) ON DELETE SET NULL,
    assessment_type TEXT CHECK (assessment_type IN ('initial', 'mid_term', 'final', 'quarterly')),
    assessment_date DATE NOT NULL DEFAULT NOW(),
    rules_knowledge INTEGER CHECK (rules_knowledge BETWEEN 0 AND 4),
    fouls_contact INTEGER CHECK (fouls_contact BETWEEN 0 AND 4),
    fair_mindedness INTEGER CHECK (fair_mindedness BETWEEN 0 AND 4),
    positive_attitude INTEGER CHECK (positive_attitude BETWEEN 0 AND 4),
    communication INTEGER CHECK (communication BETWEEN 0 AND 4),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Home Visits Table
CREATE TABLE home_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID,
    coach_id UUID,
    visit_date DATE NOT NULL,
    location TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Reports Table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    generated_by UUID REFERENCES auth.users(id) ON DELETE NO ACTION,
    type TEXT,
    filters JSONB,
    data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User Roles Table (Legacy/Additional)
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE NO ACTION,
    role TEXT CHECK (role IN ('admin', 'coach', 'coordinator', 'volunteer')),
    assigned_programme UUID REFERENCES programmes(id) ON DELETE NO ACTION,
    assigned_community UUID REFERENCES communities(id) ON DELETE NO ACTION
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE spirit_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Profiles are viewable by authenticated users" ON profiles
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Enable insert for authenticated users" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Teams Policies
CREATE POLICY "Team managers can create teams" ON teams
    FOR INSERT WITH CHECK (manager_id = auth.uid());

CREATE POLICY "Team managers can view their own teams" ON teams
    FOR SELECT USING (manager_id = auth.uid());

CREATE POLICY "Team managers can update their own teams" ON teams
    FOR UPDATE USING (manager_id = auth.uid());

CREATE POLICY "Team managers can delete their own teams" ON teams
    FOR DELETE USING (manager_id = auth.uid());

-- Team Players Policies
CREATE POLICY "View players of own teams" ON team_players
    FOR SELECT USING (
        team_id IN (SELECT id FROM teams WHERE manager_id = auth.uid())
        OR player_id = auth.uid()
    );

CREATE POLICY "Add players to own teams" ON team_players
    FOR INSERT WITH CHECK (team_id IN (SELECT id FROM teams WHERE manager_id = auth.uid()));

CREATE POLICY "Update players of own teams" ON team_players
    FOR UPDATE USING (team_id IN (SELECT id FROM teams WHERE manager_id = auth.uid()));

CREATE POLICY "Delete players from own teams" ON team_players
    FOR DELETE USING (team_id IN (SELECT id FROM teams WHERE manager_id = auth.uid()));

-- Tournaments Policies
CREATE POLICY "Anyone can view published tournaments" ON tournaments
    FOR SELECT USING (status <> 'draft' OR created_by = auth.uid());

CREATE POLICY "Tournament directors can create tournaments" ON tournaments
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'tournament_director')
    );

CREATE POLICY "Creators can update their tournaments" ON tournaments
    FOR UPDATE USING (created_by = auth.uid());

-- Tournament Registrations Policies
CREATE POLICY "View own team registrations" ON tournament_registrations
    FOR SELECT USING (
        team_id IN (SELECT id FROM teams WHERE manager_id = auth.uid())
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('tournament_director', 'tournament_organizer'))
    );

CREATE POLICY "Team managers can register teams" ON tournament_registrations
    FOR INSERT WITH CHECK (team_id IN (SELECT id FROM teams WHERE manager_id = auth.uid()));

CREATE POLICY "Team managers can update their registrations" ON tournament_registrations
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM teams WHERE id = tournament_registrations.team_id AND manager_id = auth.uid())
    );

CREATE POLICY "Tournament directors can approve registrations" ON tournament_registrations
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM tournaments WHERE id = tournament_registrations.tournament_id AND created_by = auth.uid())
    );

-- Fields Policies
CREATE POLICY "Anyone can view fields" ON fields
    FOR SELECT USING (true);

CREATE POLICY "Tournament directors can manage fields" ON fields
    FOR ALL USING (
        EXISTS (SELECT 1 FROM tournaments WHERE id = fields.tournament_id AND created_by = auth.uid())
    );

-- Matches Policies
CREATE POLICY "Anyone can view matches" ON matches
    FOR SELECT USING (true);

CREATE POLICY "Volunteers can update match scores" ON matches
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('volunteer', 'scoring_team', 'tournament_director'))
    );

-- Spirit Scores Policies
CREATE POLICY "View all spirit scores" ON spirit_scores
    FOR SELECT USING (true);

CREATE POLICY "Team managers can submit spirit scores" ON spirit_scores
    FOR INSERT WITH CHECK (
        scoring_team_id IN (SELECT id FROM teams WHERE manager_id = auth.uid())
    );

-- Team Followers Policies
CREATE POLICY "Users can manage their own follows" ON team_followers
    FOR ALL USING (auth.uid() = user_id);

-- Match Predictions Policies
CREATE POLICY "Users can manage their own predictions" ON match_predictions
    FOR ALL USING (auth.uid() = user_id);

-- Announcements Policies
CREATE POLICY "Announcements are viewable by everyone" ON announcements
    FOR SELECT USING (true);

CREATE POLICY "Tournament directors can create announcements" ON announcements
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM tournaments t WHERE t.id = tournament_id AND t.created_by = auth.uid())
    );

-- Sponsors Policies
CREATE POLICY "Sponsors are viewable by everyone" ON sponsors
    FOR SELECT USING (true);

CREATE POLICY "Tournament directors can manage sponsors" ON sponsors
    FOR ALL USING (
        EXISTS (SELECT 1 FROM tournaments t WHERE t.id = sponsors.tournament_id AND t.created_by = auth.uid())
    );

-- Tournament Media Policies
CREATE POLICY "Media is viewable by everyone" ON tournament_media
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can upload media" ON tournament_media
    FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

-- Tournament Photos Policies
CREATE POLICY "Anyone can view tournament photos" ON tournament_photos
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can upload photos" ON tournament_photos
    FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can delete their own photos" ON tournament_photos
    FOR DELETE USING (auth.uid() = uploaded_by);

-- Visitors Policies
CREATE POLICY "Tournament directors can manage visitors" ON visitors
    FOR ALL USING (
        EXISTS (SELECT 1 FROM tournaments t WHERE t.id = visitors.tournament_id AND t.created_by = auth.uid())
    );

CREATE POLICY "Visitors can view their own record" ON visitors
    FOR SELECT USING (
        auth.uid() IN (SELECT id FROM profiles WHERE email = visitors.email)
    );

-- Approval Requests Policies
CREATE POLICY "Users can view their own approval requests" ON approval_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Tournament directors can view all approval requests" ON approval_requests
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'tournament_director')
    );

-- Children Policies
CREATE POLICY "Allow read for all" ON children
    FOR SELECT USING (true);

-- Coaches Policies
CREATE POLICY "Allow read for all" ON coaches
    FOR SELECT USING (true);

-- Assessments Policies
CREATE POLICY "Coach can insert assessment" ON assessments
    FOR INSERT WITH CHECK (assessor_id = auth.uid());

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'spectator')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON profiles;
CREATE TRIGGER on_auth_user_created
    BEFORE INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_teams_manager_id ON teams(manager_id);
CREATE INDEX idx_team_players_team_id ON team_players(team_id);
CREATE INDEX idx_team_players_player_id ON team_players(player_id);
CREATE INDEX idx_tournaments_created_by ON tournaments(created_by);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournament_registrations_tournament_id ON tournament_registrations(tournament_id);
CREATE INDEX idx_tournament_registrations_team_id ON tournament_registrations(team_id);
CREATE INDEX idx_matches_tournament_id ON matches(tournament_id);
CREATE INDEX idx_matches_team1_id ON matches(team1_id);
CREATE INDEX idx_matches_team2_id ON matches(team2_id);
CREATE INDEX idx_spirit_scores_match_id ON spirit_scores(match_id);
CREATE INDEX idx_announcements_tournament_id ON announcements(tournament_id);

-- ============================================================================
-- SAMPLE DATA (Optional - Remove if not needed)
-- ============================================================================

-- You can add sample data here for testing
-- Example:
-- INSERT INTO profiles (id, email, name, role) VALUES ...

COMMENT ON DATABASE postgres IS 'Y-Ultimate Tournament Management Platform Database';