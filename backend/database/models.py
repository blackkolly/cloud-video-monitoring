# 🗄️ Database Models for Cloud Video Network Monitoring
# SQLAlchemy models for storing video streaming data

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text, ForeignKey, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

Base = declarative_base()

class User(Base):
    """User account model"""
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime)
    is_active = Column(Boolean, default=True)
    subscription_tier = Column(String(20), default="free")  # free, pro, enterprise
    
    # Relationships
    videos = relationship("Video", back_populates="owner")
    sessions = relationship("Session", back_populates="user")
    analytics = relationship("UserAnalytics", back_populates="user")

class Video(Base):
    """Video asset model"""
    __tablename__ = "videos"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    filename = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_size = Column(Integer)  # bytes
    duration = Column(Float)  # seconds
    format = Column(String(20))  # mp4, webm, etc.
    resolution = Column(String(20))  # 1080p, 720p, etc.
    bitrate = Column(Integer)  # kbps
    
    # Status and processing
    status = Column(String(20), default="processing")  # processing, ready, failed, deleted
    upload_progress = Column(Float, default=0.0)  # 0-100
    processing_progress = Column(Float, default=0.0)  # 0-100
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    published_at = Column(DateTime)
    
    # Livepeer integration
    livepeer_asset_id = Column(String(100))
    livepeer_playback_id = Column(String(100))
    use_livepeer = Column(Boolean, default=False)
    
    # Metadata
    thumbnail_path = Column(String(500))
    video_metadata = Column(JSON)  # Additional video metadata
    
    # Foreign keys
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Relationships
    owner = relationship("User", back_populates="videos")
    streams = relationship("StreamSession", back_populates="video")
    analytics = relationship("VideoAnalytics", back_populates="video")

class Session(Base):
    """User session model"""
    __tablename__ = "sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_token = Column(String(255), unique=True, nullable=False)
    user_agent = Column(Text)
    ip_address = Column(String(45))  # IPv4 or IPv6
    location = Column(JSON)  # Country, city, etc.
    
    # Session data
    created_at = Column(DateTime, default=datetime.utcnow)
    last_activity = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime)
    is_active = Column(Boolean, default=True)
    
    # Special sessions (like Livepeer API key session)
    session_type = Column(String(50), default="user")  # user, system, api, livepeer
    is_special = Column(Boolean, default=False)
    
    # Foreign keys
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Relationships
    user = relationship("User", back_populates="sessions")
    events = relationship("SessionEvent", back_populates="session")
    stream_sessions = relationship("StreamSession", back_populates="session")

class StreamSession(Base):
    """Video streaming session model"""
    __tablename__ = "stream_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Session info
    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime)
    duration = Column(Float)  # seconds
    status = Column(String(20), default="active")  # active, paused, ended, error
    
    # Playback data
    current_time = Column(Float, default=0.0)  # Current playback position
    quality = Column(String(20), default="auto")  # 1080p, 720p, 480p, auto
    volume = Column(Float, default=1.0)  # 0.0 - 1.0
    playback_rate = Column(Float, default=1.0)  # 0.5, 1.0, 1.25, 1.5, 2.0
    
    # Performance metrics
    buffer_duration = Column(Float, default=0.0)  # Total buffer time
    dropped_frames = Column(Integer, default=0)
    network_state = Column(Integer, default=0)  # HTML5 video networkState
    ready_state = Column(Integer, default=0)  # HTML5 video readyState
    
    # Bandwidth and CDN
    bandwidth_used = Column(Integer, default=0)  # bytes
    cdn_used = Column(String(50), default="direct")  # direct, livepeer, cloudflare
    cdn_cost = Column(Float, default=0.0)  # Cost in USD
    
    # Device and browser info
    device_type = Column(String(50))  # desktop, mobile, tablet
    browser = Column(String(100))
    os = Column(String(100))
    screen_resolution = Column(String(20))
    
    # Foreign keys
    video_id = Column(UUID(as_uuid=True), ForeignKey("videos.id"), nullable=False)
    session_id = Column(UUID(as_uuid=True), ForeignKey("sessions.id"))
    
    # Relationships
    video = relationship("Video", back_populates="streams")
    session = relationship("Session", back_populates="stream_sessions")
    events = relationship("StreamEvent", back_populates="stream_session")

class SessionEvent(Base):
    """Session events model"""
    __tablename__ = "session_events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_type = Column(String(100), nullable=False)  # login, logout, page_view, etc.
    event_data = Column(JSON)  # Additional event data
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Foreign keys
    session_id = Column(UUID(as_uuid=True), ForeignKey("sessions.id"), nullable=False)
    
    # Relationships
    session = relationship("Session", back_populates="events")

class StreamEvent(Base):
    """Video streaming events model"""
    __tablename__ = "stream_events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_type = Column(String(100), nullable=False)  # play, pause, seek, quality_change, etc.
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Event data
    playback_time = Column(Float)  # Video time when event occurred
    event_data = Column(JSON)  # Additional event-specific data
    
    # Performance data
    buffer_length = Column(Float)  # Buffer length at event time
    bandwidth = Column(Integer)  # Bandwidth at event time (kbps)
    latency = Column(Float)  # Network latency (ms)
    
    # Foreign keys
    stream_session_id = Column(UUID(as_uuid=True), ForeignKey("stream_sessions.id"), nullable=False)
    
    # Relationships
    stream_session = relationship("StreamSession", back_populates="events")

class VideoAnalytics(Base):
    """Video analytics and statistics"""
    __tablename__ = "video_analytics"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    date = Column(DateTime, default=datetime.utcnow)
    
    # View statistics
    total_views = Column(Integer, default=0)
    unique_views = Column(Integer, default=0)
    total_watch_time = Column(Float, default=0.0)  # seconds
    average_watch_time = Column(Float, default=0.0)  # seconds
    completion_rate = Column(Float, default=0.0)  # 0-1
    
    # Quality statistics
    avg_quality = Column(String(20))
    quality_distribution = Column(JSON)  # {1080p: 50%, 720p: 30%, 480p: 20%}
    
    # Performance statistics
    avg_buffer_time = Column(Float, default=0.0)
    error_rate = Column(Float, default=0.0)
    dropped_frame_rate = Column(Float, default=0.0)
    
    # Bandwidth and cost
    bandwidth_used = Column(Integer, default=0)  # bytes
    cdn_cost = Column(Float, default=0.0)  # USD
    livepeer_savings = Column(Float, default=0.0)  # USD saved vs traditional CDN
    
    # Geographic data
    geographic_data = Column(JSON)  # Views by country/region
    device_data = Column(JSON)  # Views by device type
    
    # Foreign keys
    video_id = Column(UUID(as_uuid=True), ForeignKey("videos.id"), nullable=False)
    
    # Relationships
    video = relationship("Video", back_populates="analytics")

class UserAnalytics(Base):
    """User analytics and statistics"""
    __tablename__ = "user_analytics"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    date = Column(DateTime, default=datetime.utcnow)
    
    # Usage statistics
    total_sessions = Column(Integer, default=0)
    total_watch_time = Column(Float, default=0.0)  # seconds
    videos_watched = Column(Integer, default=0)
    videos_uploaded = Column(Integer, default=0)
    
    # Bandwidth usage
    bandwidth_used = Column(Integer, default=0)  # bytes
    storage_used = Column(Integer, default=0)  # bytes
    
    # Cost tracking
    monthly_cost = Column(Float, default=0.0)  # USD
    livepeer_savings = Column(Float, default=0.0)  # USD saved
    
    # Foreign keys
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="analytics")

class LivepeerIntegration(Base):
    """Livepeer integration tracking"""
    __tablename__ = "livepeer_integration"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    api_key = Column(String(255), nullable=False)  # Your Livepeer API key
    
    # Usage tracking
    total_assets = Column(Integer, default=0)
    total_streams = Column(Integer, default=0)
    total_minutes_streamed = Column(Float, default=0.0)
    total_storage_used = Column(Integer, default=0)  # bytes
    
    # Cost tracking
    monthly_cost = Column(Float, default=0.0)  # USD
    traditional_cdn_cost = Column(Float, default=0.0)  # What it would cost with traditional CDN
    savings = Column(Float, default=0.0)  # USD saved
    savings_percentage = Column(Float, default=0.0)  # % saved
    
    # Performance tracking
    avg_startup_time = Column(Float, default=0.0)  # ms
    avg_rebuffer_rate = Column(Float, default=0.0)  # %
    quality_of_experience = Column(Float, default=0.0)  # 1-10 scale
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_sync = Column(DateTime)

class SystemConfig(Base):
    """System configuration"""
    __tablename__ = "system_config"
    
    id = Column(Integer, primary_key=True)
    key = Column(String(100), unique=True, nullable=False)
    value = Column(Text)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Indexes for better performance
from sqlalchemy import Index

# User indexes
Index('idx_users_email', User.email)
Index('idx_users_username', User.username)

# Video indexes
Index('idx_videos_owner', Video.owner_id)
Index('idx_videos_status', Video.status)
Index('idx_videos_created', Video.created_at)

# Session indexes
Index('idx_sessions_user', Session.user_id)
Index('idx_sessions_token', Session.session_token)
Index('idx_sessions_active', Session.is_active)

# Stream session indexes
Index('idx_stream_sessions_video', StreamSession.video_id)
Index('idx_stream_sessions_session', StreamSession.session_id)
Index('idx_stream_sessions_started', StreamSession.started_at)

# Event indexes
Index('idx_session_events_session', SessionEvent.session_id)
Index('idx_session_events_type', SessionEvent.event_type)
Index('idx_stream_events_stream', StreamEvent.stream_session_id)
Index('idx_stream_events_type', StreamEvent.event_type)
