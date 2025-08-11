# 🎥 Livepeer Integration Service
# Hybrid video infrastructure with Livepeer for cost optimization

import asyncio
import aiohttp
import json
import os
from typing import Dict, List, Optional, Union
import logging
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)

class LivepeerIntegration:
    """
    Livepeer integration for decentralized video transcoding and streaming
    Provides cost-effective alternative to traditional CDN services
    """
    
    def __init__(self, config_path: str = "config/livepeer-config.json"):
        self.config = self._load_config(config_path)
        # Use provided Livepeer API key
        self.api_key = '40d145e9-4cae-4913-89a2-fcd1c4fa3bfb'
        self.gateway_url = self.config.get('gateway_url', 'https://livepeer.studio')
        self.session: Optional[aiohttp.ClientSession] = None
        
    def _load_config(self, config_path: str) -> Dict:
        """Load Livepeer configuration"""
        default_config = {
            "enabled": True,
            "use_for_transcoding": True,
            "use_for_streaming": True,
            "fallback_to_traditional": True,
            "cost_threshold_gb": 100,  # Use Livepeer for videos > 100GB processing
            "quality_profiles": {
                "1080p": {"width": 1920, "height": 1080, "bitrate": 5000000},
                "720p": {"width": 1280, "height": 720, "bitrate": 2500000},
                "480p": {"width": 854, "height": 480, "bitrate": 1200000},
                "360p": {"width": 640, "height": 360, "bitrate": 800000}
            },
            "web3_features": {
                "nft_gating": False,
                "crypto_payments": False,
                "token_access": False
            }
        }
        
        try:
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    default_config.update(config)
            return default_config
        except Exception as e:
            logger.error(f"Livepeer config loading failed: {e}")
            return default_config
    
    async def initialize(self):
        """Initialize Livepeer client"""
        if not self.api_key:
            logger.warning("Livepeer API key not provided, integration disabled")
            return False
        
        self.session = aiohttp.ClientSession(
            headers={'Authorization': f'Bearer {self.api_key}'},
            timeout=aiohttp.ClientTimeout(total=300)
        )
        
        # Test connection
        try:
            await self._test_connection()
            logger.info("✅ Livepeer integration initialized successfully")
            return True
        except Exception as e:
            logger.error(f"❌ Livepeer initialization failed: {e}")
            return False
    
    async def _test_connection(self):
        """Test Livepeer API connection"""
        async with self.session.get(f"{self.gateway_url}/api/stream") as response:
            if response.status != 200:
                raise Exception(f"Livepeer API test failed: {response.status}")
    
    async def should_use_livepeer(self, video_size_bytes: int, duration_seconds: float) -> bool:
        """Determine if Livepeer should be used based on cost analysis"""
        if not self.config['enabled']:
            return False
        
        # Use Livepeer for larger files or longer content
        size_gb = video_size_bytes / (1024 ** 3)
        
        # Cost comparison logic
        livepeer_cost = size_gb * 0.01  # Approximate Livepeer cost
        traditional_cost = size_gb * 0.12  # Approximate traditional CDN cost
        
        cost_savings = traditional_cost - livepeer_cost
        threshold = self.config.get('cost_threshold_gb', 100)
        
        should_use = (
            size_gb > (threshold / 1024) or  # File size threshold
            cost_savings > 10 or  # Significant cost savings
            duration_seconds > 3600  # Long content (>1 hour)
        )
        
        logger.info(f"Livepeer analysis - Size: {size_gb:.2f}GB, Duration: {duration_seconds}s, Use: {should_use}")
        return should_use
    
    async def create_stream(self, name: str, profiles: List[Dict] = None) -> Dict:
        """Create a new Livepeer stream"""
        if not self.session:
            raise Exception("Livepeer not initialized")
        
        if profiles is None:
            profiles = [
                {"name": "720p", "bitrate": 2000000, "fps": 30, "width": 1280, "height": 720},
                {"name": "480p", "bitrate": 1000000, "fps": 30, "width": 854, "height": 480},
                {"name": "360p", "bitrate": 500000, "fps": 30, "width": 640, "height": 360}
            ]
        
        payload = {
            "name": name,
            "profiles": profiles,
            "record": True
        }
        
        async with self.session.post(
            f"{self.gateway_url}/api/stream",
            json=payload
        ) as response:
            if response.status == 201:
                stream_data = await response.json()
                logger.info(f"✅ Livepeer stream created: {stream_data['id']}")
                return stream_data
            else:
                error = await response.text()
                raise Exception(f"Stream creation failed: {error}")
    
    async def upload_video(self, video_path: str, name: str = None) -> Dict:
        """Upload video to Livepeer for transcoding"""
        if not self.session:
            raise Exception("Livepeer not initialized")
        
        video_name = name or Path(video_path).stem
        
        # Create upload URL
        async with self.session.post(
            f"{self.gateway_url}/api/asset/upload/url",
            json={"name": video_name}
        ) as response:
            upload_data = await response.json()
            upload_url = upload_data['url']
            asset_id = upload_data['asset']['id']
        
        # Upload file
        with open(video_path, 'rb') as f:
            async with self.session.put(upload_url, data=f) as response:
                if response.status != 200:
                    raise Exception(f"Video upload failed: {response.status}")
        
        logger.info(f"✅ Video uploaded to Livepeer: {asset_id}")
        return {"asset_id": asset_id, "upload_url": upload_url}
    
    async def get_asset_status(self, asset_id: str) -> Dict:
        """Get processing status of uploaded asset"""
        if not self.session:
            raise Exception("Livepeer not initialized")
        
        async with self.session.get(
            f"{self.gateway_url}/api/asset/{asset_id}"
        ) as response:
            if response.status == 200:
                return await response.json()
            else:
                raise Exception(f"Asset status check failed: {response.status}")
    
    async def get_playback_info(self, asset_id: str) -> Dict:
        """Get playback URLs and information"""
        asset_data = await self.get_asset_status(asset_id)
        
        if asset_data['status']['phase'] != 'ready':
            return {
                "ready": False,
                "phase": asset_data['status']['phase'],
                "progress": asset_data['status'].get('progress', 0)
            }
        
        playback_info = {
            "ready": True,
            "asset_id": asset_id,
            "playback_id": asset_data['playbackId'],
            "urls": {
                "hls": f"https://livepeercdn.studio/hls/{asset_data['playbackId']}/index.m3u8",
                "mp4": f"https://livepeercdn.studio/asset/{asset_data['playbackId']}/video.mp4"
            },
            "duration": asset_data.get('duration', 0),
            "size": asset_data.get('size', 0)
        }
        
        return playback_info
    
    async def delete_asset(self, asset_id: str) -> bool:
        """Delete asset from Livepeer"""
        if not self.session:
            return False
        
        try:
            async with self.session.delete(
                f"{self.gateway_url}/api/asset/{asset_id}"
            ) as response:
                return response.status == 204
        except Exception as e:
            logger.error(f"Asset deletion failed: {e}")
            return False
    
    async def get_usage_metrics(self) -> Dict:
        """Get Livepeer usage and cost metrics"""
        if not self.session:
            return {}
        
        try:
            async with self.session.get(
                f"{self.gateway_url}/api/data/usage"
            ) as response:
                if response.status == 200:
                    usage_data = await response.json()
                    return {
                        "transcoding_minutes": usage_data.get('transcodingMinutes', 0),
                        "streaming_minutes": usage_data.get('streamingMinutes', 0),
                        "storage_gb": usage_data.get('storageGB', 0),
                        "estimated_cost": usage_data.get('estimatedCost', 0),
                        "period": usage_data.get('period', 'current_month')
                    }
        except Exception as e:
            logger.error(f"Usage metrics fetch failed: {e}")
        
        return {}
    
    async def create_webhook(self, url: str, events: List[str] = None) -> Dict:
        """Create webhook for Livepeer events"""
        if not self.session:
            raise Exception("Livepeer not initialized")
        
        if events is None:
            events = ["stream.started", "stream.idle", "recording.ready", "asset.ready"]
        
        payload = {
            "name": "Video Platform Webhook",
            "url": url,
            "events": events
        }
        
        async with self.session.post(
            f"{self.gateway_url}/api/webhook",
            json=payload
        ) as response:
            if response.status == 201:
                webhook_data = await response.json()
                logger.info(f"✅ Livepeer webhook created: {webhook_data['id']}")
                return webhook_data
            else:
                error = await response.text()
                raise Exception(f"Webhook creation failed: {error}")
    
    async def cleanup(self):
        """Cleanup Livepeer client"""
        if self.session:
            await self.session.close()
            logger.info("Livepeer client cleaned up")

class HybridVideoService:
    """
    Hybrid video service that intelligently routes between
    Livepeer (cost-effective) and traditional CDN (reliable)
    """
    
    def __init__(self, video_streamer, livepeer_integration):
        self.video_streamer = video_streamer
        self.livepeer = livepeer_integration
        self.routing_stats = {
            "livepeer_requests": 0,
            "traditional_requests": 0,
            "cost_savings": 0.0
        }
    
    async def process_video_upload(self, video_path: str, video_size: int) -> Dict:
        """
        Intelligently route video processing based on cost analysis
        """
        video_name = Path(video_path).stem
        
        # Get video duration (simplified)
        duration = await self._get_video_duration(video_path)
        
        # Decide which service to use
        use_livepeer = await self.livepeer.should_use_livepeer(video_size, duration)
        
        if use_livepeer:
            try:
                # Process with Livepeer
                result = await self._process_with_livepeer(video_path, video_name)
                self.routing_stats["livepeer_requests"] += 1
                
                # Calculate cost savings
                traditional_cost = (video_size / (1024**3)) * 0.12
                livepeer_cost = (video_size / (1024**3)) * 0.01
                savings = traditional_cost - livepeer_cost
                self.routing_stats["cost_savings"] += savings
                
                logger.info(f"📈 Cost savings: ${savings:.2f} using Livepeer")
                return result
                
            except Exception as e:
                logger.warning(f"Livepeer processing failed, falling back: {e}")
                # Fallback to traditional processing
        
        # Process with traditional method
        result = await self._process_with_traditional(video_path, video_name)
        self.routing_stats["traditional_requests"] += 1
        return result
    
    async def _process_with_livepeer(self, video_path: str, video_name: str) -> Dict:
        """Process video using Livepeer"""
        # Upload to Livepeer
        upload_result = await self.livepeer.upload_video(video_path, video_name)
        asset_id = upload_result["asset_id"]
        
        # Wait for processing (with timeout)
        max_wait = 600  # 10 minutes
        wait_interval = 30
        elapsed = 0
        
        while elapsed < max_wait:
            status = await self.livepeer.get_asset_status(asset_id)
            
            if status['status']['phase'] == 'ready':
                playback_info = await self.livepeer.get_playback_info(asset_id)
                return {
                    "provider": "livepeer",
                    "asset_id": asset_id,
                    "playback_info": playback_info,
                    "processing_time": elapsed
                }
            elif status['status']['phase'] == 'failed':
                raise Exception("Livepeer processing failed")
            
            await asyncio.sleep(wait_interval)
            elapsed += wait_interval
        
        raise Exception("Livepeer processing timeout")
    
    async def _process_with_traditional(self, video_path: str, video_name: str) -> Dict:
        """Process video using traditional method"""
        # Use existing video streamer quality generation
        await self.video_streamer._generate_quality_versions(video_path)
        
        return {
            "provider": "traditional",
            "video_id": video_name,
            "qualities": ["360p", "480p", "720p", "1080p"],
            "processing_time": 120  # Estimate
        }
    
    async def _get_video_duration(self, video_path: str) -> float:
        """Get video duration (simplified implementation)"""
        try:
            # This would use ffprobe in real implementation
            return 300.0  # 5 minutes default
        except:
            return 300.0
    
    def get_routing_stats(self) -> Dict:
        """Get routing and cost statistics"""
        total_requests = self.routing_stats["livepeer_requests"] + self.routing_stats["traditional_requests"]
        
        return {
            "total_requests": total_requests,
            "livepeer_usage_percent": (self.routing_stats["livepeer_requests"] / max(total_requests, 1)) * 100,
            "total_cost_savings": self.routing_stats["cost_savings"],
            "average_savings_per_video": self.routing_stats["cost_savings"] / max(self.routing_stats["livepeer_requests"], 1)
        }

# Integration example
async def integrate_livepeer_with_existing_platform():
    """Example integration with existing video platform"""
    
    # Initialize Livepeer
    livepeer = LivepeerIntegration()
    await livepeer.initialize()
    
    # Create hybrid service
    from streaming.video_streamer import SimpleVideoStreamer
    video_streamer = SimpleVideoStreamer()
    
    hybrid_service = HybridVideoService(video_streamer, livepeer)
    
    return hybrid_service

if __name__ == "__main__":
    # Test integration
    async def test():
        service = await integrate_livepeer_with_existing_platform()
        print("Livepeer integration ready!")
    
    asyncio.run(test())
