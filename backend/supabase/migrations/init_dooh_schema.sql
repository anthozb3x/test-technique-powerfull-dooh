-- ============================================
-- POWERFULL DOOH - Schema Initial
-- Multi-tenant avec RLS
-- ============================================

-- ============================================
-- ENUM TYPES
-- ============================================

-- Statut des contenus
CREATE TYPE content_status AS ENUM ('draft', 'published', 'archived');

-- ============================================
-- TABLE: sites
-- Lieux de diffusion (salles de sport, complexes de loisirs)
-- ============================================
CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche par nom
CREATE INDEX idx_sites_name ON sites(name);

-- ============================================
-- TABLE: profiles
-- Extension des utilisateurs avec association au site (tenant)
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    site_id UUID REFERENCES sites(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche par site
CREATE INDEX idx_profiles_site_id ON profiles(site_id);

-- ============================================
-- TABLE: contents
-- Contenus audiovisuels/publicitaires à diffuser
-- ============================================
CREATE TABLE contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    media_url TEXT,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status content_status DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Contrainte: end_at doit être après start_at
    CONSTRAINT check_dates CHECK (end_at > start_at)
);

-- Index pour recherche par site et dates
CREATE INDEX idx_contents_site_id ON contents(site_id);
CREATE INDEX idx_contents_dates ON contents(start_at, end_at);
CREATE INDEX idx_contents_status ON contents(status);

-- ============================================
-- TRIGGER: updated_at automatique
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_sites_updated_at
    BEFORE UPDATE ON sites
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contents_updated_at
    BEFORE UPDATE ON contents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRIGGER: Créer automatiquement un profil à l'inscription
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Multi-tenant: les utilisateurs ne voient que les données de leur site
-- ============================================

-- Activer RLS sur toutes les tables
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE contents ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTION: Récupérer le site_id de l'utilisateur courant
-- ============================================
CREATE OR REPLACE FUNCTION get_user_site_id()
RETURNS UUID AS $$
    SELECT site_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================
-- POLICIES: sites
-- ============================================

-- Les utilisateurs peuvent voir uniquement leur site
CREATE POLICY "Users can view their own site"
    ON sites FOR SELECT
    USING (id = get_user_site_id());

-- ============================================
-- POLICIES: profiles
-- ============================================

-- Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (id = auth.uid());

-- Les utilisateurs peuvent mettre à jour leur propre profil
CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- ============================================
-- POLICIES: contents
-- ============================================

-- Les utilisateurs peuvent voir les contenus de leur site
CREATE POLICY "Users can view contents from their site"
    ON contents FOR SELECT
    USING (site_id = get_user_site_id());

-- Les utilisateurs peuvent créer des contenus pour leur site
CREATE POLICY "Users can create contents for their site"
    ON contents FOR INSERT
    WITH CHECK (
        site_id = get_user_site_id()
        AND created_by = auth.uid()
    );

-- Les utilisateurs peuvent mettre à jour les contenus de leur site
CREATE POLICY "Users can update contents from their site"
    ON contents FOR UPDATE
    USING (site_id = get_user_site_id())
    WITH CHECK (site_id = get_user_site_id());

-- Les utilisateurs peuvent supprimer les contenus de leur site
CREATE POLICY "Users can delete contents from their site"
    ON contents FOR DELETE
    USING (site_id = get_user_site_id());

-- ============================================
-- GRANT: Permissions pour les utilisateurs authentifiés
-- ============================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON sites TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON contents TO authenticated;

-- Pour anon (lecture seule sur certaines tables si nécessaire)
GRANT USAGE ON SCHEMA public TO anon;
