# 🔧 Database Configuration and Connection Management
# SQLAlchemy setup for Cloud Video Network Monitoring

import os
from sqlalchemy import create_engine, MetaData
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.declarative import declarative_base
from contextlib import contextmanager
import logging
from typing import Generator

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DatabaseConfig:
    """Database configuration management"""
    
    def __init__(self):
        # Database URL configuration
        self.DB_HOST = os.getenv("DB_HOST", "localhost")
        self.DB_PORT = os.getenv("DB_PORT", "5432")
        self.DB_NAME = os.getenv("DB_NAME", "cloud_video_monitoring")
        self.DB_USER = os.getenv("DB_USER", "postgres")
        self.DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
        
        # SQLite fallback for development
        self.USE_SQLITE = os.getenv("USE_SQLITE", "true").lower() == "true"
        
        # Connection pool settings
        self.POOL_SIZE = int(os.getenv("DB_POOL_SIZE", "10"))
        self.MAX_OVERFLOW = int(os.getenv("DB_MAX_OVERFLOW", "20"))
        self.POOL_TIMEOUT = int(os.getenv("DB_POOL_TIMEOUT", "30"))
        self.POOL_RECYCLE = int(os.getenv("DB_POOL_RECYCLE", "3600"))
        
        # Connection settings
        self.ECHO_SQL = os.getenv("DB_ECHO", "false").lower() == "true"
        
    def get_database_url(self) -> str:
        """Get database connection URL"""
        if self.USE_SQLITE:
            # SQLite for development/testing
            db_path = os.path.join("backend", "database", "cloud_video_monitoring.db")
            os.makedirs(os.path.dirname(db_path), exist_ok=True)
            return f"sqlite:///{db_path}"
        else:
            # PostgreSQL for production
            return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

class DatabaseManager:
    """Database connection and session management"""
    
    def __init__(self):
        self.config = DatabaseConfig()
        self.engine = None
        self.SessionLocal = None
        self._initialize_database()
    
    def _initialize_database(self):
        """Initialize database connection and session factory"""
        database_url = self.config.get_database_url()
        
        if self.config.USE_SQLITE:
            # SQLite configuration
            self.engine = create_engine(
                database_url,
                echo=self.config.ECHO_SQL,
                connect_args={"check_same_thread": False}  # SQLite specific
            )
        else:
            # PostgreSQL configuration
            self.engine = create_engine(
                database_url,
                echo=self.config.ECHO_SQL,
                pool_size=self.config.POOL_SIZE,
                max_overflow=self.config.MAX_OVERFLOW,
                pool_timeout=self.config.POOL_TIMEOUT,
                pool_recycle=self.config.POOL_RECYCLE,
                pool_pre_ping=True  # Validate connections before use
            )
        
        # Create session factory
        self.SessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=self.engine
        )
        
        logger.info(f"Database initialized: {database_url}")
    
    def create_tables(self):
        """Create all database tables"""
        from .models import Base
        
        try:
            Base.metadata.create_all(bind=self.engine)
            logger.info("✅ Database tables created successfully")
        except Exception as e:
            logger.error(f"❌ Error creating database tables: {e}")
            raise
    
    def drop_tables(self):
        """Drop all database tables (use with caution!)"""
        from .models import Base
        
        try:
            Base.metadata.drop_all(bind=self.engine)
            logger.info("🗑️ Database tables dropped")
        except Exception as e:
            logger.error(f"❌ Error dropping database tables: {e}")
            raise
    
    @contextmanager
    def get_session(self) -> Generator[Session, None, None]:
        """Get database session with automatic cleanup"""
        session = self.SessionLocal()
        try:
            yield session
            session.commit()
        except Exception as e:
            session.rollback()
            logger.error(f"Database session error: {e}")
            raise
        finally:
            session.close()
    
    def get_session_sync(self) -> Session:
        """Get database session (manual management)"""
        return self.SessionLocal()
    
    def test_connection(self) -> bool:
        """Test database connection"""
        try:
            with self.get_session() as session:
                session.execute("SELECT 1")
            logger.info("✅ Database connection test successful")
            return True
        except Exception as e:
            logger.error(f"❌ Database connection test failed: {e}")
            return False
    
    def initialize_data(self):
        """Initialize database with default data"""
        from .models import SystemConfig, LivepeerIntegration
        
        with self.get_session() as session:
            # Check if data already exists
            if session.query(SystemConfig).first():
                logger.info("Database already initialized")
                return
            
            # Default system configuration
            default_configs = [
                SystemConfig(
                    key="livepeer_api_key",
                    value="40d145e9-4cae-4913-89a2-fcd1c4fa3bfb",
                    description="Livepeer API key for video streaming"
                ),
                SystemConfig(
                    key="max_video_size_mb",
                    value="500",
                    description="Maximum video file size in MB"
                ),
                SystemConfig(
                    key="supported_formats",
                    value="mp4,webm,avi,mov",
                    description="Supported video formats"
                ),
                SystemConfig(
                    key="default_quality",
                    value="720p",
                    description="Default video quality"
                ),
                SystemConfig(
                    key="enable_livepeer",
                    value="true",
                    description="Enable Livepeer integration"
                ),
                SystemConfig(
                    key="analytics_retention_days",
                    value="90",
                    description="How long to keep analytics data"
                )
            ]
            
            for config in default_configs:
                session.add(config)
            
            # Initialize Livepeer integration record
            livepeer_integration = LivepeerIntegration(
                api_key="40d145e9-4cae-4913-89a2-fcd1c4fa3bfb"
            )
            session.add(livepeer_integration)
            
            session.commit()
            logger.info("✅ Database initialized with default data")

# Global database manager instance
db_manager = DatabaseManager()

# Dependency for FastAPI
def get_database_session() -> Generator[Session, None, None]:
    """FastAPI dependency for database sessions"""
    with db_manager.get_session() as session:
        yield session

# Database utilities
class DatabaseUtils:
    """Database utility functions"""
    
    @staticmethod
    def backup_database(backup_path: str) -> bool:
        """Backup database (SQLite only)"""
        if not db_manager.config.USE_SQLITE:
            logger.warning("Backup only supported for SQLite databases")
            return False
        
        try:
            import shutil
            source = db_manager.config.get_database_url().replace("sqlite:///", "")
            shutil.copy2(source, backup_path)
            logger.info(f"✅ Database backed up to: {backup_path}")
            return True
        except Exception as e:
            logger.error(f"❌ Database backup failed: {e}")
            return False
    
    @staticmethod
    def restore_database(backup_path: str) -> bool:
        """Restore database from backup (SQLite only)"""
        if not db_manager.config.USE_SQLITE:
            logger.warning("Restore only supported for SQLite databases")
            return False
        
        try:
            import shutil
            target = db_manager.config.get_database_url().replace("sqlite:///", "")
            shutil.copy2(backup_path, target)
            logger.info(f"✅ Database restored from: {backup_path}")
            return True
        except Exception as e:
            logger.error(f"❌ Database restore failed: {e}")
            return False
    
    @staticmethod
    def get_database_stats() -> dict:
        """Get database statistics"""
        stats = {}
        
        try:
            with db_manager.get_session() as session:
                from .models import User, Video, Session, StreamSession, VideoAnalytics
                
                stats = {
                    "users": session.query(User).count(),
                    "videos": session.query(Video).count(),
                    "sessions": session.query(Session).count(),
                    "stream_sessions": session.query(StreamSession).count(),
                    "analytics_records": session.query(VideoAnalytics).count(),
                    "database_url": db_manager.config.get_database_url(),
                    "database_type": "SQLite" if db_manager.config.USE_SQLITE else "PostgreSQL"
                }
        except Exception as e:
            logger.error(f"Error getting database stats: {e}")
            stats["error"] = str(e)
        
        return stats

# Initialize database on import
if __name__ == "__main__":
    # Test database setup
    print("🗄️ Testing database setup...")
    
    # Test connection
    if db_manager.test_connection():
        print("✅ Database connection successful")
    else:
        print("❌ Database connection failed")
        exit(1)
    
    # Create tables
    try:
        db_manager.create_tables()
        print("✅ Database tables created")
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        exit(1)
    
    # Initialize data
    try:
        db_manager.initialize_data()
        print("✅ Database initialized with default data")
    except Exception as e:
        print(f"❌ Error initializing data: {e}")
    
    # Show stats
    stats = DatabaseUtils.get_database_stats()
    print(f"📊 Database stats: {stats}")
    
    print("🎉 Database setup complete!")
