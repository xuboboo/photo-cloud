// 西班牙语翻译
import en from './en-US'

export default {
  ...en,
  common: {
    ...en.common,
    loading: 'Cargando...',
    save: 'Guardar',
    cancel: 'Cancelar',
    delete: 'Eliminar',
    edit: 'Editar',
    confirm: 'Confirmar',
    upload: 'Subir',
    download: 'Descargar',
    share: 'Compartir'
  },
  nav: {
    home: 'Inicio',
    dashboard: 'Panel',
    upload: 'Subir',
    settings: 'Configuración',
    admin: 'Administrador',
    logout: 'Cerrar sesión',
    login: 'Iniciar sesión'
  },
  home: {
    title: 'Photo Cloud - Sistema Profesional de Álbum en la Nube',
    subtitle: 'Almacenamiento en la nube seguro y confiable',
    description: 'Admite carga de imágenes, vista previa en línea y compartir archivos. 1GB de almacenamiento gratuito con seguridad de nivel empresarial.',
    getStarted: 'Comenzar',
    learnMore: 'Saber más',
    features: {
      title: 'Características principales',
      storage: 'Almacenamiento seguro',
      storageDesc: 'Cifrado empresarial, seguridad de datos confiable',
      share: 'Compartir fácil',
      shareDesc: 'Enlaces para compartir con un clic, con protección por contraseña',
      preview: 'Vista previa en línea',
      previewDesc: 'Compatible con imágenes, Markdown y más formatos',
      management: 'Gestión inteligente',
      managementDesc: 'Organización de carpetas, gestión eficiente de archivos'
    }
  },
  auth: {
    login: 'Iniciar sesión',
    register: 'Registrarse',
    email: 'Correo electrónico',
    password: 'Contraseña',
    confirmPassword: 'Confirmar contraseña',
    emailPlaceholder: 'Ingrese su correo electrónico',
    passwordPlaceholder: 'Ingrese contraseña (mínimo 6 caracteres)',
    loginSuccess: 'Inicio de sesión exitoso',
    registerSuccess: 'Registro exitoso, por favor revise su correo electrónico',
    ...en.auth
  },
  seo: {
    title: 'Photo Cloud - Sistema Profesional de Gestión de Álbum en la Nube',
    description: 'Servicio de almacenamiento en la nube seguro con carga de imágenes, vista previa en línea y compartir archivos. 1GB de almacenamiento gratuito con seguridad de nivel empresarial.',
    keywords: 'Photo Cloud,álbum en la nube,almacenamiento en la nube,gestión de fotos,compartir imágenes,gestión de archivos,álbum en línea,respaldo de fotos'
  }
}
