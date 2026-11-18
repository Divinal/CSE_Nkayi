// Contenu personnalisable par école : modifier ce fichier (et lui seul) suffit
// à adapter le nom, le logo, les textes et les coordonnées d'un site cloné.
import type { SchoolCycle } from '../lib/levels';

export const siteConfig = {
  // URL publique du site (sans slash final) : utilisée pour le SEO
  // (balises canonical/Open Graph, robots.txt, sitemap.xml).
  // À METTRE À JOUR avec l'adresse donnée par Vercel.
  siteUrl: 'https://cse-nkayi.vercel.app',
  schoolName: 'Complexe Scolaire Évangélique de Nkayi',
  tagline: 'Plateforme scolaire en ligne',
  // Chemin absolu depuis public/ : sert aussi de favicon et d'image de partage.
  logoUrl: '/Images/logo-cse-nkayi.png',
  logoFallbackInitials: 'SE',
  // Cycles proposés par l'établissement, du plus jeune au plus âgé.
  cycles: ['garderie', 'prescolaire', 'primaire', 'college', 'lycee'] as SchoolCycle[],
  hero: {
    title: 'Travail – Prière – Réussite, de la garderie au lycée',
    description:
      "La plateforme du Complexe Scolaire Évangélique de Nkayi : notes, bulletins, emplois du temps, frais de scolarité et échanges entre l'école et les familles, accessibles en ligne.",
  },
  stats: [
    { value: '5', label: 'Cycles' },
    { value: '24h/24', label: 'Accès' },
    { value: '100%', label: 'En ligne' },
  ],
  about: {
    title: 'Complexe Scolaire Évangélique de Nkayi',
    description:
      'Un établissement évangélique qui accompagne chaque élève de la garderie au lycée, autour de sa devise : Travail – Prière – Réussite.',
  },
  contact: {
    addressLines: ['N° 10-12-14-16, Av. P. Lumumba', 'En face de la Mairie centrale', 'Nkayi, République du Congo'],
    // À REMPLACER par l'adresse email de l'établissement.
    email: 'contact@exemple.com',
    // Plusieurs numéros séparés par « / » : le premier sert au lien d'appel.
    phone: '+242 05 570 30 48 / 06 963 16 53',
  },
  copyrightOwner: 'Complexe Scolaire Évangélique de Nkayi',
  // En-tête officiel du bulletin de notes (imprimé tel quel, sans traduction).
  reportCard: {
    authorityLines: [
      "MINISTÈRE DE L'ENSEIGNEMENT PRÉSCOLAIRE, PRIMAIRE, SECONDAIRE ET DE L'ALPHABÉTISATION",
      "DIRECTION DÉPARTEMENTALE DE L'ENSEIGNEMENT PRÉSCOLAIRE, PRIMAIRE, SECONDAIRE ET DE L'ALPHABÉTISATION DE LA BOUENZA",
    ],
    country: 'RÉPUBLIQUE DU CONGO',
    countryMotto: 'Unité – Travail – Progrès',
    schoolMotto: 'Travail – Prière – Réussite',
    address: 'N° 10-12-14-16, Av. P. Lumumba, en face de la Mairie centrale',
    city: 'Nkayi',
    // Nom imprimé sous « Le chef d'établissement » (laisser vide pour signer à la main).
    headName: 'Apollinaire KOKOLO',
  },
};

export type SiteConfig = typeof siteConfig;

// Lien d'appel : seul le premier numéro est composé.
export const phoneHref = (phone: string): string => `tel:${phone.split('/')[0].replace(/\s/g, '')}`;
