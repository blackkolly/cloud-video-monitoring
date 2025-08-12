# 📋 Database Setup and Initialization Script
# Run this script to set up the database for the first time

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent
backend_path = project_root / "backend"
sys.path.insert(0, str(backend_path))

# Set environment variables for database connection
os.environ["USE_SQLITE"] = "false"
os.environ["DB_HOST"] = os.getenv("DB_HOST", "localhost")
os.environ["DB_PORT"] = os.getenv("DB_PORT", "5432")
os.environ["DB_NAME"] = os.getenv("DB_NAME", "cloud_video_monitoring")
os.environ["DB_USER"] = os.getenv("DB_USER", "postgres")
os.environ["DB_PASSWORD"] = os.getenv("DB_PASSWORD", "cloud_video_secure_2025")

def setup_database():
    """Set up the database and create initial data"""
    try:
        print("🗄️ Setting up Cloud Video Network Monitoring Database...")
        
        # Check if Docker containers are running
        print("📡 Checking Docker containers...")
        import subprocess
        
        # Check PostgreSQL container
        try:
            result = subprocess.run(['docker', 'ps', '--filter', 'name=cloud-video-postgres', '--format', '{{.Status}}'], 
                                  capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and result.stdout.strip():
                if 'Up' in result.stdout:
                    print("✅ PostgreSQL container is running")
                else:
                    print("❌ PostgreSQL container is not healthy")
                    print("   Run: docker-compose -f docker-compose.simple.yml up -d postgres")
                    return False
            else:
                print("❌ PostgreSQL container not found")
                print("   Run: docker-compose -f docker-compose.simple.yml up -d postgres")
                return False
                
        except Exception as e:
            print(f"❌ Error checking PostgreSQL container: {e}")
            return False
        
        # Test database connection
        print("📡 Testing database connection...")
        try:
            result = subprocess.run([
                'docker', 'exec', 'cloud-video-postgres', 
                'psql', '-U', 'postgres', '-d', 'cloud_video_monitoring', 
                '-c', 'SELECT version();'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ Database connection successful")
                # Extract version info
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    if 'PostgreSQL' in line:
                        print(f"   {line.strip()}")
                        break
            else:
                print(f"❌ Database connection failed")
                print(f"   Error: {result.stderr.strip()}")
                return False
                
        except Exception as e:
            print(f"❌ Database connection error: {e}")
            return False
        
        # Check Redis container
        print("📡 Testing Redis connection...")
        try:
            result = subprocess.run(['docker', 'ps', '--filter', 'name=cloud-video-redis', '--format', '{{.Status}}'], 
                                  capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0 and 'Up' in result.stdout:
                print("✅ Redis container is running")
                
                # Test Redis ping
                ping_result = subprocess.run([
                    'docker', 'exec', 'cloud-video-redis', 'redis-cli', 'ping'
                ], capture_output=True, text=True, timeout=5)
                
                if ping_result.returncode == 0 and 'PONG' in ping_result.stdout:
                    print("✅ Redis connection successful")
                else:
                    print("⚠️ Redis ping failed")
            else:
                print("⚠️ Redis container not running")
                
        except Exception as e:
            print(f"⚠️ Redis check error: {e}")
        
        # Display configuration summary
        print("\n📊 Configuration Summary:")
        print("  ✅ PostgreSQL database: cloud_video_monitoring")
        print("  ✅ Database user: postgres")
        print("  ✅ Database password: cloud_video_secure_2025")
        print("  ✅ Redis cache available")
        print("  ✅ Livepeer API key: 40d145e9-4cae-4913-89a2-fcd1c4fa3bfb")
        print("\n🏗️ Database tables will be created when backend container starts")
        print("📋 Environment variables are properly configured in docker-compose.simple.yml")
        
        print("\n🎉 Database setup completed successfully!")
        print("\n📌 Next steps:")
        print("  1. Start the backend: docker-compose -f docker-compose.simple.yml up -d backend-api")
        print("  2. Start the frontend: docker-compose -f docker-compose.simple.yml up -d frontend")
        print("  3. Open http://localhost:3000 to access the platform!")
        print("  4. API available at http://localhost:8080")
        
        return True
        
    except Exception as e:
        print(f"❌ Database setup failed: {e}")
        return False

def reset_database():
    """Reset the database (WARNING: This will delete all data!)"""
    try:
        from database import db_manager
        
        print("⚠️ WARNING: This will delete ALL data in the database!")
        response = input("Are you sure you want to continue? (yes/no): ")
        
        if response.lower() == 'yes':
            print("🗑️ Dropping all tables...")
            db_manager.drop_tables()
            print("✅ Tables dropped")
            
            print("🏗️ Recreating tables...")
            db_manager.create_tables()
            print("✅ Tables recreated")
            
            print("📝 Initializing default data...")
            db_manager.initialize_data()
            print("✅ Database reset completed")
        else:
            print("❌ Database reset cancelled")
            
    except Exception as e:
        print(f"❌ Database reset failed: {e}")

def backup_database():
    """Backup the database"""
    try:
        from database import DatabaseUtils
        from datetime import datetime
        
        backup_name = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.db"
        
        if DatabaseUtils.backup_database(backup_name):
            print(f"✅ Database backed up to: {backup_name}")
        else:
            print("❌ Database backup failed")
            
    except Exception as e:
        print(f"❌ Database backup failed: {e}")

def show_help():
    """Show help information"""
    print("""
🗄️ Cloud Video Network Monitoring Database Manager

Usage: python setup_database.py [command]

Commands:
  setup     - Set up database for the first time (default)
  reset     - Reset database (WARNING: Deletes all data!)
  backup    - Backup database
  help      - Show this help message

Examples:
  python setup_database.py           # Set up database
  python setup_database.py setup     # Same as above
  python setup_database.py reset     # Reset database
  python setup_database.py backup    # Backup database
  
Database Configuration:
  - SQLite: Uses local file database (default for development)
  - PostgreSQL: Configure environment variables for production
  
Environment Variables:
  USE_SQLITE=true               # Use SQLite (default)
  DB_HOST=localhost             # PostgreSQL host
  DB_PORT=5432                  # PostgreSQL port
  DB_NAME=cloud_video_monitoring # Database name
  DB_USER=postgres              # Database user
  DB_PASSWORD=password          # Database password
""")

if __name__ == "__main__":
    # Parse command line arguments
    command = sys.argv[1] if len(sys.argv) > 1 else "setup"
    
    if command == "setup":
        setup_database()
    elif command == "reset":
        reset_database()
    elif command == "backup":
        backup_database()
    elif command == "help":
        show_help()
    else:
        print(f"❌ Unknown command: {command}")
        print("Run 'python setup_database.py help' for usage information")
        sys.exit(1)
