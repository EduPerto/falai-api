"""
Translation utility for Evo AI
Manages language switching and message translation
"""

import json
from pathlib import Path
from typing import Dict, Optional
from contextvars import ContextVar

# Context variable to store current language per request
current_language: ContextVar[str] = ContextVar("current_language", default="en")

# Cache for loaded translations
_translations_cache: Dict[str, Dict] = {}


def load_translations(language: str) -> Dict:
    """Load translation file for specified language"""
    if language in _translations_cache:
        return _translations_cache[language]

    locale_file = Path(__file__).parent / "locales" / f"{language}.json"

    if not locale_file.exists():
        # Fallback to English if language not found
        locale_file = Path(__file__).parent / "locales" / "en.json"

    with open(locale_file, "r", encoding="utf-8") as f:
        translations = json.load(f)

    _translations_cache[language] = translations
    return translations


def set_language(language: str) -> None:
    """Set the current language for the request context"""
    supported_languages = ["en", "pt-BR"]
    if language not in supported_languages:
        language = "en"  # Default to English
    current_language.set(language)


def get_current_language() -> str:
    """Get the current language from context"""
    return current_language.get()


class Translator:
    """Translation class for getting localized strings"""

    def __init__(self, language: Optional[str] = None):
        self.language = language or get_current_language()
        self.translations = load_translations(self.language)

    def t(self, key: str, **kwargs) -> str:
        """
        Translate a key to the current language

        Args:
            key: Translation key in dot notation (e.g., "auth.login.success")
            **kwargs: Variables to interpolate in the translation

        Returns:
            Translated string
        """
        # Navigate nested dictionary using dot notation
        keys = key.split(".")
        value = self.translations

        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                # Return key if translation not found
                return key

        # Interpolate variables if provided
        if isinstance(value, str) and kwargs:
            try:
                return value.format(**kwargs)
            except KeyError:
                return value

        return value if isinstance(value, str) else key


def get_translator(language: Optional[str] = None) -> Translator:
    """Get a translator instance for the specified language"""
    return Translator(language)
