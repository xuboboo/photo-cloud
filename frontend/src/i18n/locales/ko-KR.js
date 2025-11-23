// 韩语翻译 - 基于英文和中文翻译
import en from './en-US'

export default {
  ...en,
  common: {
    ...en.common,
    appName: 'Photo Cloud',
    loading: '로딩 중...',
    save: '저장',
    cancel: '취소',
    delete: '삭제',
    edit: '편집',
    confirm: '확인',
    upload: '업로드',
    download: '다운로드',
    share: '공유'
  },
  nav: {
    home: '홈',
    dashboard: '대시보드',
    upload: '업로드',
    settings: '설정',
    admin: '관리자',
    logout: '로그아웃',
    login: '로그인'
  },
  home: {
    title: 'Photo Cloud - 전문 클라우드 앨범 시스템',
    subtitle: '안전하고 신뢰할 수 있는 클라우드 스토리지',
    description: '이미지 업로드, 온라인 미리보기, 파일 공유를 지원합니다. 무료 1GB 스토리지, 엔터프라이즈급 보안.',
    getStarted: '시작하기',
    learnMore: '더 알아보기',
    features: en.home.features
  },
  auth: {
    login: '로그인',
    register: '회원가입',
    email: '이메일',
    password: '비밀번호',
    confirmPassword: '비밀번호 확인',
    emailPlaceholder: '이메일을 입력하세요',
    passwordPlaceholder: '비밀번호를 입력하세요 (최소 6자)',
    loginSuccess: '로그인 성공',
    registerSuccess: '회원가입 성공, 이메일을 확인해주세요',
    ...en.auth
  },
  seo: {
    title: 'Photo Cloud - 전문 클라우드 앨범 관리 시스템',
    description: '이미지 업로드, 온라인 미리보기, 파일 공유 기능을 갖춘 안전한 클라우드 스토리지 서비스. 무료 1GB 스토리지, 엔터프라이즈급 보안.',
    keywords: 'Photo Cloud,클라우드 앨범,클라우드 스토리지,사진 관리,이미지 공유,파일 관리,온라인 앨범,사진 백업'
  }
}
