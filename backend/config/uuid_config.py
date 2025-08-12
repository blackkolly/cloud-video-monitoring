# 🆔 UUID Configuration
# Configuration file for UUID: 40d145e9-4cae-4913-89a2-fcd1c4fa3bfb

import json
from datetime import datetime
from typing import Dict, Any

# UUID Configuration
UUID_CONFIG = {
    "provided_uuid": "40d145e9-4cae-4913-89a2-fcd1c4fa3bfb",
    "system_name": "Cloud Video Network Monitoring",
    "integration_date": "2025-08-11",
    "version": "1.0.0",
    
    # Session Configuration
    "session_config": {
        "auto_initialize": True,
        "special_session": True,
        "priority_tracking": True,
        "extended_analytics": True,
        "real_time_updates": True
    },
    
    # Video Streaming Configuration
    "video_config": {
        "track_quality_changes": True,
        "track_buffer_events": True,
        "track_network_state": True,
        "performance_monitoring": True,
        "adaptive_streaming": True
    },
    
    # Analytics Configuration
    "analytics_config": {
        "update_interval_seconds": 5,
        "retention_hours": 168,  # 7 days
        "export_format": "json",
        "include_metadata": True,
        "real_time_dashboard": True
    },
    
    # Storage Configuration
    "storage_config": {
        "local_storage": True,
        "backend_sync": True,
        "auto_cleanup": True,
        "cleanup_interval_hours": 24,
        "max_events_per_session": 10000
    },
    
    # API Configuration
    "api_config": {
        "base_url": "/api",
        "session_endpoint": "/sessions",
        "analytics_endpoint": "/analytics",
        "video_endpoint": "/video",
        "timeout_seconds": 30
    },
    
    # Dashboard Configuration
    "dashboard_config": {
        "show_uuid_card": True,
        "show_full_uuid": True,
        "update_frequency": 5000,  # milliseconds
        "highlight_special": True,
        "color_scheme": {
            "primary": "#0d6efd",
            "success": "#198754",
            "info": "#0dcaf0",
            "warning": "#ffc107",
            "special": "#6f42c1"
        }
    },
    
    # Event Configuration
    "event_config": {
        "video_events": [
            "play", "pause", "ended", "seeking", "seeked",
            "loadstart", "loadeddata", "canplay", "playing",
            "waiting", "stalled", "error", "quality_change"
        ],
        "system_events": [
            "session_created", "session_closed", "page_load",
            "page_unload", "error", "warning", "info"
        ],
        "custom_events": [
            "user_interaction", "api_call", "data_export",
            "settings_change", "feature_usage"
        ]
    },
    
    # Performance Thresholds
    "performance_thresholds": {
        "max_buffer_time_ms": 5000,
        "max_seek_time_ms": 2000,
        "min_playback_quality": 480,
        "max_dropped_frames_percent": 5,
        "network_timeout_ms": 30000
    },
    
    # Logging Configuration
    "logging_config": {
        "level": "INFO",
        "console_output": True,
        "file_output": False,
        "include_timestamps": True,
        "include_session_id": True,
        "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    }
}

class UUIDConfig:
    """Configuration manager for UUID integration"""
    
    def __init__(self):
        self.config = UUID_CONFIG.copy()
        self.load_time = datetime.utcnow()
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value"""
        keys = key.split('.')
        value = self.config
        
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        
        return value
    
    def set(self, key: str, value: Any) -> bool:
        """Set configuration value"""
        keys = key.split('.')
        config = self.config
        
        # Navigate to parent
        for k in keys[:-1]:
            if k not in config:
                config[k] = {}
            config = config[k]
        
        # Set value
        config[keys[-1]] = value
        return True
    
    def get_provided_uuid(self) -> str:
        """Get the provided UUID"""
        return self.config["provided_uuid"]
    
    def is_special_session(self) -> bool:
        """Check if this is configured as a special session"""
        return self.get("session_config.special_session", False)
    
    def get_update_interval(self) -> int:
        """Get analytics update interval in seconds"""
        return self.get("analytics_config.update_interval_seconds", 5)
    
    def get_dashboard_config(self) -> Dict:
        """Get dashboard configuration"""
        return self.get("dashboard_config", {})
    
    def get_video_events(self) -> list:
        """Get list of video events to track"""
        return self.get("event_config.video_events", [])
    
    def get_performance_thresholds(self) -> Dict:
        """Get performance monitoring thresholds"""
        return self.get("performance_thresholds", {})
    
    def export_config(self) -> str:
        """Export configuration as JSON"""
        export_data = {
            "config": self.config,
            "load_time": self.load_time.isoformat(),
            "export_time": datetime.utcnow().isoformat()
        }
        return json.dumps(export_data, indent=2)
    
    def validate_config(self) -> Dict[str, Any]:
        """Validate configuration settings"""
        issues = []
        warnings = []
        
        # Validate UUID format
        import re
        uuid_pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        if not re.match(uuid_pattern, self.get_provided_uuid(), re.IGNORECASE):
            issues.append("Invalid UUID format")
        
        # Validate intervals
        update_interval = self.get_update_interval()
        if update_interval < 1 or update_interval > 60:
            warnings.append("Update interval should be between 1-60 seconds")
        
        # Validate retention
        retention = self.get("analytics_config.retention_hours", 168)
        if retention < 1:
            issues.append("Retention hours must be positive")
        
        return {
            "valid": len(issues) == 0,
            "issues": issues,
            "warnings": warnings,
            "config_loaded": self.load_time.isoformat()
        }

# Global configuration instance
uuid_config = UUIDConfig()

# Export configuration for JavaScript
def generate_js_config() -> str:
    """Generate JavaScript configuration object"""
    js_config = {
        "providedUUID": uuid_config.get_provided_uuid(),
        "updateInterval": uuid_config.get_update_interval() * 1000,  # Convert to ms
        "dashboardConfig": uuid_config.get_dashboard_config(),
        "videoEvents": uuid_config.get_video_events(),
        "isSpecialSession": uuid_config.is_special_session(),
        "apiConfig": uuid_config.get("api_config", {}),
        "performanceThresholds": uuid_config.get_performance_thresholds()
    }
    
    return f"window.UUID_CONFIG = {json.dumps(js_config, indent=2)};"

# Configuration validation
if __name__ == "__main__":
    validation = uuid_config.validate_config()
    print("UUID Configuration Validation:")
    print(f"Valid: {validation['valid']}")
    
    if validation['issues']:
        print("Issues:")
        for issue in validation['issues']:
            print(f"  ❌ {issue}")
    
    if validation['warnings']:
        print("Warnings:")
        for warning in validation['warnings']:
            print(f"  ⚠️ {warning}")
    
    if validation['valid']:
        print(f"✅ Configuration loaded successfully for UUID: {uuid_config.get_provided_uuid()}")
        print(f"📊 Update interval: {uuid_config.get_update_interval()}s")
        print(f"🎯 Special session: {uuid_config.is_special_session()}")
        print(f"📱 Dashboard updates: {uuid_config.get('dashboard_config.update_frequency')}ms")
