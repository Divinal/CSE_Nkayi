# Mise en route — Complexe Scolaire Évangélique de Nkayi

Ce dossier est une copie de l'application Christ-Roi, déjà adaptée à l'école.
Il reste à lui donner **sa propre base Supabase**, **son dépôt GitHub** et **son site Vercel**.

## Ce qui est déjà fait

| Élément | Où |
|---|---|
| Nom, devise « Travail – Prière – Réussite », adresse, téléphones, directeur | `src/config/site.config.ts` |
| Logo (grand C + livre ouvert « S E », bleu et blanc) | `public/Images/logo-cse-nkayi.svg` et `.png` |
| Thème clair bleu et blanc | `index.html` |
| Cycles : Garderie, Préscolaire, Primaire, Collège, Lycée (le Supérieur est masqué) | `site.config.ts` → `cycles` |
| Cycle « Garderie » dans la base (niveau « Garderie » créé, notes par compositions et trimestres comme au préscolaire) | `supabase/migrations/` |
| Matricules au format `SE-6E260001` | `supabase/functions/admin-users/handler.ts` |
| Clés Supabase de Christ-Roi retirées | `.env` (valeurs à remplacer) |

## À compléter dans `src/config/site.config.ts`

- `contact.email` : l'adresse email de l'école (actuellement `contact@exemple.com`).
- `reportCard.authorityLines` : ajouter si besoin la ligne de l'inspection dont dépend l'école (en-tête du bulletin).
- `siteUrl` : ✅ fait — `https://cse-nkayi.vercel.app` (sert aussi aux liens d'inscription envoyés aux familles).

## 1. Créer la base Supabase

1. Sur https://supabase.com/dashboard → **New project** (nom : `cse-nkayi`). Notez le mot de passe de la base.
2. L'URL du projet (`https://fjfadrzaanrwibkgugkh.supabase.co`) est déjà dans `.env`.
   Il reste la **clé publishable** : **Project Settings → API Keys**, copiez `sb_publishable_…`
   à la place de `sb_publishable_A_REMPLACER`. Ne mettez jamais la clé secrète dans `.env`.
3. Dans un terminal ouvert dans ce dossier, créez les tables et déployez la fonction serveur :
   ```powershell
   npx supabase login
   ```
   ```powershell
   npx supabase link --project-ref fjfadrzaanrwibkgugkh
   ```
   ```powershell
   npx supabase db push
   ```
   ```powershell
   npx supabase functions deploy admin-users
   ```
   ```powershell
   npx supabase secrets set SCHOOL_CODE=SE
   ```
4. **Premier compte administrateur** : *Authentication → Users → Add user* (email + mot de passe),
   puis dans *SQL Editor* :
   ```sql
   INSERT INTO public.user_roles (user_id, role)
   SELECT id, 'admin' FROM auth.users WHERE email = 'email-du-directeur@exemple.com';
   ```

## 2. Créer le dépôt GitHub

1. Sur GitHub → **New repository** (ex. `cse-nkayi`), vide, sans README.
2. Dans ce dossier :
   ```powershell
   git init -b main
   ```
   ```powershell
   git add .
   ```
   ```powershell
   git commit -m "Plateforme du Complexe Scolaire Évangélique de Nkayi"
   ```
   ```powershell
   git remote add origin https://github.com/VOTRE-COMPTE/cse-nkayi.git
   ```
   ```powershell
   git push -u origin main
   ```

## 3. Mettre le site en ligne sur Vercel

1. https://vercel.com/new → importez le dépôt `cse-nkayi` (Vite est détecté tout seul).
2. **Environment Variables** : ajoutez `VITE_SUPABASE_URL` et `VITE_SUPABASE_PUBLISHABLE_KEY` (mêmes valeurs que `.env`).
3. **Deploy**. Reportez ensuite l'adresse obtenue :
   - dans `siteUrl` (`src/config/site.config.ts`), puis poussez sur GitHub ;
   - dans Supabase → *Authentication → URL Configuration* → **Site URL** et **Redirect URLs**.
   Adresse du site : **https://cse-nkayi.vercel.app** (Site URL = cette adresse ;
   Redirect URLs = `https://cse-nkayi.vercel.app/**`).

## Dépannage : « Service de gestion des comptes injoignable » / « pas encore déployé »

L'ajout d'étudiants, d'enseignants et d'admins, la réinitialisation des mots de passe,
la corbeille et l'inscription par lien passent tous par la fonction serveur `admin-users`.
Si elle n'est pas déployée, toutes ces actions échouent. Pour la déployer, il faut être
connecté au **compte Supabase propriétaire du projet** `fjfadrzaanrwibkgugkh` :

```powershell
npx supabase logout
```
```powershell
npx supabase login
```
```powershell
npx supabase functions deploy admin-users --project-ref fjfadrzaanrwibkgugkh
```
```powershell
npx supabase secrets set SCHOOL_CODE=SE --project-ref fjfadrzaanrwibkgugkh
```

Sans terminal : Supabase → *Edge Functions* → **Deploy a new function** → *Via Editor*,
nom `admin-users`, créer les deux fichiers `index.ts` et `handler.ts` avec le contenu de
`supabase/functions/admin-users/`, puis **désactiver la vérification JWT** dans les
réglages de la fonction (la session est vérifiée dans le code, comme le prévoit
`supabase/config.toml` avec `verify_jwt = false`), et ajouter le secret
`SCHOOL_CODE` = `SE` dans *Edge Functions → Secrets*.

## Tester en local

```powershell
npm install
```
```powershell
npm run dev
```

## Bon à savoir

Ce dossier est indépendant de Christ-Roi : une nouveauté ajoutée à l'un n'apparaît pas dans l'autre.
Pour reporter une fonctionnalité, copiez les fichiers concernés et la nouvelle migration SQL ;
si une migration redéfinit le contrôle des notes, gardez `'garderie'` dans les listes de cycles.
