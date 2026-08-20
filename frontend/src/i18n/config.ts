import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import enTranslations from './locales/en.json';
import deTranslations from './locales/de.json';
import itTranslations from './locales/it.json';
import esTranslations from './locales/es.json';
import frTranslations from './locales/fr.json';
import zhTranslations from './locales/zh.json';
import jaTranslations from './locales/ja.json';
import koTranslations from './locales/ko.json';

// Suppress i18next's promotional console message (hardcoded since v23)
const noop = () => {};
const origLog = console.log;
console.log = noop;
i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: {
        translation: enTranslations
      },
      de: {
        translation: deTranslations
      },
      it: {
        translation: itTranslations
      },
      es: {
        translation: esTranslations
      },
      fr: {
        translation: frTranslations
      },
      zh: {
        translation: zhTranslations
      },
      ja: {
        translation: jaTranslations
      },
      ko: {
        translation: koTranslations
      }
    },
    fallbackLng: 'en',
    load: 'languageOnly',
    debug: false,
    interpolation: {
      escapeValue: false
    },
    detection: {
      // Environment-only detection: pick up the browser/OS language on every
      // load. The explicit user choice is stored server-side (users.language)
      // and applied after login / on app load; we intentionally do NOT cache a
      // client-side language, so a previously stored choice can never clobber
      // detection. When users.language is empty, detection wins.
      order: ['navigator']
    }
  }).then(() => {
    console.log = origLog;
  });

export default i18n;
