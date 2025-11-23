// 法语翻译
import en from './en-US'

export default {
  ...en,
  common: {
    ...en.common,
    loading: 'Chargement...',
    save: 'Enregistrer',
    cancel: 'Annuler',
    delete: 'Supprimer',
    edit: 'Modifier',
    confirm: 'Confirmer',
    upload: 'Télécharger',
    download: 'Télécharger',
    share: 'Partager'
  },
  nav: {
    home: 'Accueil',
    dashboard: 'Tableau de bord',
    upload: 'Télécharger',
    settings: 'Paramètres',
    admin: 'Administrateur',
    logout: 'Déconnexion',
    login: 'Connexion'
  },
  home: {
    title: 'Photo Cloud - Système professionnel d\'album cloud',
    subtitle: 'Stockage cloud sécurisé et fiable',
    description: 'Prise en charge du téléchargement d\'images, de la prévisualisation en ligne et du partage de fichiers. 1 Go de stockage gratuit avec sécurité de niveau entreprise.',
    getStarted: 'Commencer',
    learnMore: 'En savoir plus',
    features: {
      title: 'Fonctionnalités principales',
      storage: 'Stockage sécurisé',
      storageDesc: 'Chiffrement d\'entreprise, sécurité des données fiable',
      share: 'Partage facile',
      shareDesc: 'Liens de partage en un clic avec protection par mot de passe',
      preview: 'Aperçu en ligne',
      previewDesc: 'Prise en charge des images, Markdown et plus de formats',
      management: 'Gestion intelligente',
      managementDesc: 'Organisation des dossiers, gestion efficace des fichiers'
    }
  },
  auth: {
    login: 'Connexion',
    register: 'S\'inscrire',
    email: 'E-mail',
    password: 'Mot de passe',
    confirmPassword: 'Confirmer le mot de passe',
    emailPlaceholder: 'Entrez votre e-mail',
    passwordPlaceholder: 'Entrez le mot de passe (au moins 6 caractères)',
    loginSuccess: 'Connexion réussie',
    registerSuccess: 'Inscription réussie, veuillez vérifier votre e-mail',
    ...en.auth
  },
  seo: {
    title: 'Photo Cloud - Système professionnel de gestion d\'album cloud',
    description: 'Service de stockage cloud sécurisé avec téléchargement d\'images, aperçu en ligne et partage de fichiers. 1 Go de stockage gratuit avec sécurité de niveau entreprise.',
    keywords: 'Photo Cloud,album cloud,stockage cloud,gestion de photos,partage d\'images,gestion de fichiers,album en ligne,sauvegarde de photos'
  }
}
