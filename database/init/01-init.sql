# 🚀 Database Initialization Script
# SQL script to initialize the database with proper schema and data

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE cloud_video_monitoring'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'cloud_video_monitoring');

-- Connect to the database
\c cloud_video_monitoring;

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable row level security
ALTER DATABASE cloud_video_monitoring SET row_security = on;

-- Create custom types
CREATE TYPE video_status AS ENUM ('processing', 'ready', 'failed', 'deleted');
CREATE TYPE session_type AS ENUM ('user', 'system', 'api', 'livepeer');
CREATE TYPE stream_status AS ENUM ('active', 'paused', 'ended', 'error');

-- Insert initial configuration data
INSERT INTO system_config (key, value, description) VALUES
('livepeer_api_key', '40d145e9-4cae-4913-89a2-fcd1c4fa3bfb', 'Livepeer API key for video streaming'),
('max_video_size_mb', '500', 'Maximum video file size in MB'),
('supported_formats', 'mp4,webm,avi,mov', 'Supported video formats'),
('default_quality', '720p', 'Default video quality'),
('enable_livepeer', 'true', 'Enable Livepeer integration'),
('analytics_retention_days', '90', 'How long to keep analytics data'),
('platform_name', 'Cloud Video Network Monitoring', 'Platform name'),
('version', '1.0.0', 'Platform version')
ON CONFLICT (key) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_videos_owner_status ON videos(owner_id, status);
CREATE INDEX IF NOT EXISTS idx_sessions_type_active ON sessions(session_type, is_active);
CREATE INDEX IF NOT EXISTS idx_stream_sessions_video_started ON stream_sessions(video_id, started_at);
CREATE INDEX IF NOT EXISTS idx_session_events_session_type ON session_events(session_id, event_type);
CREATE INDEX IF NOT EXISTS idx_stream_events_session_type ON stream_events(stream_session_id, event_type);

-- Create a view for active sessions
CREATE OR REPLACE VIEW active_sessions AS
SELECT 
    s.*,
    u.username,
    u.email,
    COUNT(se.id) as event_count
FROM sessions s
LEFT JOIN users u ON s.user_id = u.id
LEFT JOIN session_events se ON s.id = se.session_id
WHERE s.is_active = true
GROUP BY s.id, u.username, u.email;

-- Create a view for video analytics
CREATE OR REPLACE VIEW video_stats AS
SELECT 
    v.id,
    v.title,
    v.status,
    v.use_livepeer,
    COUNT(DISTINCT ss.id) as total_views,
    AVG(ss.duration) as avg_watch_time,
    SUM(ss.bandwidth_used) as total_bandwidth,
    MAX(ss.started_at) as last_viewed
FROM videos v
LEFT JOIN stream_sessions ss ON v.id = ss.video_id
GROUP BY v.id, v.title, v.status, v.use_livepeer;

-- Create function to cleanup old data
CREATE OR REPLACE FUNCTION cleanup_old_data(retention_days INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    cutoff_date TIMESTAMP;
BEGIN
    cutoff_date := NOW() - INTERVAL '%d days' USING retention_days;
    
    -- Delete old session events
    DELETE FROM session_events WHERE timestamp < cutoff_date;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Delete old stream events
    DELETE FROM stream_events WHERE timestamp < cutoff_date;
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    -- Delete old inactive sessions
    DELETE FROM sessions 
    WHERE is_active = false 
    AND last_activity < cutoff_date 
    AND session_type != 'livepeer';
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to update session activity
CREATE OR REPLACE FUNCTION update_session_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE sessions 
    SET last_activity = NOW() 
    WHERE id = NEW.session_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update session activity
CREATE TRIGGER trigger_update_session_activity
    AFTER INSERT ON session_events
    FOR EACH ROW
    EXECUTE FUNCTION update_session_activity();

-- Initialize Livepeer integration record
INSERT INTO livepeer_integration (api_key) VALUES ('40d145e9-4cae-4913-89a2-fcd1c4fa3bfb')
ON CONFLICT (api_key) DO NOTHING;

-- Create admin user (password: admin123 - hashed)
INSERT INTO users (username, email, password_hash, subscription_tier) VALUES 
('admin', 'admin@cloudvideo.com', 'ef2d127de37b942baad06145e54b0c619a1f22327b2ebbcfbec78f5564afe39d', 'enterprise')
ON CONFLICT (email) DO NOTHING;

-- Log successful initialization
INSERT INTO system_config (key, value, description) VALUES 
('database_initialized', NOW()::text, 'Database initialization timestamp'),
('livepeer_configured', 'true', 'Livepeer API key configured')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
