# 🌐 Frontend Dockerfile
# Optimized for development and production

FROM node:18-alpine as base

# Set working directory
WORKDIR /app

# Install dependencies for frontend development
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++

# Copy package files
COPY package*.json ./

# Install npm dependencies
RUN npm ci --only=production && npm cache clean --force

# Development stage
FROM base as development

# Install all dependencies (including dev)
RUN npm ci

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Development command with live reload
CMD ["npm", "run", "dev"]

# Production stage
FROM nginx:alpine as production

# Copy built assets
COPY --from=base /app .

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy source files
COPY . /usr/share/nginx/html

# Expose port
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
