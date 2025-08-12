# 🎥 Simple Video Streaming Service Integration
# Lightweight streaming server for the monitoring platform

import asyncio
import aiohttp
from aiohttp import web, WSMsgType
import aiofiles
import json
import os
import subprocess
import logging
from pathlib import Path
from typing import Dict, List, Optional
import time
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SimpleVideoStreamer:
    """Simple video streaming service for monitoring platform integration"""
    
    def __init__(self, config_path: str = "config/streaming-config.json"):
        self.config = self._load_config(config_path)
        self.active_streams: Dict[str, Dict] = {}
        self.stream_metrics: Dict[str, List] = {}
        self.app = web.Application()
        self._setup_routes()
        
    def _load_config(self, config_path: str) -> Dict:
        """Load streaming configuration"""
        default_config = {
            "video_storage_path": "./videos",
            "supported_formats": ["mp4", "webm", "m3u8"],
            "max_concurrent_streams": 100,
            "chunk_size": 1024 * 1024,  # 1MB chunks
            "quality_profiles": {
                "1080p": {"width": 1920, "height": 1080, "bitrate": "5000k"},
                "720p": {"width": 1280, "height": 720, "bitrate": "2500k"},
                "480p": {"width": 854, "height": 480, "bitrate": "1200k"},
                "360p": {"width": 640, "height": 360, "bitrate": "800k"}
            },
            "hls_config": {
                "segment_duration": 6,
                "playlist_size": 10
            }
        }
        
        try:
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    # Merge with defaults
                    default_config.update(config)
            return default_config
        except Exception as e:
            logger.error(f"Config loading failed: {e}")
            return default_config
    
    def _setup_routes(self):
        """Setup HTTP routes for streaming service"""
        self.app.router.add_get('/stream/{video_id}', self.stream_video)
        self.app.router.add_get('/hls/{video_id}/playlist.m3u8', self.serve_hls_playlist)
        self.app.router.add_get('/hls/{video_id}/segment_{segment_id}.ts', self.serve_hls_segment)
        self.app.router.add_get('/api/videos', self.list_videos)
        self.app.router.add_post('/api/upload', self.upload_video)
        self.app.router.add_get('/api/stream/{video_id}/stats', self.get_stream_stats)
        self.app.router.add_get('/health', self.health_check)
        self.app.router.add_get('/metrics', self.prometheus_metrics)
        
        # WebSocket for real-time streaming
        self.app.router.add_get('/ws/stream/{video_id}', self.websocket_stream)
        
        # Static file serving
        self.app.router.add_static('/', path='./static', name='static')

    async def stream_video(self, request):
        """Stream video with adaptive quality"""
        video_id = request.match_info['video_id']
        quality = request.query.get('quality', '720p')
        
        # Get video file path
        video_path = self._get_video_path(video_id, quality)
        if not video_path or not os.path.exists(video_path):
            return web.Response(status=404, text="Video not found")
        
        # Check range request for video seeking
        range_header = request.headers.get('Range')
        
        try:
            if range_header:
                return await self._serve_range_request(video_path, range_header)
            else:
                return await self._serve_full_video(video_path)
        except Exception as e:
            logger.error(f"Video streaming error: {e}")
            return web.Response(status=500, text="Streaming error")

    async def _serve_range_request(self, video_path: str, range_header: str):
        """Serve video with range support for seeking"""
        file_size = os.path.getsize(video_path)
        
        # Parse range header
        range_match = range_header.replace('bytes=', '').split('-')
        start = int(range_match[0]) if range_match[0] else 0
        end = int(range_match[1]) if range_match[1] else file_size - 1
        
        # Ensure valid range
        start = max(0, start)
        end = min(file_size - 1, end)
        content_length = end - start + 1
        
        # Prepare response headers
        headers = {
            'Content-Range': f'bytes {start}-{end}/{file_size}',
            'Accept-Ranges': 'bytes',
            'Content-Length': str(content_length),
            'Content-Type': 'video/mp4'
        }
        
        response = web.StreamResponse(status=206, headers=headers)
        await response.prepare(request)
        
        # Stream the requested range
        async with aiofiles.open(video_path, 'rb') as f:
            await f.seek(start)
            remaining = content_length
            
            while remaining > 0:
                chunk_size = min(self.config['chunk_size'], remaining)
                chunk = await f.read(chunk_size)
                if not chunk:
                    break
                
                await response.write(chunk)
                remaining -= len(chunk)
        
        await response.write_eof()
        return response

    async def _serve_full_video(self, video_path: str):
        """Serve complete video file"""
        file_size = os.path.getsize(video_path)
        
        headers = {
            'Content-Length': str(file_size),
            'Content-Type': 'video/mp4',
            'Accept-Ranges': 'bytes'
        }
        
        response = web.StreamResponse(headers=headers)
        await response.prepare(request)
        
        async with aiofiles.open(video_path, 'rb') as f:
            while True:
                chunk = await f.read(self.config['chunk_size'])
                if not chunk:
                    break
                await response.write(chunk)
        
        await response.write_eof()
        return response

    async def serve_hls_playlist(self, request):
        """Serve HLS playlist for adaptive streaming"""
        video_id = request.match_info['video_id']
        
        # Generate or serve existing HLS playlist
        playlist_path = f"./hls/{video_id}/playlist.m3u8"
        
        if not os.path.exists(playlist_path):
            # Generate HLS playlist if it doesn't exist
            await self._generate_hls_playlist(video_id)
        
        if os.path.exists(playlist_path):
            async with aiofiles.open(playlist_path, 'r') as f:
                playlist_content = await f.read()
            
            return web.Response(
                text=playlist_content,
                content_type='application/vnd.apple.mpegurl'
            )
        else:
            return web.Response(status=404, text="Playlist not found")

    async def serve_hls_segment(self, request):
        """Serve HLS video segments"""
        video_id = request.match_info['video_id']
        segment_id = request.match_info['segment_id']
        
        segment_path = f"./hls/{video_id}/segment_{segment_id}.ts"
        
        if os.path.exists(segment_path):
            async with aiofiles.open(segment_path, 'rb') as f:
                segment_data = await f.read()
            
            return web.Response(
                body=segment_data,
                content_type='video/mp2t'
            )
        else:
            return web.Response(status=404, text="Segment not found")

    async def _generate_hls_playlist(self, video_id: str):
        """Generate HLS playlist and segments using FFmpeg"""
        video_path = self._get_video_path(video_id)
        if not video_path:
            return
        
        output_dir = f"./hls/{video_id}"
        os.makedirs(output_dir, exist_ok=True)
        
        # FFmpeg command for HLS generation
        cmd = [
            'ffmpeg',
            '-i', video_path,
            '-c:v', 'libx264',
            '-c:a', 'aac',
            '-hls_time', str(self.config['hls_config']['segment_duration']),
            '-hls_list_size', str(self.config['hls_config']['playlist_size']),
            '-hls_segment_filename', f'{output_dir}/segment_%03d.ts',
            f'{output_dir}/playlist.m3u8'
        ]
        
        try:
            # Run FFmpeg asynchronously
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                logger.info(f"HLS playlist generated for video {video_id}")
            else:
                logger.error(f"FFmpeg error: {stderr.decode()}")
                
        except Exception as e:
            logger.error(f"HLS generation failed: {e}")

    async def websocket_stream(self, request):
        """WebSocket-based real-time streaming"""
        video_id = request.match_info['video_id']
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        
        # Add to active streams
        stream_info = {
            'video_id': video_id,
            'start_time': time.time(),
            'bytes_sent': 0,
            'client_ip': request.remote
        }
        
        stream_key = f"{video_id}_{int(time.time())}"
        self.active_streams[stream_key] = stream_info
        
        try:
            video_path = self._get_video_path(video_id)
            if not video_path:
                await ws.send_str(json.dumps({'error': 'Video not found'}))
                return ws
            
            # Send video metadata
            metadata = await self._get_video_metadata(video_path)
            await ws.send_str(json.dumps({'type': 'metadata', 'data': metadata}))
            
            # Stream video chunks
            async with aiofiles.open(video_path, 'rb') as f:
                while True:
                    chunk = await f.read(self.config['chunk_size'])
                    if not chunk:
                        break
                    
                    # Send chunk as binary data
                    await ws.send_bytes(chunk)
                    stream_info['bytes_sent'] += len(chunk)
                    
                    # Check if client disconnected
                    if ws.closed:
                        break
                    
                    # Small delay to prevent overwhelming client
                    await asyncio.sleep(0.1)
            
            await ws.send_str(json.dumps({'type': 'end'}))
            
        except Exception as e:
            logger.error(f"WebSocket streaming error: {e}")
            await ws.send_str(json.dumps({'error': str(e)}))
        finally:
            # Remove from active streams
            if stream_key in self.active_streams:
                del self.active_streams[stream_key]
        
        return ws

    async def list_videos(self, request):
        """List available videos"""
        video_dir = Path(self.config['video_storage_path'])
        videos = []
        
        if video_dir.exists():
            for video_file in video_dir.glob('*.mp4'):
                try:
                    metadata = await self._get_video_metadata(str(video_file))
                    videos.append({
                        'id': video_file.stem,
                        'filename': video_file.name,
                        'size': video_file.stat().st_size,
                        'metadata': metadata
                    })
                except Exception as e:
                    logger.error(f"Error processing video {video_file}: {e}")
        
        return web.json_response({'videos': videos})

    async def upload_video(self, request):
        """Handle video upload"""
        try:
            reader = await request.multipart()
            
            while True:
                field = await reader.next()
                if field is None:
                    break
                
                if field.name == 'video':
                    filename = field.filename
                    if not filename:
                        continue
                    
                    # Save uploaded video
                    video_dir = Path(self.config['video_storage_path'])
                    video_dir.mkdir(exist_ok=True)
                    
                    video_path = video_dir / filename
                    
                    async with aiofiles.open(video_path, 'wb') as f:
                        while True:
                            chunk = await field.read_chunk()
                            if not chunk:
                                break
                            await f.write(chunk)
                    
                    # Generate different quality versions
                    await self._generate_quality_versions(str(video_path))
                    
                    return web.json_response({
                        'status': 'success',
                        'video_id': video_path.stem,
                        'message': 'Video uploaded successfully'
                    })
            
            return web.json_response({'error': 'No video file found'}, status=400)
            
        except Exception as e:
            logger.error(f"Upload error: {e}")
            return web.json_response({'error': str(e)}, status=500)

    async def get_stream_stats(self, request):
        """Get streaming statistics"""
        video_id = request.match_info['video_id']
        
        # Collect stats for this video
        stats = {
            'video_id': video_id,
            'active_streams': len([s for s in self.active_streams.values() if s['video_id'] == video_id]),
            'total_bytes_served': sum(s['bytes_sent'] for s in self.active_streams.values() if s['video_id'] == video_id),
            'average_bitrate': 0,  # Would calculate from actual streams
            'viewer_locations': [],  # Would collect from client IPs
            'quality_distribution': {}  # Would track quality preferences
        }
        
        return web.json_response(stats)

    async def health_check(self, request):
        """Health check endpoint"""
        return web.json_response({
            'status': 'healthy',
            'active_streams': len(self.active_streams),
            'timestamp': datetime.utcnow().isoformat()
        })

    async def prometheus_metrics(self, request):
        """Prometheus metrics endpoint"""
        metrics = []
        
        # Active streams metric
        metrics.append(f'video_active_streams {len(self.active_streams)}')
        
        # Bytes transferred
        total_bytes = sum(s['bytes_sent'] for s in self.active_streams.values())
        metrics.append(f'video_bytes_transferred_total {total_bytes}')
        
        # Streams by video
        video_counts = {}
        for stream in self.active_streams.values():
            video_id = stream['video_id']
            video_counts[video_id] = video_counts.get(video_id, 0) + 1
        
        for video_id, count in video_counts.items():
            metrics.append(f'video_streams_by_video{{video_id="{video_id}"}} {count}')
        
        return web.Response(text='\n'.join(metrics), content_type='text/plain')

    def _get_video_path(self, video_id: str, quality: str = None) -> Optional[str]:
        """Get video file path"""
        video_dir = Path(self.config['video_storage_path'])
        
        if quality and quality != 'original':
            # Look for quality-specific version
            quality_path = video_dir / f"{video_id}_{quality}.mp4"
            if quality_path.exists():
                return str(quality_path)
        
        # Fall back to original
        original_path = video_dir / f"{video_id}.mp4"
        if original_path.exists():
            return str(original_path)
        
        return None

    async def _get_video_metadata(self, video_path: str) -> Dict:
        """Get video metadata using FFprobe"""
        try:
            cmd = [
                'ffprobe',
                '-v', 'quiet',
                '-print_format', 'json',
                '-show_format',
                '-show_streams',
                video_path
            ]
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                metadata = json.loads(stdout.decode())
                return {
                    'duration': float(metadata.get('format', {}).get('duration', 0)),
                    'format': metadata.get('format', {}).get('format_name', ''),
                    'size': int(metadata.get('format', {}).get('size', 0)),
                    'bitrate': int(metadata.get('format', {}).get('bit_rate', 0)),
                    'streams': len(metadata.get('streams', []))
                }
            else:
                logger.error(f"FFprobe error: {stderr.decode()}")
                return {}
                
        except Exception as e:
            logger.error(f"Metadata extraction failed: {e}")
            return {}

    async def _generate_quality_versions(self, video_path: str):
        """Generate different quality versions of video"""
        video_id = Path(video_path).stem
        
        for quality, settings in self.config['quality_profiles'].items():
            output_path = f"{self.config['video_storage_path']}/{video_id}_{quality}.mp4"
            
            cmd = [
                'ffmpeg',
                '-i', video_path,
                '-c:v', 'libx264',
                '-c:a', 'aac',
                '-b:v', settings['bitrate'],
                '-s', f"{settings['width']}x{settings['height']}",
                '-preset', 'fast',
                '-y',  # Overwrite output file
                output_path
            ]
            
            try:
                process = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                )
                
                stdout, stderr = await process.communicate()
                
                if process.returncode == 0:
                    logger.info(f"Generated {quality} version for {video_id}")
                else:
                    logger.error(f"Quality generation failed: {stderr.decode()}")
                    
            except Exception as e:
                logger.error(f"Quality generation error: {e}")

    async def start_server(self, host='0.0.0.0', port=8006):
        """Start the streaming server"""
        logger.info(f"🎥 Starting Simple Video Streaming Server on {host}:{port}")
        
        # Create necessary directories
        os.makedirs(self.config['video_storage_path'], exist_ok=True)
        os.makedirs('./hls', exist_ok=True)
        os.makedirs('./static', exist_ok=True)
        
        runner = web.AppRunner(self.app)
        await runner.setup()
        
        site = web.TCPSite(runner, host, port)
        await site.start()
        
        logger.info(f"✅ Video streaming server running at http://{host}:{port}")
        logger.info("📺 Available endpoints:")
        logger.info("   GET  /api/videos - List videos")
        logger.info("   POST /api/upload - Upload video")
        logger.info("   GET  /stream/{video_id} - Stream video")
        logger.info("   GET  /hls/{video_id}/playlist.m3u8 - HLS playlist")
        logger.info("   WS   /ws/stream/{video_id} - WebSocket stream")
        logger.info("   GET  /health - Health check")
        logger.info("   GET  /metrics - Prometheus metrics")

# Example usage
async def main():
    streamer = SimpleVideoStreamer()
    await streamer.start_server()
    
    # Keep server running
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        logger.info("Server stopped")

if __name__ == "__main__":
    asyncio.run(main())
