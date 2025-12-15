"""
Internationalization (i18n) module for Evo AI
Supports pt-BR (Portuguese Brazil) and en (English)
"""

from .translator import get_translator, set_language, get_current_language

__all__ = ["get_translator", "set_language", "get_current_language"]
