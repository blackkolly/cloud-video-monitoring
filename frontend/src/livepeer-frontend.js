/**
 * 🔑 Livepeer Frontend Integration
 * API Key: 40d145e9-4cae-4913-89a2-fcd1c4fa3bfb
 */

class LivepeerFrontend {
    constructor() {
        this.apiKey = '40d145e9-4cae-4913-89a2-fcd1c4fa3bfb';
        this.gatewayUrl = 'https://livepeer.studio/api';
        this.playbackUrl = 'https://lp-playback.studio';
        this.streams = new Map();
        this.isConnected = false;
        
        this.init();
    }
    
    init() {
        console.log('🔑 Livepeer Frontend initialized with API key');
        this.validateConnection();
    }
    
    /**
     * Get API headers with authentication
     */
    getHeaders() {
        return {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json'
        };
    }
    
    /**
     * Validate connection to Livepeer API
     */
    async validateConnection() {
        try {
            const response = await fetch(`${this.gatewayUrl}/stream`, {
                method: 'GET',
                headers: this.getHeaders()
            });
            
            if (response.ok) {
                this.isConnected = true;
                console.log('✅ Livepeer API connection validated');
                this.updateConnectionStatus(true);
                
                // Load existing streams
                const streams = await response.json();
                console.log(`📺 Found ${streams.length} existing streams`);
                
                return true;
            } else {
                console.error('❌ Livepeer API connection failed:', response.status);
                this.updateConnectionStatus(false);
                return false;
            }
        } catch (error) {
            console.error('❌ Livepeer connection error:', error);
            this.updateConnectionStatus(false);
            return false;
        }
    }
    
    /**
     * Update connection status in UI
     */
    updateConnectionStatus(connected) {
        this.isConnected = connected;
        
        // Create or update status indicator
        let statusElement = document.getElementById('livepeerStatus');
        if (!statusElement) {
            statusElement = document.createElement('div');
            statusElement.id = 'livepeerStatus';
            statusElement.className = 'alert mb-3';
            
            // Insert into dashboard
            const container = document.querySelector('.col-lg-8');
            if (container) {
                container.insertBefore(statusElement, container.firstChild);
            }
        }
        
        if (connected) {
            statusElement.className = 'alert alert-success mb-3';
            statusElement.innerHTML = `
                <div class="d-flex align-items-center">
                    <div class="spinner-grow spinner-grow-sm text-success me-2" role="status" aria-hidden="true"></div>
                    <strong>🚀 Livepeer Connected</strong>
                    <span class="ms-auto">
                        <small class="text-muted">API Key: ${this.apiKey.substring(0, 8)}...</small>
                    </span>
                </div>
                <small class="text-muted d-block mt-1">
                    Ready for cost-optimized video streaming (50-90% savings)
                </small>
            `;
        } else {
            statusElement.className = 'alert alert-warning mb-3';
            statusElement.innerHTML = `
                <div class="d-flex align-items-center">
                    <strong>⚠️ Livepeer Disconnected</strong>
                    <button class="btn btn-sm btn-outline-warning ms-auto" onclick="livepeerFrontend.validateConnection()">
                        Retry Connection
                    </button>
                </div>
                <small class="text-muted d-block mt-1">
                    Using fallback streaming (higher costs)
                </small>
            `;
        }
    }
    
    /**
     * Create new live stream
     */
    async createStream(name, quality = 'medium') {
        if (!this.isConnected) {
            console.warn('⚠️ Livepeer not connected, cannot create stream');
            return null;
        }
        
        const profiles = this.getTranscodingProfiles();
        const selectedProfile = profiles[quality] || profiles.medium;
        
        const streamData = {
            name: name,
            profiles: [selectedProfile]
        };
        
        try {
            const response = await fetch(`${this.gatewayUrl}/stream`, {
                method: 'POST',
                headers: this.getHeaders(),
                body: JSON.stringify(streamData)
            });
            
            if (response.ok) {
                const stream = await response.json();
                this.streams.set(stream.id, stream);
                
                console.log(`✅ Stream created: ${stream.name} (${stream.id})`);
                this.addStreamToUI(stream);
                
                return stream;
            } else {
                console.error('❌ Failed to create stream:', response.status);
                return null;
            }
        } catch (error) {
            console.error('❌ Stream creation error:', error);
            return null;
        }
    }
    
    /**
     * Get transcoding profiles
     */
    getTranscodingProfiles() {
        return {
            low: {
                name: "Low Quality (360p)",
                bitrate: 500000,
                fps: 30,
                width: 640,
                height: 360,
                profile: "H264ConstrainedHigh"
            },
            medium: {
                name: "Medium Quality (720p)",
                bitrate: 1500000,
                fps: 30,
                width: 1280,
                height: 720,
                profile: "H264ConstrainedHigh"
            },
            high: {
                name: "High Quality (1080p)",
                bitrate: 4000000,
                fps: 60,
                width: 1920,
                height: 1080,
                profile: "H264ConstrainedHigh"
            },
            ultra: {
                name: "Ultra Quality (4K)",
                bitrate: 8000000,
                fps: 60,
                width: 3840,
                height: 2160,
                profile: "H264ConstrainedHigh"
            }
        };
    }
    
    /**
     * Add stream to UI
     */
    addStreamToUI(stream) {
        // Create streams container if it doesn't exist
        let streamsContainer = document.getElementById('livepeerStreams');
        if (!streamsContainer) {
            streamsContainer = document.createElement('div');
            streamsContainer.id = 'livepeerStreams';
            streamsContainer.className = 'card mb-3';
            streamsContainer.innerHTML = `
                <div class="card-header">
                    <h6 class="mb-0">📡 Livepeer Streams</h6>
                </div>
                <div class="card-body">
                    <div id="streamsList"></div>
                    <button class="btn btn-primary btn-sm mt-2" onclick="livepeerFrontend.showCreateStreamModal()">
                        + Create New Stream
                    </button>
                </div>
            `;
            
            const container = document.querySelector('.col-lg-4');
            if (container) {
                container.appendChild(streamsContainer);
            }
        }
        
        const streamsList = document.getElementById('streamsList');
        if (streamsList) {
            const streamElement = document.createElement('div');
            streamElement.className = 'border rounded p-2 mb-2';
            streamElement.innerHTML = `
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <strong>${stream.name}</strong><br>
                        <small class="text-muted">${stream.id}</small>
                    </div>
                    <div>
                        <span class="badge ${stream.isActive ? 'bg-success' : 'bg-secondary'}">
                            ${stream.isActive ? 'Live' : 'Inactive'}
                        </span>
                    </div>
                </div>
                <div class="mt-1">
                    <small class="text-muted">
                        RTMP: <code>${stream.rtmpIngestUrl || 'N/A'}</code>
                    </small>
                </div>
                <div class="btn-group btn-group-sm mt-2" role="group">
                    <button class="btn btn-outline-primary" onclick="livepeerFrontend.copyStreamUrl('${stream.id}')">
                        📋 Copy URL
                    </button>
                    <button class="btn btn-outline-success" onclick="livepeerFrontend.startStream('${stream.id}')">
                        ▶️ Start
                    </button>
                    <button class="btn btn-outline-danger" onclick="livepeerFrontend.stopStream('${stream.id}')">
                        ⏹️ Stop
                    </button>
                </div>
            `;
            
            streamsList.appendChild(streamElement);
        }
    }
    
    /**
     * Show create stream modal
     */
    showCreateStreamModal() {
        const modal = document.createElement('div');
        modal.className = 'modal fade';
        modal.id = 'createStreamModal';
        modal.innerHTML = `
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">🎥 Create Livepeer Stream</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <form id="createStreamForm">
                            <div class="mb-3">
                                <label for="streamName" class="form-label">Stream Name</label>
                                <input type="text" class="form-control" id="streamName" required>
                            </div>
                            <div class="mb-3">
                                <label for="streamQuality" class="form-label">Quality Profile</label>
                                <select class="form-select" id="streamQuality">
                                    <option value="low">Low (360p) - $0.01/min</option>
                                    <option value="medium" selected>Medium (720p) - $0.02/min</option>
                                    <option value="high">High (1080p) - $0.04/min</option>
                                    <option value="ultra">Ultra (4K) - $0.08/min</option>
                                </select>
                            </div>
                            <div class="alert alert-info">
                                <small>
                                    💰 <strong>Cost Savings:</strong> Livepeer costs 50-90% less than traditional CDNs
                                </small>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="button" class="btn btn-primary" onclick="livepeerFrontend.submitCreateStream()">
                            Create Stream
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        const modalInstance = new bootstrap.Modal(modal);
        modalInstance.show();
        
        // Remove modal when hidden
        modal.addEventListener('hidden.bs.modal', () => {
            document.body.removeChild(modal);
        });
    }
    
    /**
     * Submit create stream form
     */
    async submitCreateStream() {
        const name = document.getElementById('streamName').value;
        const quality = document.getElementById('streamQuality').value;
        
        if (name) {
            const stream = await this.createStream(name, quality);
            if (stream) {
                const modal = bootstrap.Modal.getInstance(document.getElementById('createStreamModal'));
                modal.hide();
                
                // Show success notification
                this.showNotification('✅ Stream created successfully!', 'success');
            } else {
                this.showNotification('❌ Failed to create stream', 'error');
            }
        }
    }
    
    /**
     * Copy stream URL to clipboard
     */
    async copyStreamUrl(streamId) {
        const stream = this.streams.get(streamId);
        if (stream && stream.rtmpIngestUrl) {
            try {
                await navigator.clipboard.writeText(stream.rtmpIngestUrl);
                this.showNotification('📋 Stream URL copied to clipboard', 'success');
            } catch (error) {
                console.error('Failed to copy URL:', error);
                this.showNotification('❌ Failed to copy URL', 'error');
            }
        }
    }
    
    /**
     * Start stream
     */
    async startStream(streamId) {
        try {
            const response = await fetch(`${this.gatewayUrl}/stream/${streamId}/start`, {
                method: 'PATCH',
                headers: this.getHeaders()
            });
            
            if (response.ok) {
                this.showNotification('▶️ Stream started', 'success');
                // Refresh stream status
                this.refreshStreamStatus(streamId);
            } else {
                this.showNotification('❌ Failed to start stream', 'error');
            }
        } catch (error) {
            console.error('Start stream error:', error);
            this.showNotification('❌ Error starting stream', 'error');
        }
    }
    
    /**
     * Stop stream
     */
    async stopStream(streamId) {
        try {
            const response = await fetch(`${this.gatewayUrl}/stream/${streamId}/stop`, {
                method: 'PATCH',
                headers: this.getHeaders()
            });
            
            if (response.ok) {
                this.showNotification('⏹️ Stream stopped', 'success');
                // Refresh stream status
                this.refreshStreamStatus(streamId);
            } else {
                this.showNotification('❌ Failed to stop stream', 'error');
            }
        } catch (error) {
            console.error('Stop stream error:', error);
            this.showNotification('❌ Error stopping stream', 'error');
        }
    }
    
    /**
     * Refresh stream status
     */
    async refreshStreamStatus(streamId) {
        try {
            const response = await fetch(`${this.gatewayUrl}/stream/${streamId}`, {
                method: 'GET',
                headers: this.getHeaders()
            });
            
            if (response.ok) {
                const stream = await response.json();
                this.streams.set(streamId, stream);
                // Update UI would go here
            }
        } catch (error) {
            console.error('Refresh stream error:', error);
        }
    }
    
    /**
     * Show notification
     */
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `alert alert-${type === 'error' ? 'danger' : type} alert-dismissible fade show position-fixed`;
        notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
        notification.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        document.body.appendChild(notification);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
    }
    
    /**
     * Get cost analysis
     */
    getCostAnalysis() {
        return {
            livepeer: {
                transcoding: '$0.01-0.08 per minute',
                storage: '$0.01 per GB/month',
                delivery: '$0.01 per GB',
                total_savings: '50-90% vs traditional CDN'
            },
            traditional: {
                transcoding: '$0.05-0.40 per minute',
                storage: '$0.10 per GB/month', 
                delivery: '$0.10 per GB',
                total_cost: '5-10x more expensive'
            },
            recommendation: 'Use Livepeer for massive cost savings while maintaining quality'
        };
    }
}

// Initialize Livepeer frontend
const livepeerFrontend = new LivepeerFrontend();

// Make globally available
window.LivepeerFrontend = livepeerFrontend;

console.log('🔑 Livepeer Frontend loaded with API key: 40d145e9-4cae-4913-89a2-fcd1c4fa3bfb');
