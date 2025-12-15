"""
Response builder utility with i18n support
Helps create consistent API responses with translated messages
"""

from typing import Any, Dict, Optional
from fastapi.responses import JSONResponse
from src.i18n import get_translator


class ResponseBuilder:
    """Builder for creating standardized API responses with i18n"""

    @staticmethod
    def success(
        message_key: str,
        data: Optional[Any] = None,
        status_code: int = 200,
        **message_params
    ) -> JSONResponse:
        """
        Create a success response

        Args:
            message_key: Translation key for success message
            data: Optional data to include in response
            status_code: HTTP status code
            **message_params: Parameters to interpolate in message
        """
        t = get_translator()
        message = t.t(message_key, **message_params)

        response = {
            "success": True,
            "message": message,
        }

        if data is not None:
            response["data"] = data

        return JSONResponse(content=response, status_code=status_code)

    @staticmethod
    def error(
        message_key: str,
        status_code: int = 400,
        errors: Optional[Dict] = None,
        **message_params
    ) -> JSONResponse:
        """
        Create an error response

        Args:
            message_key: Translation key for error message
            status_code: HTTP status code
            errors: Optional detailed errors
            **message_params: Parameters to interpolate in message
        """
        t = get_translator()
        message = t.t(message_key, **message_params)

        response = {
            "success": False,
            "message": message,
        }

        if errors:
            response["errors"] = errors

        return JSONResponse(content=response, status_code=status_code)

    @staticmethod
    def created(message_key: str, data: Any, **message_params) -> JSONResponse:
        """Create a 201 Created response"""
        return ResponseBuilder.success(
            message_key, data=data, status_code=201, **message_params
        )

    @staticmethod
    def no_content(message_key: str = "common.deleted", **message_params) -> JSONResponse:
        """Create a 204 No Content response"""
        return ResponseBuilder.success(
            message_key, status_code=204, **message_params
        )

    @staticmethod
    def not_found(message_key: str = "common.not_found", **message_params) -> JSONResponse:
        """Create a 404 Not Found response"""
        return ResponseBuilder.error(
            message_key, status_code=404, **message_params
        )

    @staticmethod
    def unauthorized(message_key: str = "common.unauthorized", **message_params) -> JSONResponse:
        """Create a 401 Unauthorized response"""
        return ResponseBuilder.error(
            message_key, status_code=401, **message_params
        )

    @staticmethod
    def forbidden(message_key: str = "common.forbidden", **message_params) -> JSONResponse:
        """Create a 403 Forbidden response"""
        return ResponseBuilder.error(
            message_key, status_code=403, **message_params
        )

    @staticmethod
    def validation_error(
        message_key: str = "common.validation_error",
        errors: Optional[Dict] = None,
        **message_params
    ) -> JSONResponse:
        """Create a 422 Validation Error response"""
        return ResponseBuilder.error(
            message_key, status_code=422, errors=errors, **message_params
        )
