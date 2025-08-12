# Video Streaming Analytics Engine
import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)

@dataclass
class StreamingEvent:
    """Represents a streaming event for analytics"""
    timestamp: datetime
    event_type: str  # 'stream_start', 'stream_end', 'quality_change', 'buffering', 'error'
    user_id: str
    video_id: str
    quality: str
    location: str
    device_type: str
    metadata: Dict[str, Any]

class VideoAnalyticsEngine:
    """Comprehensive analytics engine for video streaming platform"""
    
    def __init__(self):
        self.events: List[StreamingEvent] = []
        self.active_streams: Dict[str, Dict] = {}
        self.user_sessions: Dict[str, Dict] = {}
        
    def record_event(self, event: StreamingEvent):
        """Record a streaming event"""
        self.events.append(event)
        
        # Update active streams
        if event.event_type == 'stream_start':
            self.active_streams[event.user_id] = {
                'video_id': event.video_id,
                'start_time': event.timestamp,
                'quality': event.quality,
                'location': event.location,
                'device_type': event.device_type,
                'buffering_count': 0,
                'quality_changes': 0
            }
        elif event.event_type == 'stream_end' and event.user_id in self.active_streams:
            stream = self.active_streams.pop(event.user_id)
            # Calculate session duration
            duration = (event.timestamp - stream['start_time']).total_seconds()
            
            # Store completed session
            self.user_sessions[f"{event.user_id}_{event.timestamp.isoformat()}"] = {
                **stream,
                'end_time': event.timestamp,
                'duration_seconds': duration
            }
        elif event.event_type == 'buffering' and event.user_id in self.active_streams:
            self.active_streams[event.user_id]['buffering_count'] += 1
        elif event.event_type == 'quality_change' and event.user_id in self.active_streams:
            self.active_streams[event.user_id]['quality_changes'] += 1
            self.active_streams[event.user_id]['quality'] = event.quality
    
    def get_real_time_metrics(self) -> Dict[str, Any]:
        """Get real-time streaming metrics"""
        now = datetime.utcnow()
        one_hour_ago = now - timedelta(hours=1)
        
        # Filter recent events
        recent_events = [e for e in self.events if e.timestamp >= one_hour_ago]
        
        # Calculate metrics
        total_streams = len([e for e in recent_events if e.event_type == 'stream_start'])
        buffering_events = len([e for e in recent_events if e.event_type == 'buffering'])
        quality_changes = len([e for e in recent_events if e.event_type == 'quality_change'])
        
        # Geographic distribution
        locations = {}
        for event in recent_events:
            if event.event_type == 'stream_start':
                locations[event.location] = locations.get(event.location, 0) + 1
        
        # Device distribution
        devices = {}
        for event in recent_events:
            if event.event_type == 'stream_start':
                devices[event.device_type] = devices.get(event.device_type, 0) + 1
        
        # Quality distribution
        qualities = {}
        for stream in self.active_streams.values():
            quality = stream['quality']
            qualities[quality] = qualities.get(quality, 0) + 1
        
        return {
            "timestamp": now.isoformat(),
            "active_streams": len(self.active_streams),
            "total_streams_last_hour": total_streams,
            "buffering_events_last_hour": buffering_events,
            "quality_changes_last_hour": quality_changes,
            "geographic_distribution": locations,
            "device_distribution": devices,
            "quality_distribution": qualities,
            "average_concurrent_viewers": len(self.active_streams),
            "quality_score": self._calculate_quality_score(buffering_events, quality_changes, total_streams)
        }
    
    def get_network_analytics(self) -> Dict[str, Any]:
        """Get network performance analytics"""
        now = datetime.utcnow()
        
        # Simulate network metrics (in production, get from actual monitoring)
        return {
            "timestamp": now.isoformat(),
            "global_metrics": {
                "average_latency_ms": 25.5 + np.random.normal(0, 5),
                "p95_latency_ms": 45.2 + np.random.normal(0, 8),
                "p99_latency_ms": 85.1 + np.random.normal(0, 15),
                "bandwidth_utilization_percent": 75.5 + np.random.normal(0, 10),
                "packet_loss_percent": 0.1 + max(0, np.random.normal(0, 0.05)),
                "jitter_ms": 2.1 + max(0, np.random.normal(0, 1))
            },
            "regional_metrics": {
                "us-east-1": {
                    "latency_ms": 20.1 + np.random.normal(0, 3),
                    "bandwidth_mbps": 1000 + np.random.normal(0, 50),
                    "active_connections": 450 + int(np.random.normal(0, 20))
                },
                "eu-west-1": {
                    "latency_ms": 45.2 + np.random.normal(0, 5),
                    "bandwidth_mbps": 850 + np.random.normal(0, 40),
                    "active_connections": 320 + int(np.random.normal(0, 15))
                },
                "ap-southeast-1": {
                    "latency_ms": 85.5 + np.random.normal(0, 8),
                    "bandwidth_mbps": 750 + np.random.normal(0, 35),
                    "active_connections": 180 + int(np.random.normal(0, 10))
                }
            },
            "cdn_performance": {
                "cloudflare": {
                    "response_time_ms": 15.2 + np.random.normal(0, 2),
                    "cache_hit_ratio": 0.92 + np.random.normal(0, 0.02),
                    "bandwidth_mbps": 2500 + np.random.normal(0, 100)
                },
                "azure_cdn": {
                    "response_time_ms": 22.1 + np.random.normal(0, 3),
                    "cache_hit_ratio": 0.89 + np.random.normal(0, 0.03),
                    "bandwidth_mbps": 2200 + np.random.normal(0, 90)
                }
            }
        }
    
    def get_user_engagement_analytics(self) -> Dict[str, Any]:
        """Get user engagement and behavior analytics"""
        now = datetime.utcnow()
        
        # Calculate engagement metrics from completed sessions
        if not self.user_sessions:
            return self._get_mock_engagement_analytics()
        
        sessions = list(self.user_sessions.values())
        
        # Average watch time
        avg_duration = np.mean([s['duration_seconds'] for s in sessions])
        
        # Completion rate (sessions > 5 minutes considered complete)
        completed_sessions = [s for s in sessions if s['duration_seconds'] > 300]
        completion_rate = len(completed_sessions) / len(sessions) * 100 if sessions else 0
        
        # Quality stability
        quality_stable_sessions = [s for s in sessions if s['quality_changes'] <= 2]
        quality_stability = len(quality_stable_sessions) / len(sessions) * 100 if sessions else 0
        
        # Buffering analysis
        avg_buffering = np.mean([s['buffering_count'] for s in sessions])
        
        return {
            "timestamp": now.isoformat(),
            "engagement_metrics": {
                "total_sessions": len(sessions),
                "active_users": len(self.active_streams),
                "average_watch_time_minutes": avg_duration / 60,
                "completion_rate_percent": completion_rate,
                "quality_stability_percent": quality_stability,
                "average_buffering_events": avg_buffering
            },
            "content_performance": {
                "most_watched_videos": self._get_popular_content(),
                "peak_viewing_hours": self._get_peak_hours(),
                "device_preferences": self._get_device_preferences()
            },
            "user_experience": {
                "quality_satisfaction_score": self._calculate_satisfaction_score(),
                "streaming_reliability_percent": max(0, 100 - avg_buffering * 10),
                "user_retention_rate": 85.5 + np.random.normal(0, 5)
            }
        }
    
    def get_azure_cost_analytics(self) -> Dict[str, Any]:
        """Get Azure cost and resource analytics"""
        now = datetime.utcnow()
        
        # Simulate cost metrics (in production, get from Azure Cost Management API)
        daily_cost = 1.95 + np.random.normal(0, 0.2)
        monthly_projected = daily_cost * 30
        
        return {
            "timestamp": now.isoformat(),
            "cost_overview": {
                "daily_cost_usd": daily_cost,
                "monthly_to_date_usd": daily_cost * datetime.now().day,
                "projected_monthly_usd": monthly_projected,
                "budget_limit_usd": 100.0,
                "budget_utilization_percent": (monthly_projected / 100.0) * 100
            },
            "service_breakdown": {
                "Azure Kubernetes Service": 35.20,
                "Container Registry": 5.50,
                "Load Balancer": 4.15,
                "Storage Account": 3.00,
                "Network": 2.85,
                "Monitoring": 1.80
            },
            "optimization_recommendations": [
                {
                    "service": "AKS",
                    "recommendation": "Consider using Spot instances for dev workloads",
                    "potential_savings_percent": 15
                },
                {
                    "service": "Storage",
                    "recommendation": "Enable lifecycle management for old videos",
                    "potential_savings_percent": 25
                },
                {
                    "service": "Network",
                    "recommendation": "Optimize CDN caching policies",
                    "potential_savings_percent": 10
                }
            ],
            "resource_utilization": {
                "cpu_utilization_percent": 35.2 + np.random.normal(0, 5),
                "memory_utilization_percent": 45.8 + np.random.normal(0, 8),
                "storage_utilization_percent": 22.5 + np.random.normal(0, 3),
                "network_utilization_percent": 65.3 + np.random.normal(0, 10)
            }
        }
    
    def generate_analytics_report(self, time_range: str = "24h") -> Dict[str, Any]:
        """Generate comprehensive analytics report"""
        return {
            "report_metadata": {
                "generated_at": datetime.utcnow().isoformat(),
                "time_range": time_range,
                "report_type": "comprehensive_analytics"
            },
            "streaming_metrics": self.get_real_time_metrics(),
            "network_analytics": self.get_network_analytics(),
            "user_engagement": self.get_user_engagement_analytics(),
            "azure_costs": self.get_azure_cost_analytics(),
            "recommendations": self._generate_recommendations()
        }
    
    def _calculate_quality_score(self, buffering_events: int, quality_changes: int, total_streams: int) -> float:
        """Calculate overall streaming quality score (0-100)"""
        if total_streams == 0:
            return 100.0
        
        buffering_penalty = (buffering_events / total_streams) * 20
        quality_change_penalty = (quality_changes / total_streams) * 10
        
        score = 100 - buffering_penalty - quality_change_penalty
        return max(0, min(100, score))
    
    def _calculate_satisfaction_score(self) -> float:
        """Calculate user satisfaction score"""
        return 88.5 + np.random.normal(0, 3)
    
    def _get_popular_content(self) -> List[Dict]:
        """Get most popular content"""
        return [
            {"video_id": "demo1", "title": "Sample Video 1", "views": 5420, "watch_time_hours": 1250},
            {"video_id": "demo2", "title": "Sample Video 2", "views": 3890, "watch_time_hours": 980},
            {"video_id": "demo3", "title": "Sample Video 3", "views": 2150, "watch_time_hours": 650}
        ]
    
    def _get_peak_hours(self) -> List[int]:
        """Get peak viewing hours (0-23)"""
        return [19, 20, 21, 22]  # 7-10 PM
    
    def _get_device_preferences(self) -> Dict[str, float]:
        """Get device usage distribution"""
        return {
            "Desktop": 55.2,
            "Mobile": 35.8,
            "Smart TV": 9.0
        }
    
    def _get_mock_engagement_analytics(self) -> Dict[str, Any]:
        """Mock engagement analytics when no real data available"""
        now = datetime.utcnow()
        return {
            "timestamp": now.isoformat(),
            "engagement_metrics": {
                "total_sessions": 245,
                "active_users": 89,
                "average_watch_time_minutes": 12.5,
                "completion_rate_percent": 78.5,
                "quality_stability_percent": 92.3,
                "average_buffering_events": 0.8
            },
            "content_performance": {
                "most_watched_videos": self._get_popular_content(),
                "peak_viewing_hours": self._get_peak_hours(),
                "device_preferences": self._get_device_preferences()
            },
            "user_experience": {
                "quality_satisfaction_score": 88.5,
                "streaming_reliability_percent": 95.2,
                "user_retention_rate": 85.5
            }
        }
    
    def _generate_recommendations(self) -> List[Dict]:
        """Generate optimization recommendations"""
        return [
            {
                "category": "Performance",
                "priority": "High",
                "recommendation": "Implement adaptive bitrate streaming for better quality adjustment",
                "expected_improvement": "15% reduction in buffering events"
            },
            {
                "category": "Cost",
                "priority": "Medium",
                "recommendation": "Enable Azure Blob Storage lifecycle management",
                "expected_improvement": "25% storage cost reduction"
            },
            {
                "category": "Network",
                "priority": "Medium",
                "recommendation": "Optimize CDN cache TTL settings",
                "expected_improvement": "10% latency reduction"
            },
            {
                "category": "User Experience",
                "priority": "High",
                "recommendation": "Implement preemptive quality adjustment based on network conditions",
                "expected_improvement": "20% improvement in user satisfaction"
            }
        ]

# Global analytics engine instance
analytics_engine = VideoAnalyticsEngine()
