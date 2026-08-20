import { ReactNode, createContext, useContext, useEffect, useMemo, useState, useCallback } from "react";
import i18n from './i18n/config';

export type DateFormat = "eu" | "us" | "iso" | "cjk" | "ko";

const SUPPORTED_DATE_FORMATS: DateFormat[] = ["eu", "us", "iso", "cjk", "ko"];

// Most-common display date format for each supported UI language. Used when the
// user has not explicitly chosen a date format: the format then follows the
// selected language. This mirrors the language-priority rule where the backend
// stores an empty value until the user picks one in Settings.
const DEFAULT_DATE_FORMAT_FOR_LANGUAGE: Record<string, DateFormat> = {
  en: "us", // MM/DD/YYYY
  de: "eu", // DD.MM.YYYY
  it: "eu", // DD/MM/YYYY
  es: "eu", // DD/MM/YYYY
  fr: "eu", // DD/MM/YYYY
  zh: "cjk", // YYYY年M月D日
  ja: "cjk", // YYYY年M月D日
  ko: "ko", // YYYY.MM.DD
};

// Resolve the date format that should be used when the user has not made an
// explicit choice. Falls back to ISO for unknown languages.
export function getDefaultDateFormatForLanguage(lang: string | undefined): DateFormat {
  if (!lang) return "iso";
  const base = lang.split("-")[0];
  return DEFAULT_DATE_FORMAT_FOR_LANGUAGE[base] ?? "iso";
}

interface DateFormatContextValue {
  dateFormat: DateFormat;
  dateFormatExplicit: DateFormat | null;
  setDateFormat: (format: DateFormat | null) => void;
  formatDate: (dateString: string) => string;
  formatBirthday: (birthday: string, includeAge?: boolean) => string;
  formatBirthdayForInput: (birthday: string) => string;
  parseBirthdayInput: (input: string) => string | null;
  autoFormatBirthdayInput: (newValue: string, prevValue: string) => string;
  getBirthdayPlaceholder: () => string;
  getBirthdayFormatHint: () => string;
  getDatePlaceholder: () => string;
  calculateAge: (birthday: string) => number | null;
}

const DateFormatContext = createContext<DateFormatContextValue | undefined>(undefined);

const DATE_FORMAT_STORAGE_KEY = "dateFormat";

// Module-level hook so non-React modules (auth.ts, LoginPage) can push the
// backend's explicit date-format preference into the live provider state.
// `null` means "follow the language" (no explicit choice).
let setExplicitFormatRef: ((format: DateFormat | null) => void) | null = null;

// Initialize date format from the backend value (called on login / refresh).
// An empty/unknown value means "follow the language": we clear the explicit
// choice so the provider derives the format from the active language. An
// explicit value (highest priority) is stored as-is.
export function initializeDateFormatFromBackend(dateFormat: string | undefined): void {
  const normalized =
    dateFormat && SUPPORTED_DATE_FORMATS.includes(dateFormat as DateFormat)
      ? (dateFormat as DateFormat)
      : null;
  setExplicitFormatRef?.(normalized);
}

/**
 * Calculate age from a birthday string (YYYY-MM-DD or --MM-DD)
 * Returns null if no year is provided or if the format is invalid
 */
export function calculateAgeFromBirthday(birthday: string): number | null {
  if (!birthday || birthday.startsWith('--')) {
    return null;
  }

  const parts = birthday.split('-');
  if (parts.length !== 3 || parts[0].length !== 4) {
    return null;
  }

  const birthYear = parseInt(parts[0], 10);
  const month = parseInt(parts[1], 10);
  const day = parseInt(parts[2], 10);

  if (isNaN(day) || isNaN(month) || isNaN(birthYear)) {
    return null;
  }

  const today = new Date();
  const currentYear = today.getFullYear();
  const currentMonth = today.getMonth() + 1;
  const currentDay = today.getDate();

  let age = currentYear - birthYear;

  // Adjust if birthday hasn't occurred yet this year
  if (month > currentMonth || (month === currentMonth && day > currentDay)) {
    age--;
  }

  return age >= 0 ? age : null;
}

const pad2 = (s: string): string => s.padStart(2, '0');

/**
 * Format a standard date (ISO format) to the user's preferred display format
 */
export function formatDateWithFormat(dateString: string, format: DateFormat): string {
  if (!dateString) return '';

  const date = new Date(dateString);
  if (isNaN(date.getTime())) return dateString;

  const day = String(date.getUTCDate()).padStart(2, '0');
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const year = date.getUTCFullYear();

  switch (format) {
    case 'eu':
      return `${day}.${month}.${year}`;
    case 'iso':
      return `${year}-${month}-${day}`;
    case 'ko':
      return `${year}.${month}.${day}`;
    case 'cjk':
      return `${year}年${parseInt(month, 10)}月${parseInt(day, 10)}日`;
    default: // us
      return `${month}/${day}/${year}`;
  }
}

/**
 * Format a birthday (YYYY-MM-DD or --MM-DD) to the user's preferred display format
 * Optionally includes age calculation
 */
export function formatBirthdayWithFormat(birthday: string, format: DateFormat, includeAge: boolean = false): string {
  if (!birthday) return '';

  // Check if it's a year-less birthday (starts with --)
  if (birthday.startsWith('--')) {
    const month = birthday.substring(2, 4);
    const day = birthday.substring(5, 7);

    switch (format) {
      case 'eu':
        return `${day}.${month}.`;
      case 'iso':
        return `${month}-${day}`;
      case 'ko':
        return `${month}.${day}`;
      case 'cjk':
        return `${parseInt(month, 10)}月${parseInt(day, 10)}日`;
      default: // us
        return `${month}/${day}`;
    }
  }

  // YYYY-MM-DD format
  const parts = birthday.split('-');
  if (parts.length === 3) {
    const year = parts[0];
    const month = parts[1];
    const day = parts[2];

    let dateStr: string;

    switch (format) {
      case 'eu':
        dateStr = `${day}.${month}.${year}`; break;
      case 'iso':
        dateStr = `${year}-${month}-${day}`; break;
      case 'ko':
        dateStr = `${year}.${month}.${day}`; break;
      case 'cjk':
        dateStr = `${year}年${parseInt(month, 10)}月${parseInt(day, 10)}日`; break;
      default: // us
        dateStr = `${month}/${day}/${year}`;
    }

    // Calculate age if requested and year is valid
    if (includeAge && year && year.length === 4) {
      const birthYear = parseInt(year, 10);
      if (!isNaN(birthYear)) {
        const today = new Date();
        const birthDate = new Date(birthYear, parseInt(month, 10) - 1, parseInt(day, 10));
        let age = today.getFullYear() - birthYear;

        // Adjust if birthday hasn't occurred yet this year
        if (today < new Date(today.getFullYear(), birthDate.getMonth(), birthDate.getDate())) {
          age--;
        }

        if (age >= 0) {
          return `${dateStr} (${age})`;
        }
      }
    }

    return dateStr;
  }

  return birthday; // Return as-is if format doesn't match
}

/**
 * Format a birthday for editing (convert ISO to display format)
 */
export function formatBirthdayForInputWithFormat(birthday: string, format: DateFormat): string {
  if (!birthday) return '';

  // Check if it's a year-less birthday (starts with --)
  if (birthday.startsWith('--')) {
    const month = birthday.substring(2, 4);
    const day = birthday.substring(5, 7);

    switch (format) {
      case 'eu':
        return `${day}.${month}.`;
      case 'iso':
        return `${month}-${day}`;
      case 'ko':
        return `${month}.${day}`;
      case 'cjk':
        return `${parseInt(month, 10)}月${parseInt(day, 10)}日`;
      default: // us
        return `${month}/${day}`;
    }
  }

  // YYYY-MM-DD format
  const parts = birthday.split('-');
  if (parts.length === 3) {
    const year = parts[0];
    const month = parts[1];
    const day = parts[2];

    switch (format) {
      case "eu":
        return `${day}.${month}.${year}`;
      case "iso":
        return `${year}-${month}-${day}`;
      case "ko":
        return `${year}.${month}.${day}`;
      case "cjk":
        return `${year}年${parseInt(month, 10)}月${parseInt(day, 10)}日`;
      default: // us
        return `${month}/${day}/${year}`;
    }
  }

  return birthday;
}

/**
 * Parse user input in display format back to ISO format for storage
 * Returns null if input is invalid
 */
export function parseBirthdayInputWithFormat(input: string, format: DateFormat): string | null {
  if (!input || input.trim() === '') return '';

  const trimmed = input.trim();

  // Also accept ISO format directly (YYYY-MM-DD or --MM-DD)
  const isoFullDateRegex = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/;
  const isoYearlessRegex = /^--(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/;
  if (isoFullDateRegex.test(trimmed) || isoYearlessRegex.test(trimmed)) {
    return trimmed;
  }

  if (format === "eu") {
    // EU format: DD.MM.YYYY or DD.MM.
    const euFullMatch = trimmed.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/);
    if (euFullMatch) {
      const day = pad2(euFullMatch[1]);
      const month = pad2(euFullMatch[2]);
      const year = euFullMatch[3];
      if (!isValidMD(day, month)) return null;
      return `${year}-${month}-${day}`;
    }
    const euYearlessMatch = trimmed.match(/^(\d{1,2})\.(\d{1,2})\.?$/);
    if (euYearlessMatch) {
      const day = pad2(euYearlessMatch[1]);
      const month = pad2(euYearlessMatch[2]);
      if (!isValidMD(day, month)) return null;
      return `--${month}-${day}`;
    }
  } else if (format === "ko") {
    // Korean format: YYYY.MM.DD or MM.DD (zero-padded, dotted)
    const koFullMatch = trimmed.match(/^(\d{4})\.(\d{1,2})\.(\d{1,2})$/);
    if (koFullMatch) {
      const day = pad2(koFullMatch[3]);
      const month = pad2(koFullMatch[2]);
      const year = koFullMatch[1];
      if (!isValidMD(day, month)) return null;
      return `${year}-${month}-${day}`;
    }
    const koYearlessMatch = trimmed.match(/^(\d{1,2})\.(\d{1,2})$/);
    if (koYearlessMatch) {
      const day = pad2(koYearlessMatch[2]);
      const month = pad2(koYearlessMatch[1]);
      if (!isValidMD(day, month)) return null;
      return `--${month}-${day}`;
    }
  } else if (format === "cjk") {
    // CJK format: YYYY年M月D日 or M月D日 (no leading zeros)
    const cjkFullMatch = trimmed.match(/^(\d{4})年(\d{1,2})月(\d{1,2})日$/);
    if (cjkFullMatch) {
      const day = pad2(cjkFullMatch[3]);
      const month = pad2(cjkFullMatch[2]);
      const year = cjkFullMatch[1];
      if (!isValidMD(day, month)) return null;
      return `${year}-${month}-${day}`;
    }
    const cjkYearlessMatch = trimmed.match(/^(\d{1,2})月(\d{1,2})日$/);
    if (cjkYearlessMatch) {
      const day = pad2(cjkYearlessMatch[2]);
      const month = pad2(cjkYearlessMatch[1]);
      if (!isValidMD(day, month)) return null;
      return `--${month}-${day}`;
    }
  } else {
    // US format: MM/DD/YYYY or MM/DD (also accepts ISO MM-DD for year-less)
    const usFullMatch = trimmed.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
    if (usFullMatch) {
      const month = pad2(usFullMatch[1]);
      const day = pad2(usFullMatch[2]);
      const year = usFullMatch[3];
      if (!isValidMD(day, month)) return null;
      return `${year}-${month}-${day}`;
    }
    const usYearlessMatch = trimmed.match(/^(\d{1,2})[-/](\d{1,2})$/);
    if (usYearlessMatch) {
      const month = pad2(usYearlessMatch[1]);
      const day = pad2(usYearlessMatch[2]);
      if (!isValidMD(day, month)) return null;
      return `--${month}-${day}`;
    }
  }

  return null;
}

// isValidMD validates day/month components (1-12 month, 1-31 day).
function isValidMD(day: string, month: string): boolean {
  const m = parseInt(month, 10);
  const d = parseInt(day, 10);
  return m >= 1 && m <= 12 && d >= 1 && d <= 31;
}

export function autoFormatBirthdayInputWithFormat(newValue: string, prevValue: string, format: DateFormat): string {
  const newDigits = newValue.replace(/[^0-9]/g, '');
  const prevDigits = prevValue.replace(/[^0-9]/g, '');

  if (format === 'iso') {
    if (newDigits.length < prevDigits.length) {
      return newValue.replace(/-+$/, '');
    }
    if (newDigits.length <= 4) {
      return newValue;
    }
    const formatted =
      newDigits.slice(0, 4) + '-' + newDigits.slice(4, 6) +
      (newDigits.length > 6 ? '-' + newDigits.slice(6, 8) : '');
    if (
      newDigits.length === 6 &&
      newDigits.length === prevDigits.length &&
      newValue.length > prevValue.length &&
      /-$/.test(newValue)
    ) {
      return formatted + '-';
    }
    return formatted;
  }

  if (format === 'ko') {
    if (newDigits.length < prevDigits.length) {
      return newValue.replace(/\.+$/, '');
    }
    const y = newDigits.slice(0, 4);
    let out = y;
    if (newDigits.length > 4) out += '.' + newDigits.slice(4, 6);
    if (newDigits.length > 6) out += '.' + newDigits.slice(6, 8);
    return out;
  }

  if (format === 'cjk') {
    if (newDigits.length < prevDigits.length) {
      return newValue.replace(/[年月日]+$/, '');
    }
    const y = newDigits.slice(0, 4);
    let out = y;
    const rest = newDigits.slice(4); // month + day digits
    if (rest.length > 0) {
      // Month is 1 or 2 digits; prefer 2 only when the two digits form <= 12.
      const mi = rest.length >= 2 && parseInt(rest.slice(0, 2), 10) <= 12 ? 2 : 1;
      const month = parseInt(rest.slice(0, mi), 10);
      out += '年' + month;
      const dayRest = rest.slice(mi);
      if (dayRest.length > 0) {
        const day = parseInt(dayRest.slice(0, 2), 10);
        out += '月' + day + '日';
      }
    }
    return out;
  }

  const sep = format === 'eu' ? '.' : '/';

  const formatDigits = (digits: string): string => {
    if (digits.length <= 2) return digits;
    if (digits.length <= 4) return digits.slice(0, 2) + sep + digits.slice(2);
    return digits.slice(0, 2) + sep + digits.slice(2, 4) + sep + digits.slice(4, 8);
  };

  if (newDigits.length < prevDigits.length) {
    return newValue.replace(/[./]+$/, '');
  }

  if (newDigits.length === prevDigits.length) {
    const formatted = formatDigits(newDigits);
    const atBoundary = newDigits.length === 2 || newDigits.length === 4;
    const endsWithSep = /[./]$/.test(newValue);
    if (atBoundary && newValue.length > prevValue.length && endsWithSep) {
      return formatted + sep;
    }
    return formatted;
  }

  return formatDigits(newDigits);
}

export function DateFormatProvider({ children }: { children: ReactNode }) {
  // The user's explicit choice (null = follow the active language).
  const [explicitFormat, setExplicitFormat] = useState<DateFormat | null>(() => {
    if (typeof window === "undefined") return null;
    const stored = window.localStorage.getItem(DATE_FORMAT_STORAGE_KEY);
    return stored && SUPPORTED_DATE_FORMATS.includes(stored as DateFormat)
      ? (stored as DateFormat)
      : null;
  });

  // Track the active language so the derived format updates when the user
  // switches language (Settings) or when environment detection runs on load.
  const [activeLanguage, setActiveLanguage] = useState<string>(() =>
    i18n.resolvedLanguage || i18n.language || "en"
  );

  useEffect(() => {
    const onLangChanged = (lng: string) => setActiveLanguage(lng);
    i18n.on("languageChanged", onLangChanged);
    return () => {
      i18n.off("languageChanged", onLangChanged);
    };
  }, []);

  useEffect(() => {
    // Expose the setter so initializeDateFormatFromBackend (called from
    // auth.ts / LoginPage) can update the live state.
    setExplicitFormatRef = setExplicitFormat;
    return () => {
      setExplicitFormatRef = null;
    };
  }, []);

  useEffect(() => {
    // Persist the explicit choice (or its absence) across reloads.
    if (typeof window === "undefined") return;
    if (explicitFormat) {
      window.localStorage.setItem(DATE_FORMAT_STORAGE_KEY, explicitFormat);
    } else {
      window.localStorage.removeItem(DATE_FORMAT_STORAGE_KEY);
    }
  }, [explicitFormat]);

  // Priority: explicit user choice > language-derived default.
  const effectiveFormat: DateFormat =
    explicitFormat ?? getDefaultDateFormatForLanguage(activeLanguage);

  const setDateFormat = useCallback((format: DateFormat | null) => {
    setExplicitFormat(format);
  }, []);

  const formatDate = useCallback(
    (dateString: string) => formatDateWithFormat(dateString, effectiveFormat),
    [effectiveFormat]
  );

  const formatBirthday = useCallback(
    (birthday: string, includeAge: boolean = false) => formatBirthdayWithFormat(birthday, effectiveFormat, includeAge),
    [effectiveFormat]
  );

  const formatBirthdayForInput = useCallback(
    (birthday: string) => formatBirthdayForInputWithFormat(birthday, effectiveFormat),
    [effectiveFormat]
  );

  const parseBirthdayInput = useCallback(
    (input: string) => parseBirthdayInputWithFormat(input, effectiveFormat),
    [effectiveFormat]
  );

  const autoFormatBirthdayInput = useCallback(
    (newValue: string, prevValue: string) =>
      autoFormatBirthdayInputWithFormat(newValue, prevValue, effectiveFormat),
    [effectiveFormat]
  );

  const getBirthdayPlaceholder = useCallback(() => {
    switch (effectiveFormat) {
      case "eu":
        return "DD.MM.YYYY";
      case "iso":
        return "YYYY-MM-DD";
      case "ko":
        return "YYYY.MM.DD";
      case "cjk":
        return "YYYY年M月D日";
      default: // us
        return "MM/DD/YYYY";
    }
  }, [effectiveFormat]);

  const getBirthdayFormatHint = useCallback(() => {
    switch (effectiveFormat) {
      case "eu":
        return "DD.MM.YYYY (year optional, e.g., 30.04.1990 or 30.04.)";
      case "iso":
        return "YYYY-MM-DD (year optional, e.g., 1990-04-30 or --04-30 or 04-30)";
      case "ko":
        return "YYYY.MM.DD (year optional, e.g., 2026.08.20 or 08.20)";
      case "cjk":
        return "YYYY年M月D日 (year optional, e.g., 2026年8月20日 or 8月20日)";
      default: // us
        return "MM/DD/YYYY (year optional, e.g., 04/30/1990 or 04/30)";
    }
  }, [effectiveFormat]);

  const getDatePlaceholder = useCallback(() => {
    switch (effectiveFormat) {
      case "eu":
        return "DD.MM.YYYY";
      case "iso":
        return "YYYY-MM-DD";
      case "ko":
        return "YYYY.MM.DD";
      case "cjk":
        return "YYYY年M月D日";
      default: // us
        return "MM/DD/YYYY";
    }
  }, [effectiveFormat]);

  const calculateAge = useCallback(
    (birthday: string) => calculateAgeFromBirthday(birthday),
    []
  );

  const contextValue = useMemo(
    () => ({
      dateFormat: effectiveFormat,
      dateFormatExplicit: explicitFormat,
      setDateFormat,
      formatDate,
      formatBirthday,
      formatBirthdayForInput,
      parseBirthdayInput,
      autoFormatBirthdayInput,
      getBirthdayPlaceholder,
      getBirthdayFormatHint,
      getDatePlaceholder,
      calculateAge,
    }),
    [effectiveFormat, explicitFormat, setDateFormat, formatDate, formatBirthday, formatBirthdayForInput, parseBirthdayInput, autoFormatBirthdayInput, getBirthdayPlaceholder, getBirthdayFormatHint, getDatePlaceholder, calculateAge]
  );

  return (
    <DateFormatContext.Provider value={contextValue}>
      {children}
    </DateFormatContext.Provider>
  );
}

export const useDateFormat = () => {
  const context = useContext(DateFormatContext);

  if (!context) {
    throw new Error("useDateFormat must be used within DateFormatProvider");
  }

  return context;
};
