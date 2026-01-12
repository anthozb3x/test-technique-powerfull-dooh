-- ============================================
-- POWERFULL DOOH - Données de test (seed)
-- ============================================

-- ============================================
-- Sites de diffusion (salles de sport / complexes)
-- ============================================
INSERT INTO sites (id, name, address) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Fitness Park Lyon', '123 Rue de la République, 69001 Lyon'),
    ('22222222-2222-2222-2222-222222222222', 'Basic Fit Paris Bastille', '45 Boulevard Beaumarchais, 75003 Paris'),
    ('33333333-3333-3333-3333-333333333333', 'Keep Cool Marseille Vieux-Port', '15 Quai du Port, 13002 Marseille');

-- ============================================
-- Note: Les utilisateurs sont créés via Supabase Auth
-- Utilisez Supabase Studio ou l'API Auth pour créer des utilisateurs de test
--
-- Après création d'un utilisateur, mettez à jour son profil avec un site_id:
--
-- UPDATE profiles
-- SET site_id = '11111111-1111-1111-1111-111111111111'
-- WHERE email = 'user@example.com';
-- ============================================
