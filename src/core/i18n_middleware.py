"""
I18n Middleware for FastAPI
Detects language from Accept-Language header or query parameter
"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from src.i18n import set_language


class I18nMiddleware(BaseHTTPMiddleware):
    """Middleware to set language for each request"""

    async def dispatch(self, request: Request, call_next):
        # Try to get language from query parameter first
        language = request.query_params.get("lang")

        # If not in query, try Accept-Language header
        if not language:
            accept_language = request.headers.get("Accept-Language", "en")
            # Parse Accept-Language header (e.g., "pt-BR,pt;q=0.9,en;q=0.8")
            if accept_language:
                # Get first language from header
                language = accept_language.split(",")[0].split(";")[0].strip()

        # Normalize language code
        if language:
            # Convert pt, pt-br, pt_BR to pt-BR
            if language.lower().startswith("pt"):
                language = "pt-BR"
            # Default to English for other languages
            elif not language.lower().startswith("en"):
                language = "en"
            else:
                language = "en"

        # Set language in context
        set_language(language)

        # Continue processing request
        response = await call_next(request)
        return response
