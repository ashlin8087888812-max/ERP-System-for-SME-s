from passlib.context import CryptContext
import secrets
import hashlib

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

# === Refresh Token Security Functions ===

def generate_refresh_token() -> str:
    """
    Generate a cryptographically secure random refresh token.
    Uses 64 bytes (~512 bits) of entropy for maximum security.
    
    Returns:
        str: Token in format "rt_<urlsafe_base64_string>"
    """
    return f"rt_{secrets.token_urlsafe(64)}"

def hash_token(token: str) -> str:
    """
    Hash a token using SHA-256 for database storage.
    
    IMPORTANT: Never store raw tokens in the database.
    Always hash before storage to prevent token theft from DB dumps.
    
    Args:
        token: Raw refresh token to hash
        
    Returns:
        str: Hexadecimal SHA-256 hash of the token
    """
    return hashlib.sha256(token.encode()).hexdigest()

def verify_token_hash(token: str, token_hash: str) -> bool:
    """
    Verify a token against its stored hash.
    
    Args:
        token: Raw token to verify
        token_hash: Stored hash to verify against
        
    Returns:
        bool: True if token matches hash, False otherwise
    """
    return hash_token(token) == token_hash
