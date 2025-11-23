// 德语翻译
import en from './en-US'

export default {
  ...en,
  common: {
    ...en.common,
    loading: 'Wird geladen...',
    save: 'Speichern',
    cancel: 'Abbrechen',
    delete: 'Löschen',
    edit: 'Bearbeiten',
    confirm: 'Bestätigen',
    upload: 'Hochladen',
    download: 'Herunterladen',
    share: 'Teilen'
  },
  nav: {
    home: 'Startseite',
    dashboard: 'Dashboard',
    upload: 'Hochladen',
    settings: 'Einstellungen',
    admin: 'Administrator',
    logout: 'Abmelden',
    login: 'Anmelden'
  },
  home: {
    title: 'Photo Cloud - Professionelles Cloud-Album-System',
    subtitle: 'Sicherer und zuverlässiger Cloud-Speicher',
    description: 'Unterstützt Bild-Upload, Online-Vorschau und Dateifreigabe. 1 GB kostenloser Speicher mit Sicherheit auf Unternehmensniveau.',
    getStarted: 'Loslegen',
    learnMore: 'Mehr erfahren',
    features: {
      title: 'Kernfunktionen',
      storage: 'Sicherer Speicher',
      storageDesc: 'Unternehmensverschlüsselung, zuverlässige Datensicherheit',
      share: 'Einfaches Teilen',
      shareDesc: 'Ein-Klick-Freigabelinks mit Passwortschutz',
      preview: 'Online-Vorschau',
      previewDesc: 'Unterstützt Bilder, Markdown und weitere Formate',
      management: 'Intelligente Verwaltung',
      managementDesc: 'Ordnerorganisation, effiziente Dateiverwaltung'
    }
  },
  auth: {
    login: 'Anmelden',
    register: 'Registrieren',
    email: 'E-Mail',
    password: 'Passwort',
    confirmPassword: 'Passwort bestätigen',
    emailPlaceholder: 'Geben Sie Ihre E-Mail ein',
    passwordPlaceholder: 'Passwort eingeben (mindestens 6 Zeichen)',
    loginSuccess: 'Anmeldung erfolgreich',
    registerSuccess: 'Registrierung erfolgreich, bitte überprüfen Sie Ihre E-Mail',
    ...en.auth
  },
  seo: {
    title: 'Photo Cloud - Professionelles Cloud-Album-Verwaltungssystem',
    description: 'Sicherer Cloud-Speicherdienst mit Bild-Upload, Online-Vorschau und Dateifreigabe. 1 GB kostenloser Speicher mit Sicherheit auf Unternehmensniveau.',
    keywords: 'Photo Cloud,Cloud-Album,Cloud-Speicher,Fotoverwaltung,Bildfreigabe,Dateiverwaltung,Online-Album,Foto-Backup'
  }
}
