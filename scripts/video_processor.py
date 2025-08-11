# 🎥 Video Processing Script
import os
import subprocess
import json
import time
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class VideoProcessor:
    """FFmpeg-based video processing service"""
    
    def __init__(self):
        self.input_dir = os.getenv('INPUT_DIR', '/input')
        self.output_dir = os.getenv('OUTPUT_DIR', '/output')
        self.hls_dir = os.getenv('HLS_DIR', '/hls')
        
        # Quality profiles
        self.quality_profiles = {
            '1080p': {'width': 1920, 'height': 1080, 'bitrate': '5000k'},
            '720p': {'width': 1280, 'height': 720, 'bitrate': '2500k'},
            '480p': {'width': 854, 'height': 480, 'bitrate': '1200k'},
            '360p': {'width': 640, 'height': 360, 'bitrate': '800k'}
        }
    
    def process_video(self, input_file):
        """Process video into multiple qualities and HLS"""
        video_name = Path(input_file).stem
        
        try:
            # Create output directories
            video_output_dir = Path(self.output_dir) / video_name
            video_hls_dir = Path(self.hls_dir) / video_name
            
            video_output_dir.mkdir(parents=True, exist_ok=True)
            video_hls_dir.mkdir(parents=True, exist_ok=True)
            
            # Generate quality versions
            for quality, settings in self.quality_profiles.items():
                output_file = video_output_dir / f"{video_name}_{quality}.mp4"
                
                cmd = [
                    'ffmpeg',
                    '-i', input_file,
                    '-c:v', 'libx264',
                    '-c:a', 'aac',
                    '-b:v', settings['bitrate'],
                    '-s', f"{settings['width']}x{settings['height']}",
                    '-preset', 'fast',
                    '-y',
                    str(output_file)
                ]
                
                logger.info(f"Processing {quality} version...")
                subprocess.run(cmd, check=True)
            
            # Generate HLS playlist
            hls_playlist = video_hls_dir / 'playlist.m3u8'
            
            cmd = [
                'ffmpeg',
                '-i', input_file,
                '-c:v', 'libx264',
                '-c:a', 'aac',
                '-hls_time', '6',
                '-hls_list_size', '10',
                '-hls_segment_filename', str(video_hls_dir / 'segment_%03d.ts'),
                str(hls_playlist)
            ]
            
            logger.info("Generating HLS playlist...")
            subprocess.run(cmd, check=True)
            
            logger.info(f"Successfully processed {video_name}")
            
        except subprocess.CalledProcessError as e:
            logger.error(f"FFmpeg error processing {video_name}: {e}")
        except Exception as e:
            logger.error(f"Error processing {video_name}: {e}")
    
    def watch_and_process(self):
        """Watch input directory and process new videos"""
        logger.info(f"Watching {self.input_dir} for new videos...")
        
        processed_files = set()
        
        while True:
            try:
                input_path = Path(self.input_dir)
                
                # Look for video files
                for video_file in input_path.glob('*.mp4'):
                    if video_file.name not in processed_files:
                        logger.info(f"Found new video: {video_file.name}")
                        self.process_video(str(video_file))
                        processed_files.add(video_file.name)
                
                # Check every 10 seconds
                time.sleep(10)
                
            except KeyboardInterrupt:
                logger.info("Stopping video processor...")
                break
            except Exception as e:
                logger.error(f"Error in watch loop: {e}")
                time.sleep(30)

if __name__ == "__main__":
    processor = VideoProcessor()
    processor.watch_and_process()
