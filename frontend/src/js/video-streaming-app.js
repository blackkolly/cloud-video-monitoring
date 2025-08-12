class VideoStreamingApp {
    constructor() {
        this.currentVideo = null;
        this.selectedFile = null;
        this.streamingSocket = null;
        this.monitoringInterval = null;
        // Backend API URL - use relative URL in production
        this.baseUrl = window.location.origin;
        
        // Video player optimization properties
        this.loadingTimeout = null;
        this.canplayHandler = null;
        this.waitingHandler = null;
        this.playingHandler = null;
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.loadVideoList();
        this.startMonitoring();
    }
    
    setupEventListeners() {
        // Video player events - only basic error handling here
        const video = document.getElementById('videoPlayer');
        video.addEventListener('timeupdate', () => this.updateStats());
        video.addEventListener('error', (e) => this.handleVideoError(e));
        
        // Upload area events
        const uploadArea = document.getElementById('uploadArea');
        if (uploadArea) {
            uploadArea.addEventListener('click', () => {
                const fileInput = document.getElementById('fileInput');
                if (fileInput) fileInput.click();
            });
            uploadArea.addEventListener('dragover', (e) => {
                e.preventDefault();
                uploadArea.classList.add('border-primary', 'bg-light');
            });
            uploadArea.addEventListener('dragleave', () => {
                uploadArea.classList.remove('border-primary', 'bg-light');
            });
            uploadArea.addEventListener('drop', (e) => {
                e.preventDefault();
                uploadArea.classList.remove('border-primary', 'bg-light');
                this.handleFileSelect(e);
            });
        }
    }
    
    async loadVideoList() {
        try {
            const response = await fetch(`${this.baseUrl}/api/videos`);
            const data = await response.json();
            
            this.renderVideoList(data.videos);
        } catch (error) {
            console.error('Error loading videos:', error);
            this.showError('Failed to load video library');
        }
    }
    
    renderVideoList(videos) {
        const videoList = document.getElementById('videoList');
        
        if (videos.length === 0) {
            videoList.innerHTML = `
                <div class="text-center p-4 text-muted">
                    <i class="fas fa-video fa-3x mb-2"></i>
                    <p>No videos available</p>
                </div>
            `;
            return;
        }
        
        videoList.innerHTML = videos.map(video => `
            <div class="video-card p-3 border-bottom" onclick="app.playVideo('${video.id}', '${video.filename}')">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <i class="fas fa-play-circle fa-2x text-primary"></i>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="mb-1">${video.filename}</h6>
                        <small class="text-muted">
                            ${this.formatFileSize(video.size)} • 
                            ${video.metadata.duration ? this.formatDuration(video.metadata.duration) : 'Unknown'}
                        </small>
                    </div>
                </div>
            </div>
        `).join('');
    }
    
    async playVideo(videoId, filename) {
        // Clean up any previous video setup
        this.cleanupVideoPlayer();
        
        this.currentVideo = videoId;
        
        const video = document.getElementById('videoPlayer');
        const quality = document.getElementById('qualitySelect').value;
        
        // Update video info
        document.getElementById('videoTitle').textContent = filename;
        document.getElementById('videoDescription').textContent = `Playing in ${quality} quality`;
        
        // Set video source with optimizations
        const streamUrl = quality === 'auto' ? 
            `${this.baseUrl}/stream/${videoId}` : 
            `${this.baseUrl}/stream/${videoId}?quality=${quality}`;
        
        // Optimize video element for streaming with aggressive buffering
        video.preload = 'auto';  // Changed from 'metadata' to 'auto' for better buffering
        video.controls = true;
        video.autoplay = false;
        
        // Enhanced buffering optimization
        video.setAttribute('playsinline', true);  // Better mobile support
        video.setAttribute('webkit-playsinline', true);
        
        // Set buffer size hints for smoother playback
        if (video.buffered) {
            video.currentTime = 0;
        }
        
        // Remove old event listeners to prevent conflicts
        video.removeEventListener('waiting', this.waitingHandler);
        video.removeEventListener('playing', this.playingHandler);
        video.removeEventListener('canplay', this.canplayHandler);
        
        video.src = streamUrl;
        video.load();
        
        try {
            // Create bound event handlers for better control
            this.canplayHandler = () => {
                this.showLoading(false);
                console.log('Video ready to play');
            };
            
            this.waitingHandler = () => {
                // Only show loading if we've been waiting for more than 500ms
                this.loadingTimeout = setTimeout(() => {
                    this.showLoading(true);
                }, 500);
            };
            
            this.playingHandler = () => {
                // Clear any pending loading timeout
                if (this.loadingTimeout) {
                    clearTimeout(this.loadingTimeout);
                    this.loadingTimeout = null;
                }
                this.showLoading(false);
            };
            
            // Add optimized event listeners
            video.addEventListener('canplay', this.canplayHandler, { once: true });
            video.addEventListener('waiting', this.waitingHandler);
            video.addEventListener('playing', this.playingHandler);
            
            // Additional events for smoother experience
            video.addEventListener('loadeddata', () => {
                this.showLoading(false);
                console.log('Video data loaded');
            }, { once: true });
            
            video.addEventListener('progress', () => {
                // Update buffering progress
                if (video.buffered.length > 0) {
                    const bufferedEnd = video.buffered.end(video.buffered.length - 1);
                    const duration = video.duration;
                    if (duration > 0) {
                        const bufferedPercent = (bufferedEnd / duration) * 100;
                        console.log(`Buffered: ${bufferedPercent.toFixed(1)}%`);
                    }
                }
            });
            
            await video.play();
            this.showStatsOverlay(true);
            await this.updateStreamStats();
        } catch (error) {
            console.error('Error playing video:', error);
            this.showError('Failed to play video');
        }
    }
    
    // Cleanup method to remove event listeners and timeouts
    cleanupVideoPlayer() {
        const video = document.getElementById('videoPlayer');
        if (video) {
            // Remove our custom event listeners
            if (this.canplayHandler) {
                video.removeEventListener('canplay', this.canplayHandler);
            }
            if (this.waitingHandler) {
                video.removeEventListener('waiting', this.waitingHandler);
            }
            if (this.playingHandler) {
                video.removeEventListener('playing', this.playingHandler);
            }
        }
        
        // Clear any pending timeouts
        if (this.loadingTimeout) {
            clearTimeout(this.loadingTimeout);
            this.loadingTimeout = null;
        }
        
        // Hide loading indicator
        this.showLoading(false);
    }
    
    changeQuality() {
        if (this.currentVideo) {
            // Clean up before changing quality
            this.cleanupVideoPlayer();
            const filename = document.getElementById('videoTitle').textContent;
            this.playVideo(this.currentVideo, filename);
        }
    }
    
    async updateStreamStats() {
        if (!this.currentVideo) return;
        
        try {
            const response = await fetch(`${this.baseUrl}/api/stream/${this.currentVideo}/stats`);
            const stats = await response.json();
            
            // Update monitoring metrics
            document.getElementById('currentViewers').textContent = stats.active_streams;
            document.getElementById('avgBitrate').textContent = `${(stats.average_bitrate / 1000000).toFixed(1)} Mbps`;
            
        } catch (error) {
            console.error('Error updating stats:', error);
        }
    }
    
    updateStats() {
        const video = document.getElementById('videoPlayer');
        
        if (video.videoWidth && video.videoHeight) {
            document.getElementById('resolution').textContent = `${video.videoWidth}x${video.videoHeight}`;
        }
        
        // Calculate buffer level
        if (video.buffered.length > 0) {
            const buffered = video.buffered.end(video.buffered.length - 1);
            const duration = video.duration;
            const bufferPercent = duration ? Math.round((buffered / duration) * 100) : 0;
            document.getElementById('bufferHealth').textContent = `${bufferPercent}%`;
            document.getElementById('bufferLevel').textContent = `${Math.round(buffered - video.currentTime)}s`;
        }
        
        // Estimate bitrate (simplified)
        if (video.currentTime > 0) {
            const estimatedBitrate = (video.videoWidth * video.videoHeight * 0.1 / 1000).toFixed(0);
            document.getElementById('bitrate').textContent = `${estimatedBitrate} kbps`;
        }
    }
    
    handleFileSelect(event) {
        const files = event.dataTransfer ? event.dataTransfer.files : event.target.files;
        
        if (files.length > 0) {
            this.selectedFile = files[0];
            document.getElementById('uploadBtn').disabled = false;
            
            // Update upload area text
            const uploadArea = document.getElementById('uploadArea');
            uploadArea.innerHTML = `
                <i class="fas fa-file-video fa-3x text-success mb-3"></i>
                <h6>${this.selectedFile.name}</h6>
                <p class="text-muted">${this.formatFileSize(this.selectedFile.size)}</p>
            `;
        }
    }
    
    async uploadVideo() {
        if (!this.selectedFile) {
            console.error('No file selected for upload');
            this.showError('Please select a file first');
            return;
        }
        
        console.log('Starting upload for file:', this.selectedFile.name, 'Size:', this.selectedFile.size);
        
        const formData = new FormData();
        formData.append('video', this.selectedFile);
        
        const progressBar = document.getElementById('progressBar');
        const progressText = document.getElementById('progressText');
        const uploadProgress = document.getElementById('uploadProgress');
        
        uploadProgress.style.display = 'block';
        document.getElementById('uploadBtn').disabled = true;
        
        try {
            const xhr = new XMLHttpRequest();
            
            xhr.upload.addEventListener('progress', (e) => {
                if (e.lengthComputable) {
                    const percentComplete = Math.round((e.loaded / e.total) * 100);
                    progressBar.style.width = `${percentComplete}%`;
                    progressText.textContent = `${percentComplete}%`;
                }
            });
            
            xhr.addEventListener('load', () => {
                console.log('Upload response status:', xhr.status);
                console.log('Upload response text:', xhr.responseText);
                
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        this.showSuccess('Video uploaded successfully!');
                        this.hideUploadModal();
                        this.loadVideoList(); // Refresh video list
                    } catch (parseError) {
                        console.error('Error parsing upload response:', parseError);
                        this.showError('Upload succeeded but response was invalid');
                    }
                } else {
                    console.error('Upload failed with status:', xhr.status);
                    this.showError(`Upload failed: ${xhr.status} ${xhr.statusText}`);
                }
                
                uploadProgress.style.display = 'none';
                document.getElementById('uploadBtn').disabled = false;
            });
            
            xhr.addEventListener('error', (event) => {
                console.error('Upload XHR error:', event);
                console.error('Upload error details:', {
                    status: xhr.status,
                    statusText: xhr.statusText,
                    responseText: xhr.responseText
                });
                this.showError('Upload failed - Network error');
                uploadProgress.style.display = 'none';
                document.getElementById('uploadBtn').disabled = false;
            });
            
            console.log('Sending upload request to:', `${this.baseUrl}/api/upload`);
            xhr.open('POST', `${this.baseUrl}/api/upload`);
            xhr.send(formData);
            
        } catch (error) {
            console.error('Upload error:', error);
            this.showError('Upload failed');
            uploadProgress.style.display = 'none';
            document.getElementById('uploadBtn').disabled = false;
        }
    }
    
    startMonitoring() {
        // Update metrics every 5 seconds
        this.monitoringInterval = setInterval(() => {
            this.updateStreamStats();
        }, 5000);
    }
    
    showLoading(show) {
        const loadingIndicator = document.getElementById('loadingIndicator');
        if (loadingIndicator) {
            // Only show loading if we're actually waiting and it's been requested
            if (show && !this.loadingTimeout) {
                loadingIndicator.style.display = 'flex';
            } else if (!show) {
                // Always hide when requested
                if (this.loadingTimeout) {
                    clearTimeout(this.loadingTimeout);
                    this.loadingTimeout = null;
                }
                loadingIndicator.style.display = 'none';
            }
        }
    }
    
    showStatsOverlay(show) {
        document.getElementById('statsOverlay').style.display = show ? 'block' : 'none';
    }
    
    showUploadModal() {
        const modal = new bootstrap.Modal(document.getElementById('uploadModal'));
        modal.show();
    }
    
    hideUploadModal() {
        const modal = bootstrap.Modal.getInstance(document.getElementById('uploadModal'));
        if (modal) modal.hide();
    }
    
    refreshVideoList() {
        this.loadVideoList();
    }
    
    handleVideoError(error) {
        console.error('Video error:', error);
        this.showError('Video playback error');
    }
    
    formatFileSize(bytes) {
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        if (bytes === 0) return '0 Bytes';
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
    }
    
    formatDuration(seconds) {
        const hrs = Math.floor(seconds / 3600);
        const mins = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);
        
        if (hrs > 0) {
            return `${hrs}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        }
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }
    
    showError(message) {
        // Simple error notification (you could use a toast library)
        alert(`Error: ${message}`);
    }
    
    showSuccess(message) {
        // Simple success notification (you could use a toast library)
        alert(`Success: ${message}`);
    }
}
