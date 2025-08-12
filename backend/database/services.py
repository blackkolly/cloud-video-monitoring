# 📊 Database Service Layer
# Business logic for database operations

from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, and_, or_
from datetime import datetime, timedelta
import logging
from uuid import UUID

from .models import (
    User, Video, Session as UserSession, StreamSession, 
    SessionEvent, StreamEvent, VideoAnalytics, UserAnalytics,
    LivepeerIntegration, SystemConfig
)
from . import db_manager

logger = logging.getLogger(__name__)

class UserService:
    """User management service"""
    
    @staticmethod
    def create_user(session: Session, username: str, email: str, password_hash: str) -> User:
        """Create a new user"""
        user = User(
            username=username,
            email=email,
            password_hash=password_hash
        )
        session.add(user)
        session.flush()
        logger.info(f"User created: {username} ({user.id})")
        return user
    
    @staticmethod
    def get_user_by_email(session: Session, email: str) -> Optional[User]:
        """Get user by email"""
        return session.query(User).filter(User.email == email).first()
    
    @staticmethod
    def get_user_by_username(session: Session, username: str) -> Optional[User]:
        """Get user by username"""
        return session.query(User).filter(User.username == username).first()
    
    @staticmethod
    def update_last_login(session: Session, user_id: UUID) -> bool:
        """Update user's last login time"""
        user = session.query(User).filter(User.id == user_id).first()
        if user:
            user.last_login = datetime.utcnow()
            return True
        return False

class VideoService:
    """Video management service"""
    
    @staticmethod
    def create_video(session: Session, owner_id: UUID, title: str, filename: str, 
                    file_path: str, **kwargs) -> Video:
        """Create a new video record"""
        video = Video(
            title=title,
            filename=filename,
            file_path=file_path,
            owner_id=owner_id,
            **kwargs
        )
        session.add(video)
        session.flush()
        logger.info(f"Video created: {title} ({video.id})")
        return video
    
    @staticmethod
    def get_video_by_id(session: Session, video_id: UUID) -> Optional[Video]:
        """Get video by ID"""
        return session.query(Video).filter(Video.id == video_id).first()
    
    @staticmethod
    def get_videos_by_owner(session: Session, owner_id: UUID, 
                           limit: int = 50, offset: int = 0) -> List[Video]:
        """Get videos by owner"""
        return (session.query(Video)
                .filter(Video.owner_id == owner_id)
                .order_by(desc(Video.created_at))
                .offset(offset)
                .limit(limit)
                .all())
    
    @staticmethod
    def update_video_status(session: Session, video_id: UUID, status: str) -> bool:
        """Update video processing status"""
        video = session.query(Video).filter(Video.id == video_id).first()
        if video:
            video.status = status
            video.updated_at = datetime.utcnow()
            return True
        return False
    
    @staticmethod
    def update_livepeer_info(session: Session, video_id: UUID, 
                           asset_id: str, playback_id: str) -> bool:
        """Update Livepeer integration info"""
        video = session.query(Video).filter(Video.id == video_id).first()
        if video:
            video.livepeer_asset_id = asset_id
            video.livepeer_playback_id = playback_id
            video.use_livepeer = True
            video.updated_at = datetime.utcnow()
            return True
        return False

class SessionService:
    """Session management service"""
    
    @staticmethod
    def create_session(session: Session, user_id: Optional[UUID], session_token: str,
                      user_agent: str = None, ip_address: str = None, 
                      session_type: str = "user", is_special: bool = False) -> UserSession:
        """Create a new session"""
        user_session = UserSession(
            user_id=user_id,
            session_token=session_token,
            user_agent=user_agent,
            ip_address=ip_address,
            session_type=session_type,
            is_special=is_special
        )
        session.add(user_session)
        session.flush()
        logger.info(f"Session created: {session_token[:8]}... ({user_session.id})")
        return user_session
    
    @staticmethod
    def get_session_by_token(session: Session, token: str) -> Optional[UserSession]:
        """Get session by token"""
        return session.query(UserSession).filter(UserSession.session_token == token).first()
    
    @staticmethod
    def create_livepeer_session(session: Session, api_key: str) -> UserSession:
        """Create special session for Livepeer API key"""
        return SessionService.create_session(
            session=session,
            user_id=None,
            session_token=api_key,
            session_type="livepeer",
            is_special=True
        )
    
    @staticmethod
    def add_session_event(session: Session, session_id: UUID, 
                         event_type: str, event_data: Dict = None) -> SessionEvent:
        """Add event to session"""
        event = SessionEvent(
            session_id=session_id,
            event_type=event_type,
            event_data=event_data or {}
        )
        session.add(event)
        session.flush()
        return event

class StreamService:
    """Video streaming service"""
    
    @staticmethod
    def create_stream_session(session: Session, video_id: UUID, 
                            session_id: Optional[UUID] = None, **kwargs) -> StreamSession:
        """Create a new streaming session"""
        stream_session = StreamSession(
            video_id=video_id,
            session_id=session_id,
            **kwargs
        )
        session.add(stream_session)
        session.flush()
        logger.info(f"Stream session created: {stream_session.id}")
        return stream_session
    
    @staticmethod
    def get_stream_session(session: Session, stream_id: UUID) -> Optional[StreamSession]:
        """Get stream session by ID"""
        return session.query(StreamSession).filter(StreamSession.id == stream_id).first()
    
    @staticmethod
    def update_stream_position(session: Session, stream_id: UUID, 
                             current_time: float) -> bool:
        """Update stream playback position"""
        stream = session.query(StreamSession).filter(StreamSession.id == stream_id).first()
        if stream:
            stream.current_time = current_time
            return True
        return False
    
    @staticmethod
    def add_stream_event(session: Session, stream_id: UUID, event_type: str,
                        playback_time: float = None, event_data: Dict = None) -> StreamEvent:
        """Add event to stream session"""
        event = StreamEvent(
            stream_session_id=stream_id,
            event_type=event_type,
            playback_time=playback_time,
            event_data=event_data or {}
        )
        session.add(event)
        session.flush()
        return event
    
    @staticmethod
    def end_stream_session(session: Session, stream_id: UUID) -> bool:
        """End streaming session"""
        stream = session.query(StreamSession).filter(StreamSession.id == stream_id).first()
        if stream and stream.status == "active":
            stream.ended_at = datetime.utcnow()
            stream.status = "ended"
            if stream.started_at:
                stream.duration = (stream.ended_at - stream.started_at).total_seconds()
            return True
        return False

class AnalyticsService:
    """Analytics and reporting service"""
    
    @staticmethod
    def create_video_analytics(session: Session, video_id: UUID, date: datetime = None) -> VideoAnalytics:
        """Create video analytics record"""
        analytics = VideoAnalytics(
            video_id=video_id,
            date=date or datetime.utcnow()
        )
        session.add(analytics)
        session.flush()
        return analytics
    
    @staticmethod
    def get_video_stats(session: Session, video_id: UUID, 
                       days: int = 30) -> Dict[str, Any]:
        """Get video statistics for the last N days"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        # Get stream sessions for this video
        streams = (session.query(StreamSession)
                  .filter(StreamSession.video_id == video_id)
                  .filter(StreamSession.started_at >= start_date)
                  .all())
        
        # Calculate statistics
        total_views = len(streams)
        total_watch_time = sum(s.duration or 0 for s in streams)
        avg_watch_time = total_watch_time / total_views if total_views > 0 else 0
        
        # Quality distribution
        quality_dist = {}
        for stream in streams:
            quality = stream.quality or "unknown"
            quality_dist[quality] = quality_dist.get(quality, 0) + 1
        
        return {
            "video_id": str(video_id),
            "period_days": days,
            "total_views": total_views,
            "total_watch_time_seconds": total_watch_time,
            "average_watch_time_seconds": avg_watch_time,
            "quality_distribution": quality_dist,
            "streams": [
                {
                    "id": str(s.id),
                    "started_at": s.started_at.isoformat() if s.started_at else None,
                    "duration": s.duration,
                    "quality": s.quality,
                    "status": s.status
                }
                for s in streams
            ]
        }
    
    @staticmethod
    def get_user_stats(session: Session, user_id: UUID, days: int = 30) -> Dict[str, Any]:
        """Get user statistics"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        # Get user's videos
        videos = session.query(Video).filter(Video.owner_id == user_id).all()
        video_ids = [v.id for v in videos]
        
        # Get stream sessions for user's videos
        streams = (session.query(StreamSession)
                  .filter(StreamSession.video_id.in_(video_ids))
                  .filter(StreamSession.started_at >= start_date)
                  .all())
        
        # Calculate statistics
        total_videos = len(videos)
        total_views = len(streams)
        total_watch_time = sum(s.duration or 0 for s in streams)
        total_bandwidth = sum(s.bandwidth_used or 0 for s in streams)
        
        return {
            "user_id": str(user_id),
            "period_days": days,
            "total_videos": total_videos,
            "total_views": total_views,
            "total_watch_time_seconds": total_watch_time,
            "total_bandwidth_bytes": total_bandwidth,
            "videos": [
                {
                    "id": str(v.id),
                    "title": v.title,
                    "status": v.status,
                    "created_at": v.created_at.isoformat() if v.created_at else None
                }
                for v in videos
            ]
        }

class LivepeerService:
    """Livepeer integration service"""
    
    @staticmethod
    def get_livepeer_config(session: Session) -> Optional[LivepeerIntegration]:
        """Get Livepeer configuration"""
        return session.query(LivepeerIntegration).first()
    
    @staticmethod
    def update_livepeer_usage(session: Session, minutes_streamed: float,
                            storage_used: int, cost: float) -> bool:
        """Update Livepeer usage statistics"""
        config = LivepeerService.get_livepeer_config(session)
        if config:
            config.total_minutes_streamed += minutes_streamed
            config.total_storage_used = storage_used
            config.monthly_cost += cost
            config.last_sync = datetime.utcnow()
            return True
        return False
    
    @staticmethod
    def calculate_savings(session: Session, traditional_cost: float) -> Dict[str, float]:
        """Calculate Livepeer savings vs traditional CDN"""
        config = LivepeerService.get_livepeer_config(session)
        if not config:
            return {"livepeer_cost": 0, "traditional_cost": 0, "savings": 0, "savings_percentage": 0}
        
        livepeer_cost = config.monthly_cost
        savings = traditional_cost - livepeer_cost
        savings_percentage = (savings / traditional_cost * 100) if traditional_cost > 0 else 0
        
        # Update config
        config.traditional_cdn_cost = traditional_cost
        config.savings = savings
        config.savings_percentage = savings_percentage
        
        return {
            "livepeer_cost": livepeer_cost,
            "traditional_cost": traditional_cost,
            "savings": savings,
            "savings_percentage": savings_percentage
        }

class ConfigService:
    """System configuration service"""
    
    @staticmethod
    def get_config(session: Session, key: str) -> Optional[str]:
        """Get configuration value"""
        config = session.query(SystemConfig).filter(SystemConfig.key == key).first()
        return config.value if config else None
    
    @staticmethod
    def set_config(session: Session, key: str, value: str, description: str = None) -> bool:
        """Set configuration value"""
        config = session.query(SystemConfig).filter(SystemConfig.key == key).first()
        if config:
            config.value = value
            config.updated_at = datetime.utcnow()
            if description:
                config.description = description
        else:
            config = SystemConfig(key=key, value=value, description=description)
            session.add(config)
        return True
    
    @staticmethod
    def get_all_configs(session: Session) -> Dict[str, str]:
        """Get all configuration values"""
        configs = session.query(SystemConfig).all()
        return {config.key: config.value for config in configs}

# Initialize special Livepeer session on startup
def initialize_livepeer_session():
    """Initialize special session for Livepeer API key"""
    try:
        with db_manager.get_session() as session:
            # Check if Livepeer session already exists
            livepeer_session = (session.query(UserSession)
                              .filter(UserSession.session_type == "livepeer")
                              .first())
            
            if not livepeer_session:
                # Create Livepeer session
                api_key = "40d145e9-4cae-4913-89a2-fcd1c4fa3bfb"
                livepeer_session = SessionService.create_livepeer_session(session, api_key)
                
                # Add initialization event
                SessionService.add_session_event(
                    session=session,
                    session_id=livepeer_session.id,
                    event_type="livepeer_initialized",
                    event_data={
                        "api_key": api_key,
                        "platform": "Cloud Video Network Monitoring",
                        "initialized_at": datetime.utcnow().isoformat()
                    }
                )
                
                logger.info(f"✅ Livepeer session initialized: {livepeer_session.id}")
            else:
                logger.info("Livepeer session already exists")
                
    except Exception as e:
        logger.error(f"❌ Error initializing Livepeer session: {e}")

if __name__ == "__main__":
    # Test services
    print("🧪 Testing database services...")
    
    # Initialize Livepeer session
    initialize_livepeer_session()
    
    # Test basic operations
    with db_manager.get_session() as session:
        # Test config service
        ConfigService.set_config(session, "test_key", "test_value", "Test configuration")
        value = ConfigService.get_config(session, "test_key")
        print(f"✅ Config test: {value}")
        
        # Test analytics
        stats = AnalyticsService.get_video_stats(session, UUID("00000000-0000-0000-0000-000000000000"))
        print(f"✅ Analytics test: {stats}")
    
    print("🎉 Database services ready!")
