# 🔧 Backend Services Initialization
# Main service initialization and configuration

import asyncio
import logging
from typing import Dict, Any, Optional
from pathlib import Path
import yaml
import json

from .streaming.video_streamer import SimpleVideoStreamer
from .monitoring.network_monitor import NetworkMonitor
from .services.cdn_manager import CDNManager

logger = logging.getLogger(__name__)

class ServiceManager:
    """Manages all backend services for the video streaming platform"""
    
    def __init__(self, config_path: str = "config/services.yml"):
        self.config_path = config_path
        self.config = self._load_config()
        
        # Service instances
        self.video_streamer: Optional[SimpleVideoStreamer] = None
        self.network_monitor: Optional[NetworkMonitor] = None
        self.cdn_manager: Optional[CDNManager] = None
        
        self.services_status = {
            "video_streaming": False,
            "network_monitoring": False,
            "cdn_management": False
        }
    
    def _load_config(self) -> Dict[str, Any]:
        """Load service configuration"""
        default_config = {
            "video_streaming": {
                "enabled": True,
                "port": 8006,
                "video_storage_path": "./videos",
                "hls_storage_path": "./hls",
                "max_concurrent_streams": 1000
            },
            "network_monitoring": {
                "enabled": True,
                "interval_seconds": 30,
                "prometheus_port": 9090,
                "targets": ["8.8.8.8", "1.1.1.1"]
            },
            "cdn_management": {
                "enabled": True,
                "providers": ["cloudflare", "aws", "azure"],
                "failover_enabled": True,
                "health_check_interval": 60
            },
            "security": {
                "enabled": True,
                "threat_detection": True,
                "compliance_monitoring": True
            }
        }
        
        try:
            if Path(self.config_path).exists():
                with open(self.config_path, 'r') as f:
                    if self.config_path.endswith('.yml') or self.config_path.endswith('.yaml'):
                        config = yaml.safe_load(f)
                    else:
                        config = json.load(f)
                
                # Merge with defaults
                for key, value in config.items():
                    if key in default_config:
                        default_config[key].update(value)
                    else:
                        default_config[key] = value
            
            return default_config
        
        except Exception as e:
            logger.error(f"Config loading failed: {e}, using defaults")
            return default_config
    
    async def start_all_services(self):
        """Start all configured services"""
        logger.info("🚀 Starting all backend services...")
        
        try:
            # Start video streaming service
            if self.config["video_streaming"]["enabled"]:
                await self._start_video_streaming()
            
            # Start network monitoring
            if self.config["network_monitoring"]["enabled"]:
                await self._start_network_monitoring()
            
            # Start CDN management
            if self.config["cdn_management"]["enabled"]:
                await self._start_cdn_management()
            
            logger.info("✅ All services started successfully")
            
        except Exception as e:
            logger.error(f"❌ Service startup failed: {e}")
            raise
    
    async def _start_video_streaming(self):
        """Start video streaming service"""
        try:
            self.video_streamer = SimpleVideoStreamer(
                config_path="config/streaming-config.json"
            )
            
            # Start in background
            asyncio.create_task(
                self.video_streamer.start_server(
                    port=self.config["video_streaming"]["port"]
                )
            )
            
            self.services_status["video_streaming"] = True
            logger.info("✅ Video streaming service started")
            
        except Exception as e:
            logger.error(f"❌ Video streaming startup failed: {e}")
            raise
    
    async def _start_network_monitoring(self):
        """Start network monitoring service"""
        try:
            self.network_monitor = NetworkMonitor()
            
            # Start monitoring in background
            asyncio.create_task(self.network_monitor.start_monitoring())
            
            self.services_status["network_monitoring"] = True
            logger.info("✅ Network monitoring service started")
            
        except Exception as e:
            logger.error(f"❌ Network monitoring startup failed: {e}")
            # Non-critical service, continue
            logger.warning("Continuing without network monitoring")
    
    async def _start_cdn_management(self):
        """Start CDN management service"""
        try:
            self.cdn_manager = CDNManager()
            await self.cdn_manager.initialize()
            
            # Start health checks in background
            asyncio.create_task(self.cdn_manager.start_health_monitoring())
            
            self.services_status["cdn_management"] = True
            logger.info("✅ CDN management service started")
            
        except Exception as e:
            logger.error(f"❌ CDN management startup failed: {e}")
            # Non-critical service, continue
            logger.warning("Continuing without CDN management")
    
    async def stop_all_services(self):
        """Stop all services gracefully"""
        logger.info("🔄 Stopping all backend services...")
        
        try:
            if self.network_monitor:
                await self.network_monitor.stop_monitoring()
                logger.info("✅ Network monitoring stopped")
            
            if self.cdn_manager:
                await self.cdn_manager.cleanup()
                logger.info("✅ CDN management stopped")
            
            # Video streamer will stop when main process ends
            
            logger.info("✅ All services stopped successfully")
            
        except Exception as e:
            logger.error(f"❌ Service shutdown error: {e}")
    
    def get_service_status(self) -> Dict[str, Any]:
        """Get status of all services"""
        return {
            "services": self.services_status.copy(),
            "instances": {
                "video_streamer": self.video_streamer is not None,
                "network_monitor": self.network_monitor is not None,
                "cdn_manager": self.cdn_manager is not None
            },
            "config": self.config
        }
    
    async def restart_service(self, service_name: str):
        """Restart a specific service"""
        logger.info(f"🔄 Restarting {service_name} service...")
        
        try:
            if service_name == "video_streaming":
                # Video streaming requires full restart
                logger.warning("Video streaming restart requires full application restart")
                return False
            
            elif service_name == "network_monitoring":
                if self.network_monitor:
                    await self.network_monitor.stop_monitoring()
                await self._start_network_monitoring()
            
            elif service_name == "cdn_management":
                if self.cdn_manager:
                    await self.cdn_manager.cleanup()
                await self._start_cdn_management()
            
            else:
                logger.error(f"Unknown service: {service_name}")
                return False
            
            logger.info(f"✅ {service_name} service restarted")
            return True
            
        except Exception as e:
            logger.error(f"❌ {service_name} restart failed: {e}")
            return False

# Global service manager instance
service_manager: Optional[ServiceManager] = None

def get_service_manager() -> ServiceManager:
    """Get global service manager instance"""
    global service_manager
    if service_manager is None:
        service_manager = ServiceManager()
    return service_manager

async def initialize_services():
    """Initialize all backend services"""
    manager = get_service_manager()
    await manager.start_all_services()
    return manager

async def cleanup_services():
    """Cleanup all backend services"""
    global service_manager
    if service_manager:
        await service_manager.stop_all_services()
        service_manager = None
