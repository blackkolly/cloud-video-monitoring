# 🆔 UUID Integration Service
# Handle UUID-based operations for the video streaming platform

import uuid
import json
import asyncio
from typing import Dict, Optional, List
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class UUIDManager:
    """
    Manages UUID-based operations for video streaming platform
    Handles stream IDs, session tracking, asset management, etc.
    """
    
    def __init__(self):
        self.active_sessions: Dict[str, Dict] = {}
        self.video_assets: Dict[str, Dict] = {}
        self.stream_sessions: Dict[str, Dict] = {}
        
    def validate_uuid(self, uuid_string: str) -> bool:
        """Validate if string is a valid UUID"""
        try:
            uuid.UUID(uuid_string)
            return True
        except ValueError:
            return False
    
    def generate_session_id(self) -> str:
        """Generate new session UUID"""
        return str(uuid.uuid4())
    
    def register_session(self, session_id: str = None, metadata: Dict = None) -> str:
        """Register a new streaming session"""
        if session_id is None:
            session_id = self.generate_session_id()
        
        if not self.validate_uuid(session_id):
            raise ValueError(f"Invalid UUID format: {session_id}")
        
        session_data = {
            "session_id": session_id,
            "created_at": datetime.utcnow().isoformat(),
            "status": "active",
            "metadata": metadata or {},
            "events": []
        }
        
        self.active_sessions[session_id] = session_data
        logger.info(f"✅ Session registered: {session_id}")
        
        return session_id
    
    def get_session_info(self, session_id: str) -> Optional[Dict]:
        """Get session information by UUID"""
        if not self.validate_uuid(session_id):
            return None
        
        return self.active_sessions.get(session_id)
    
    def update_session(self, session_id: str, updates: Dict) -> bool:
        """Update session data"""
        if session_id not in self.active_sessions:
            return False
        
        self.active_sessions[session_id].update(updates)
        self.active_sessions[session_id]["last_updated"] = datetime.utcnow().isoformat()
        
        return True
    
    def add_session_event(self, session_id: str, event: Dict) -> bool:
        """Add event to session timeline"""
        if session_id not in self.active_sessions:
            return False
        
        event["timestamp"] = datetime.utcnow().isoformat()
        self.active_sessions[session_id]["events"].append(event)
        
        return True
    
    def close_session(self, session_id: str) -> bool:
        """Close and archive session"""
        if session_id not in self.active_sessions:
            return False
        
        self.active_sessions[session_id]["status"] = "closed"
        self.active_sessions[session_id]["closed_at"] = datetime.utcnow().isoformat()
        
        # Move to archived sessions (in production, this would go to database)
        logger.info(f"🔒 Session closed: {session_id}")
        
        return True
    
    def register_video_asset(self, asset_id: str = None, video_data: Dict = None) -> str:
        """Register a video asset with UUID"""
        if asset_id is None:
            asset_id = self.generate_session_id()
        
        if not self.validate_uuid(asset_id):
            raise ValueError(f"Invalid UUID format: {asset_id}")
        
        asset_data = {
            "asset_id": asset_id,
            "created_at": datetime.utcnow().isoformat(),
            "status": "processing",
            "video_data": video_data or {},
            "access_count": 0,
            "last_accessed": None
        }
        
        self.video_assets[asset_id] = asset_data
        logger.info(f"📹 Video asset registered: {asset_id}")
        
        return asset_id
    
    def get_video_asset(self, asset_id: str) -> Optional[Dict]:
        """Get video asset by UUID"""
        if not self.validate_uuid(asset_id):
            return None
        
        asset = self.video_assets.get(asset_id)
        if asset:
            # Update access tracking
            asset["access_count"] += 1
            asset["last_accessed"] = datetime.utcnow().isoformat()
        
        return asset
    
    def create_stream_session(self, video_id: str, viewer_info: Dict = None) -> str:
        """Create streaming session for a video"""
        stream_id = self.generate_session_id()
        
        stream_data = {
            "stream_id": stream_id,
            "video_id": video_id,
            "viewer_info": viewer_info or {},
            "started_at": datetime.utcnow().isoformat(),
            "status": "streaming",
            "quality": "auto",
            "bandwidth_usage": 0,
            "buffer_events": []
        }
        
        self.stream_sessions[stream_id] = stream_data
        logger.info(f"🎥 Stream session created: {stream_id} for video: {video_id}")
        
        return stream_id
    
    def update_stream_quality(self, stream_id: str, quality: str) -> bool:
        """Update stream quality"""
        if stream_id not in self.stream_sessions:
            return False
        
        self.stream_sessions[stream_id]["quality"] = quality
        self.add_stream_event(stream_id, {
            "type": "quality_change",
            "quality": quality
        })
        
        return True
    
    def add_stream_event(self, stream_id: str, event: Dict) -> bool:
        """Add event to stream session"""
        if stream_id not in self.stream_sessions:
            return False
        
        event["timestamp"] = datetime.utcnow().isoformat()
        
        if "events" not in self.stream_sessions[stream_id]:
            self.stream_sessions[stream_id]["events"] = []
        
        self.stream_sessions[stream_id]["events"].append(event)
        return True
    
    def get_active_streams(self) -> List[Dict]:
        """Get all active streaming sessions"""
        active_streams = []
        
        for stream_id, stream_data in self.stream_sessions.items():
            if stream_data["status"] == "streaming":
                active_streams.append(stream_data)
        
        return active_streams
    
    def get_session_analytics(self, session_id: str) -> Dict:
        """Get analytics for a specific session"""
        session = self.get_session_info(session_id)
        if not session:
            return {}
        
        stream = self.stream_sessions.get(session_id)
        if not stream:
            return {}
        
        analytics = {
            "session_id": session_id,
            "duration_seconds": self._calculate_duration(stream["started_at"]),
            "quality_changes": len([e for e in stream.get("events", []) if e["type"] == "quality_change"]),
            "buffer_events": len(stream.get("buffer_events", [])),
            "current_quality": stream.get("quality", "unknown"),
            "bandwidth_used_mb": stream.get("bandwidth_usage", 0) / (1024 * 1024)
        }
        
        return analytics
    
    def _calculate_duration(self, start_time: str) -> float:
        """Calculate duration from start time"""
        try:
            start = datetime.fromisoformat(start_time.replace('Z', '+00:00'))
            now = datetime.utcnow()
            duration = (now - start.replace(tzinfo=None)).total_seconds()
            return duration
        except:
            return 0.0
    
    def cleanup_old_sessions(self, max_age_hours: int = 24) -> int:
        """Cleanup old inactive sessions"""
        cleaned_count = 0
        current_time = datetime.utcnow()
        
        # Cleanup old active sessions
        sessions_to_remove = []
        for session_id, session_data in self.active_sessions.items():
            try:
                created = datetime.fromisoformat(session_data["created_at"])
                age_hours = (current_time - created).total_seconds() / 3600
                
                if age_hours > max_age_hours and session_data["status"] != "active":
                    sessions_to_remove.append(session_id)
            except:
                sessions_to_remove.append(session_id)  # Remove invalid sessions
        
        for session_id in sessions_to_remove:
            del self.active_sessions[session_id]
            cleaned_count += 1
        
        # Cleanup old stream sessions
        streams_to_remove = []
        for stream_id, stream_data in self.stream_sessions.items():
            try:
                started = datetime.fromisoformat(stream_data["started_at"])
                age_hours = (current_time - started).total_seconds() / 3600
                
                if age_hours > max_age_hours and stream_data["status"] != "streaming":
                    streams_to_remove.append(stream_id)
            except:
                streams_to_remove.append(stream_id)
        
        for stream_id in streams_to_remove:
            del self.stream_sessions[stream_id]
            cleaned_count += 1
        
        if cleaned_count > 0:
            logger.info(f"🧹 Cleaned up {cleaned_count} old sessions")
        
        return cleaned_count

# Global UUID manager instance
uuid_manager = UUIDManager()

# Initialize with the provided UUID
PROVIDED_UUID = "40d145e9-4cae-4913-89a2-fcd1c4fa3bfb"

async def initialize_with_provided_uuid():
    """Initialize system with the provided UUID"""
    
    # Register the provided UUID as a special session
    session_data = uuid_manager.register_session(
        session_id=PROVIDED_UUID,
        metadata={
            "type": "system_session",
            "source": "user_provided",
            "special": True,
            "description": "User-provided UUID for platform initialization"
        }
    )
    
    # Add initial event
    uuid_manager.add_session_event(PROVIDED_UUID, {
        "type": "system_init",
        "message": "Platform initialized with user-provided UUID",
        "platform": "Cloud Video Network Monitoring"
    })
    
    logger.info(f"🎯 System initialized with UUID: {PROVIDED_UUID}")
    
    return {
        "status": "initialized",
        "session_id": PROVIDED_UUID,
        "message": "Platform ready with user UUID",
        "timestamp": datetime.utcnow().isoformat()
    }

# Usage examples for the video platform
class VideoSessionManager:
    """Integrate UUID management with video streaming"""
    
    def __init__(self):
        self.uuid_manager = uuid_manager
    
    async def start_video_session(self, video_id: str, user_id: str = None) -> str:
        """Start a new video streaming session"""
        
        # Create stream session
        stream_id = self.uuid_manager.create_stream_session(
            video_id=video_id,
            viewer_info={"user_id": user_id} if user_id else {}
        )
        
        # Register as general session
        self.uuid_manager.register_session(
            session_id=stream_id,
            metadata={
                "type": "video_stream",
                "video_id": video_id,
                "user_id": user_id
            }
        )
        
        return stream_id
    
    async def track_video_event(self, stream_id: str, event_type: str, data: Dict = None):
        """Track video streaming events"""
        
        event = {
            "type": event_type,
            "data": data or {}
        }
        
        # Add to both session and stream tracking
        self.uuid_manager.add_session_event(stream_id, event)
        self.uuid_manager.add_stream_event(stream_id, event)
    
    async def get_session_stats(self, stream_id: str) -> Dict:
        """Get comprehensive session statistics"""
        
        session_info = self.uuid_manager.get_session_info(stream_id)
        analytics = self.uuid_manager.get_session_analytics(stream_id)
        
        return {
            "session": session_info,
            "analytics": analytics,
            "active": stream_id in self.uuid_manager.stream_sessions
        }

if __name__ == "__main__":
    # Test the UUID system
    async def test_uuid_system():
        result = await initialize_with_provided_uuid()
        print(f"✅ UUID System initialized: {result}")
        
        # Test video session
        video_session = VideoSessionManager()
        stream_id = await video_session.start_video_session("test_video_123", "user_456")
        print(f"🎥 Video session started: {stream_id}")
        
        # Track some events
        await video_session.track_video_event(stream_id, "play_start")
        await video_session.track_video_event(stream_id, "quality_change", {"quality": "720p"})
        
        # Get stats
        stats = await video_session.get_session_stats(stream_id)
        print(f"📊 Session stats: {stats}")
    
    asyncio.run(test_uuid_system())
