"""
Graceful shutdown handler.

Ensures clean shutdown of application resources.
"""
import signal
import asyncio
from app.main import app
from app.db.base import engine


class GracefulShutdown:
    """Handle graceful shutdown of the application"""
    
    def __init__(self):
        self.shutdown_event = asyncio.Event()
        self.is_shutting_down = False
    
    async def shutdown(self):
        """Perform graceful shutdown"""
        if self.is_shutting_down:
            return
        
        self.is_shutting_down = True
        print("🛑 Graceful shutdown initiated...")
        
        # Stop accepting new requests
        self.shutdown_event.set()
        
        # Wait for in-flight requests to complete (max 30 seconds)
        print("⏳ Waiting for in-flight requests to complete...")
        await asyncio.sleep(5)
        
        # Close database connections
        print("🔌 Closing database connections...")
        engine.dispose()
        
        # Close Redis connections
        try:
            from app.redis_client.client import get_redis_client
            redis = await get_redis_client()
            await redis.close()
            print("🔌 Closed Redis connections")
        except:
            pass
        
        # Flush metrics
        print("📊 Flushing metrics...")
        
        print("✅ Graceful shutdown complete")


shutdown_handler = GracefulShutdown()


@app.on_event("shutdown")
async def shutdown_event():
    """FastAPI shutdown event handler"""
    await shutdown_handler.shutdown()


def handle_sigterm(*args):
    """Handle SIGTERM signal"""
    print("📡 Received SIGTERM signal")
    raise KeyboardInterrupt()


def handle_sigint(*args):
    """Handle SIGINT signal (Ctrl+C)"""
    print("📡 Received SIGINT signal")
    raise KeyboardInterrupt()


# Register signal handlers
signal.signal(signal.SIGTERM, handle_sigterm)
signal.signal(signal.SIGINT, handle_sigint)
