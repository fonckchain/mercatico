"""
Custom authentication classes for MercaTico.
"""
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, AuthenticationFailed


class JWTAuthenticationSafe(JWTAuthentication):
    """
    JWT Authentication that doesn't raise exceptions on invalid tokens.
    This allows endpoints with AllowAny permission to work even when
    an invalid/expired token is sent.
    """
    
    def authenticate(self, request):
        """
        Attempt to authenticate using JWT token.
        Returns None instead of raising exception if token is invalid,
        allowing permission classes to decide if authentication is required.
        """
        try:
            return super().authenticate(request)
        except (InvalidToken, AuthenticationFailed):
            # Return None to indicate no authentication, 
            # letting permission classes decide what to do
            return None
