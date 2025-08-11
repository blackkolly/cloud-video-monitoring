# 🎥 Cloud Video Network Monitoring Platform
# Network Performance Configuration Templates

# AWS VPC Configuration for Video Streaming
resource "aws_vpc" "video_streaming_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "video-streaming-vpc"
    Environment = var.environment
    Purpose     = "video-network-monitoring"
  }
}

# Multi-AZ Subnets for High Availability
resource "aws_subnet" "video_streaming_public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.video_streaming_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "video-streaming-public-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_subnet" "video_streaming_private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.video_streaming_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "video-streaming-private-${count.index + 1}"
    Type = "private"
  }
}

# Internet Gateway for Public Access
resource "aws_internet_gateway" "video_streaming_igw" {
  vpc_id = aws_vpc.video_streaming_vpc.id

  tags = {
    Name = "video-streaming-igw"
  }
}

# NAT Gateways for Private Subnet Internet Access
resource "aws_eip" "nat_gateway_eip" {
  count = length(var.availability_zones)

  domain = "vpc"
  tags = {
    Name = "video-streaming-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "video_streaming_nat" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.video_streaming_public[count.index].id

  tags = {
    Name = "video-streaming-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.video_streaming_igw]
}

# Route Tables
resource "aws_route_table" "video_streaming_public" {
  vpc_id = aws_vpc.video_streaming_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.video_streaming_igw.id
  }

  tags = {
    Name = "video-streaming-public-rt"
  }
}

resource "aws_route_table" "video_streaming_private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.video_streaming_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.video_streaming_nat[count.index].id
  }

  tags = {
    Name = "video-streaming-private-rt-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "video_streaming_public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.video_streaming_public[count.index].id
  route_table_id = aws_route_table.video_streaming_public.id
}

resource "aws_route_table_association" "video_streaming_private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.video_streaming_private[count.index].id
  route_table_id = aws_route_table.video_streaming_private[count.index].id
}

# Security Groups for Video Streaming
resource "aws_security_group" "video_streaming_alb" {
  name        = "video-streaming-alb-sg"
  description = "Security group for video streaming ALB"
  vpc_id      = aws_vpc.video_streaming_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "video-streaming-alb-sg"
  }
}

resource "aws_security_group" "video_streaming_app" {
  name        = "video-streaming-app-sg"
  description = "Security group for video streaming applications"
  vpc_id      = aws_vpc.video_streaming_vpc.id

  # HTTP from ALB
  ingress {
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.video_streaming_alb.id
  }

  # RTMP for video streaming
  ingress {
    from_port   = 1935
    to_port     = 1935
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # WebRTC ports
  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10000
    to_port     = 20000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "video-streaming-app-sg"
  }
}

# CloudFront Distribution for Global Video Delivery
resource "aws_cloudfront_distribution" "video_streaming_cdn" {
  origin {
    domain_name = aws_lb.video_streaming_alb.dns_name
    origin_id   = "video-streaming-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Video streaming CDN distribution"
  default_root_object = "index.html"

  # Cache behaviors for different content types
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "video-streaming-origin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }
  }

  # Cache behavior for video content
  ordered_cache_behavior {
    path_pattern           = "/videos/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "video-streaming-origin"
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Range"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  # Cache behavior for HLS/DASH manifests
  ordered_cache_behavior {
    path_pattern           = "*.m3u8"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "video-streaming-origin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 5
    max_ttl     = 30
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Price class
  price_class = var.cloudfront_price_class

  tags = {
    Environment = var.environment
    Purpose     = "video-streaming"
  }
}

# Application Load Balancer
resource "aws_lb" "video_streaming_alb" {
  name               = "video-streaming-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.video_streaming_alb.id]
  subnets            = aws_subnet.video_streaming_public[*].id

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Purpose     = "video-streaming"
  }
}

# Network Load Balancer for UDP traffic (WebRTC)
resource "aws_lb" "video_streaming_nlb" {
  name               = "video-streaming-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.video_streaming_public[*].id

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Purpose     = "video-streaming-webrtc"
  }
}

# VPC Flow Logs for Network Monitoring
resource "aws_flow_log" "video_streaming_vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.video_streaming_vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30
}

resource "aws_iam_role" "flow_log" {
  name = "flowlogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log" {
  name = "flowlogsDeliveryRolePolicy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ElastiCache for Redis (Session Storage & Caching)
resource "aws_elasticache_subnet_group" "video_streaming_cache" {
  name       = "video-streaming-cache-subnet"
  subnet_ids = aws_subnet.video_streaming_private[*].id
}

resource "aws_security_group" "video_streaming_cache" {
  name        = "video-streaming-cache-sg"
  description = "Security group for video streaming cache"
  vpc_id      = aws_vpc.video_streaming_vpc.id

  ingress {
    from_port                = 6379
    to_port                  = 6379
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.video_streaming_app.id
  }

  tags = {
    Name = "video-streaming-cache-sg"
  }
}

resource "aws_elasticache_replication_group" "video_streaming_redis" {
  description          = "Redis cluster for video streaming"
  replication_group_id = "video-streaming-redis"
  
  node_type            = "cache.r6g.large"
  port                 = 6379
  parameter_group_name = "default.redis7"
  
  num_cache_clusters = 2
  
  subnet_group_name  = aws_elasticache_subnet_group.video_streaming_cache.name
  security_group_ids = [aws_security_group.video_streaming_cache.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = {
    Environment = var.environment
    Purpose     = "video-streaming-cache"
  }
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_All"
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.video_streaming_vpc.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.video_streaming_cdn.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.video_streaming_cdn.domain_name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.video_streaming_alb.dns_name
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_replication_group.video_streaming_redis.configuration_endpoint_address
}
