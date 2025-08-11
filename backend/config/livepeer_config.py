# 🔑 Livepeer API Key Configuration
# API Key: 40d145e9-4cae-4913-89a2-fcd1c4fa3bfb

import os
import json
from typing import Dict, Any
from datetime import datetime

class LivepeerConfig:
    """Configuration manager for Livepeer API integration"""
    
    def __init__(self):
        self.api_key = "40d145e9-4cae-4913-89a2-fcd1c4fa3bfb"
        self.config = self._initialize_config()
    
    def _initialize_config(self) -> Dict[str, Any]:
        """Initialize Livepeer configuration with provided API key"""
        return {
            # API Configuration
            "api_key": self.api_key,
            "gateway_url": "https://livepeer.studio/api",
            "playback_url": "https://lp-playback.studio",
            "webhook_url": "https://your-domain.com/webhook/livepeer",
            
            # Authentication
            "headers": {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            },
            
            # Transcoding Profiles
            "transcoding_profiles": {
                "low": {
                    "name": "Low Quality",
                    "bitrate": 500000,  # 500 kbps
                    "fps": 30,
                    "width": 640,
                    "height": 360,
                    "profile": "H264ConstrainedHigh"
                },
                "medium": {
                    "name": "Medium Quality", 
                    "bitrate": 1500000,  # 1.5 Mbps
                    "fps": 30,
                    "width": 1280,
                    "height": 720,
                    "profile": "H264ConstrainedHigh"
                },
                "high": {
                    "name": "High Quality",
                    "bitrate": 4000000,  # 4 Mbps
                    "fps": 60,
                    "width": 1920,
                    "height": 1080,
                    "profile": "H264ConstrainedHigh"
                },
                "4k": {
                    "name": "4K Quality",
                    "bitrate": 8000000,  # 8 Mbps
                    "fps": 60,
                    "width": 3840,
                    "height": 2160,
                    "profile": "H264ConstrainedHigh"
                }
            },
            
            # Cost Configuration
            "cost_optimization": {
                "enabled": True,
                "cost_threshold_per_gb": 0.05,  # $0.05 per GB
                "fallback_enabled": True,
                "auto_failover": True,
                "cost_tracking": True
            },
            
            # Streaming Configuration
            "streaming": {
                "hls_enabled": True,
                "dash_enabled": True,
                "rtmp_enabled": True,
                "webrtc_enabled": True,
                "record_sessions": True,
                "thumbnail_generation": True
            },
            
            # Performance Settings
            "performance": {
                "max_concurrent_streams": 100,
                "timeout_seconds": 30,
                "retry_attempts": 3,
                "buffer_size_mb": 10,
                "chunk_duration_seconds": 4
            },
            
            # Analytics & Monitoring
            "analytics": {
                "track_viewers": True,
                "track_quality_metrics": True,
                "track_costs": True,
                "export_metrics": True,
                "real_time_monitoring": True
            },
            
            # Security Settings
            "security": {
                "signed_urls": True,
                "access_control": True,
                "geo_restrictions": [],
                "ip_whitelist": [],
                "token_expiry_hours": 24
            }
        }
    
    def get_api_key(self) -> str:
        """Get Livepeer API key"""
        return self.api_key
    
    def get_headers(self) -> Dict[str, str]:
        """Get API headers with authentication"""
        return self.config["headers"]
    
    def get_gateway_url(self) -> str:
        """Get Livepeer gateway URL"""
        return self.config["gateway_url"]
    
    def get_playback_url(self) -> str:
        """Get Livepeer playback URL"""
        return self.config["playback_url"]
    
    def get_transcoding_profiles(self) -> Dict[str, Dict]:
        """Get transcoding quality profiles"""
        return self.config["transcoding_profiles"]
    
    def get_profile(self, quality: str) -> Dict:
        """Get specific transcoding profile"""
        return self.config["transcoding_profiles"].get(quality, 
                   self.config["transcoding_profiles"]["medium"])
    
    def is_cost_optimization_enabled(self) -> bool:
        """Check if cost optimization is enabled"""
        return self.config["cost_optimization"]["enabled"]
    
    def get_cost_threshold(self) -> float:
        """Get cost threshold per GB"""
        return self.config["cost_optimization"]["cost_threshold_per_gb"]
    
    def export_env_file(self) -> str:
        """Export configuration as .env file"""
        env_content = f"""# Livepeer API Configuration
LIVEPEER_API_KEY={self.api_key}
LIVEPEER_GATEWAY_URL={self.get_gateway_url()}
LIVEPEER_PLAYBACK_URL={self.get_playback_url()}
LIVEPEER_WEBHOOK_URL={self.config["webhook_url"]}

# Cost Optimization
LIVEPEER_COST_OPTIMIZATION=true
LIVEPEER_COST_THRESHOLD={self.get_cost_threshold()}
LIVEPEER_FALLBACK_ENABLED=true

# Performance Settings
LIVEPEER_MAX_CONCURRENT_STREAMS={self.config["performance"]["max_concurrent_streams"]}
LIVEPEER_TIMEOUT_SECONDS={self.config["performance"]["timeout_seconds"]}
LIVEPEER_RETRY_ATTEMPTS={self.config["performance"]["retry_attempts"]}

# Features
LIVEPEER_HLS_ENABLED=true
LIVEPEER_DASH_ENABLED=true
LIVEPEER_RTMP_ENABLED=true
LIVEPEER_WEBRTC_ENABLED=true
LIVEPEER_RECORDING_ENABLED=true
LIVEPEER_THUMBNAILS_ENABLED=true

# Analytics
LIVEPEER_ANALYTICS_ENABLED=true
LIVEPEER_COST_TRACKING=true
LIVEPEER_REAL_TIME_MONITORING=true

# Security
LIVEPEER_SIGNED_URLS=true
LIVEPEER_ACCESS_CONTROL=true
LIVEPEER_TOKEN_EXPIRY_HOURS=24
"""
        return env_content
    
    def validate_api_key(self) -> Dict[str, Any]:
        """Validate API key format and structure"""
        import re
        
        # Check UUID format (Livepeer uses UUID-like API keys)
        uuid_pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        is_valid_format = bool(re.match(uuid_pattern, self.api_key, re.IGNORECASE))
        
        validation = {
            "api_key": self.api_key,
            "is_valid_format": is_valid_format,
            "length": len(self.api_key),
            "expected_length": 36,
            "contains_hyphens": self.api_key.count('-') == 4,
            "timestamp": datetime.utcnow().isoformat(),
            "status": "valid" if is_valid_format else "invalid_format"
        }
        
        return validation
    
    def generate_curl_examples(self) -> Dict[str, str]:
        """Generate curl command examples for testing"""
        base_url = self.get_gateway_url()
        headers = self.get_headers()
        
        examples = {
            "list_streams": f"""curl -X GET "{base_url}/stream" \\
  -H "Authorization: {headers['Authorization']}" \\
  -H "Content-Type: application/json" """,
            
            "create_stream": f"""curl -X POST "{base_url}/stream" \\
  -H "Authorization: {headers['Authorization']}" \\
  -H "Content-Type: application/json" \\
  -d '{{
    "name": "My Test Stream",
    "profiles": [
      {{
        "name": "720p",
        "bitrate": 1500000,
        "fps": 30,
        "width": 1280,
        "height": 720,
        "profile": "H264ConstrainedHigh"
      }}
    ]
  }}'""",
            
            "get_stream": f"""curl -X GET "{base_url}/stream/{{STREAM_ID}}" \\
  -H "Authorization: {headers['Authorization']}" \\
  -H "Content-Type: application/json" """,
            
            "start_stream": f"""curl -X PATCH "{base_url}/stream/{{STREAM_ID}}/start" \\
  -H "Authorization: {headers['Authorization']}" \\
  -H "Content-Type: application/json" """,
            
            "stop_stream": f"""curl -X PATCH "{base_url}/stream/{{STREAM_ID}}/stop" \\
  -H "Authorization: {headers['Authorization']}" \\
  -H "Content-Type: application/json" """,
            
            "delete_stream": f"""curl -X DELETE "{base_url}/stream/{{STREAM_ID}}" \\
  -H "Authorization: {headers['Authorization']}" \\
  -H "Content-Type: application/json" """
        }
        
        return examples

# Global configuration instance
livepeer_config = LivepeerConfig()

# Generate configuration files
def create_livepeer_config_file():
    """Create Livepeer configuration JSON file"""
    config_data = {
        "api_key": livepeer_config.get_api_key(),
        "gateway_url": livepeer_config.get_gateway_url(),
        "playback_url": livepeer_config.get_playback_url(),
        "transcoding_profiles": livepeer_config.get_transcoding_profiles(),
        "cost_optimization": livepeer_config.config["cost_optimization"],
        "streaming": livepeer_config.config["streaming"],
        "performance": livepeer_config.config["performance"],
        "analytics": livepeer_config.config["analytics"],
        "security": livepeer_config.config["security"],
        "created_at": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }
    
    return json.dumps(config_data, indent=2)

if __name__ == "__main__":
    # Validate API key
    validation = livepeer_config.validate_api_key()
    print("🔑 Livepeer API Key Validation:")
    print(f"API Key: {validation['api_key']}")
    print(f"Valid Format: {'✅' if validation['is_valid_format'] else '❌'}")
    print(f"Length: {validation['length']}/{validation['expected_length']}")
    print(f"Status: {validation['status']}")
    
    if validation['is_valid_format']:
        print("\n🚀 API Key is valid for Livepeer integration!")
        print(f"Gateway URL: {livepeer_config.get_gateway_url()}")
        print(f"Cost Optimization: {'Enabled' if livepeer_config.is_cost_optimization_enabled() else 'Disabled'}")
        print(f"Cost Threshold: ${livepeer_config.get_cost_threshold()}/GB")
    else:
        print("\n❌ Invalid API key format. Expected UUID format.")
    
    print(f"\n📋 Configuration loaded at: {validation['timestamp']}")
