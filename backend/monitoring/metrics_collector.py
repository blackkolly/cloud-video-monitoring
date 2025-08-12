# Enhanced Metrics Collection for Azure Monitoring
import time
import psutil
import asyncio
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

class MetricsCollector:
    """Comprehensive metrics collector for video streaming platform"""
    
    def __init__(self):
        # Video streaming metrics
        self.video_uploads_total = Counter('video_uploads_total', 'Total video uploads')
        self.video_streams_active = Gauge('video_streams_active', 'Active video streams')
        self.video_bytes_served = Counter('video_bytes_served_total', 'Total bytes served')
        self.video_request_duration = Histogram('video_request_duration_seconds', 'Video request duration')
        
        # Network metrics
        self.network_latency = Gauge('network_latency_seconds', 'Network latency in seconds')
        self.network_bandwidth = Gauge('network_bandwidth_mbps', 'Network bandwidth in Mbps')
        self.network_packet_loss = Gauge('network_packet_loss_percent', 'Packet loss percentage')
        self.network_connections = Gauge('network_connections_total', 'Total network connections')
        
        # System metrics
        self.cpu_usage = Gauge('system_cpu_usage_percent', 'CPU usage percentage')
        self.memory_usage = Gauge('system_memory_usage_percent', 'Memory usage percentage')
        self.disk_usage = Gauge('system_disk_usage_percent', 'Disk usage percentage')
        self.load_average = Gauge('system_load_average', 'System load average')
        
        # Application metrics
        self.http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
        self.http_request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
        self.active_users = Gauge('active_users_total', 'Active users')
        self.database_connections = Gauge('database_connections_active', 'Active database connections')
        
        # Video quality metrics
        self.video_quality_score = Gauge('video_quality_score', 'Video quality score', ['quality'])
        self.buffering_events = Counter('video_buffering_events_total', 'Video buffering events')
        self.playback_errors = Counter('video_playback_errors_total', 'Video playback errors')
        
        # Azure-specific metrics
        self.azure_resource_usage = Gauge('azure_resource_usage_percent', 'Azure resource usage', ['resource_type'])
        self.aks_pod_status = Gauge('aks_pod_status', 'AKS pod status', ['pod_name', 'status'])
        
        # Start background metrics collection
        self._collecting = False
        self._collection_task = None
        
    async def start_collection(self):
        """Start background metrics collection"""
        if not self._collecting:
            self._collecting = True
            self._collection_task = asyncio.create_task(self._collect_system_metrics())
            logger.info("Started metrics collection")
    
    async def stop_collection(self):
        """Stop background metrics collection"""
        if self._collecting:
            self._collecting = False
            if self._collection_task:
                self._collection_task.cancel()
                try:
                    await self._collection_task
                except asyncio.CancelledError:
                    pass
            logger.info("Stopped metrics collection")
    
    async def _collect_system_metrics(self):
        """Continuously collect system metrics"""
        while self._collecting:
            try:
                # CPU metrics
                cpu_percent = psutil.cpu_percent(interval=1)
                self.cpu_usage.set(cpu_percent)
                
                # Memory metrics
                memory = psutil.virtual_memory()
                self.memory_usage.set(memory.percent)
                
                # Disk metrics
                disk = psutil.disk_usage('/')
                self.disk_usage.set(disk.percent)
                
                # Load average (Linux/Mac only)
                try:
                    load_avg = psutil.getloadavg()[0]
                    self.load_average.set(load_avg)
                except (AttributeError, OSError):
                    # Windows doesn't have load average
                    pass
                
                # Network connections
                connections = len(psutil.net_connections())
                self.network_connections.set(connections)
                
                # Simulate network metrics (in real environment, get from actual monitoring)
                self.network_latency.set(0.025 + (time.time() % 10) / 1000)  # Simulate latency variation
                self.network_bandwidth.set(850 + (time.time() % 100))  # Simulate bandwidth variation
                self.network_packet_loss.set(0.1 + (time.time() % 5) / 100)  # Simulate packet loss
                
                await asyncio.sleep(15)  # Collect every 15 seconds
                
            except Exception as e:
                logger.error(f"Error collecting system metrics: {e}")
                await asyncio.sleep(15)
    
    def record_video_upload(self, file_size: int):
        """Record a video upload"""
        self.video_uploads_total.inc()
        self.video_bytes_served.inc(file_size)
        logger.info(f"Recorded video upload: {file_size} bytes")
    
    def record_stream_start(self):
        """Record the start of a video stream"""
        self.video_streams_active.inc()
        
    def record_stream_end(self):
        """Record the end of a video stream"""
        self.video_streams_active.dec()
    
    def record_http_request(self, method: str, endpoint: str, status: int, duration: float):
        """Record an HTTP request"""
        self.http_requests_total.labels(method=method, endpoint=endpoint, status=str(status)).inc()
        self.http_request_duration.labels(method=method, endpoint=endpoint).observe(duration)
    
    def record_video_quality(self, quality: str, score: float):
        """Record video quality metrics"""
        self.video_quality_score.labels(quality=quality).set(score)
    
    def record_buffering_event(self):
        """Record a video buffering event"""
        self.buffering_events.inc()
    
    def record_playback_error(self):
        """Record a video playback error"""
        self.playback_errors.inc()
    
    def set_active_users(self, count: int):
        """Set the number of active users"""
        self.active_users.set(count)
    
    def set_database_connections(self, count: int):
        """Set the number of active database connections"""
        self.database_connections.set(count)
    
    def record_azure_resource_usage(self, resource_type: str, usage_percent: float):
        """Record Azure resource usage"""
        self.azure_resource_usage.labels(resource_type=resource_type).set(usage_percent)
    
    def record_aks_pod_status(self, pod_name: str, status: str):
        """Record AKS pod status"""
        status_value = 1 if status == "Running" else 0
        self.aks_pod_status.labels(pod_name=pod_name, status=status).set(status_value)
    
    def get_metrics(self) -> str:
        """Get all metrics in Prometheus format"""
        return generate_latest().decode('utf-8')
    
    def get_metrics_summary(self) -> Dict[str, Any]:
        """Get metrics summary for JSON API"""
        try:
            # Get current system metrics
            cpu_percent = psutil.cpu_percent()
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            return {
                "timestamp": time.time(),
                "system": {
                    "cpu_usage_percent": cpu_percent,
                    "memory_usage_percent": memory.percent,
                    "disk_usage_percent": disk.percent,
                    "network_connections": len(psutil.net_connections())
                },
                "video_streaming": {
                    "active_streams": int(self.video_streams_active._value._value),
                    "total_uploads": int(self.video_uploads_total._value._value),
                    "total_bytes_served": int(self.video_bytes_served._value._value)
                },
                "network": {
                    "latency_ms": self.network_latency._value._value * 1000,
                    "bandwidth_mbps": self.network_bandwidth._value._value,
                    "packet_loss_percent": self.network_packet_loss._value._value
                }
            }
        except Exception as e:
            logger.error(f"Error getting metrics summary: {e}")
            return {
                "timestamp": time.time(),
                "error": str(e)
            }

# Global metrics collector instance
metrics_collector = MetricsCollector()
