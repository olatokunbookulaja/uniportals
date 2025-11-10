# Deployment Guide

## Overview

This guide provides instructions for deploying UniPortals in various environments: development, staging, and production.

## Prerequisites

### System Requirements

**Minimum (Development)**
- 4 CPU cores
- 8GB RAM
- 50GB disk space
- Ubuntu 20.04+ or similar Linux distribution

**Recommended (Production)**
- 8+ CPU cores
- 16GB+ RAM
- 200GB+ SSD storage
- Load balancer
- CDN service

### Software Requirements

- Docker 20.10+
- Docker Compose 1.29+
- Node.js 16+ (for local development)
- PostgreSQL 13+
- Redis 6+
- Nginx 1.18+

## Environment Configuration

### 1. Environment Variables

Create `.env` file in the project root:

```bash
# Application
NODE_ENV=production
APP_NAME=UniPortals
APP_URL=https://uniportals.ng
API_URL=https://api.uniportals.ng
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/uniportals
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=your_redis_password

# JWT Authentication
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRY=24h
JWT_REFRESH_EXPIRY=7d

# Session
SESSION_SECRET=your-session-secret-key
SESSION_MAX_AGE=86400000

# JAMB Integration
JAMB_API_URL=https://api.jamb.gov.ng
JAMB_CLIENT_ID=your_jamb_client_id
JAMB_CLIENT_SECRET=your_jamb_client_secret
JAMB_INSTITUTION_CODE=0109

# Payment Gateways
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxxx
FLUTTERWAVE_SECRET_KEY=FLWSECK-xxxxxxxxxxxxx
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK-xxxxxxxxxxxxx
REMITA_API_KEY=your_remita_api_key
REMITA_MERCHANT_ID=your_merchant_id

# SMS Gateway
SMS_PROVIDER=africas_talking
SMS_API_KEY=your_sms_api_key
SMS_USERNAME=sandbox

# Email Service
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=noreply@uniportals.ng
SMTP_PASSWORD=your_email_password
EMAIL_FROM=UniPortals <noreply@uniportals.ng>

# File Storage
STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=uniportals-documents

# Monitoring & Logging
LOG_LEVEL=info
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx

# Security
CORS_ORIGIN=https://uniportals.ng,https://www.uniportals.ng
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX=100

# University Configuration
UNIVERSITY_ID=uuid-here
UNIVERSITY_NAME=University of Lagos
UNIVERSITY_CODE=UNILAG
```

## Deployment Options

### Option 1: Docker Compose (Recommended for Small to Medium Scale)

#### 1. Create Docker Compose File

```yaml
# docker-compose.yml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:13-alpine
    container_name: uniportals_db
    environment:
      POSTGRES_DB: uniportals
      POSTGRES_USER: uniportals_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/schemas/schema.sql:/docker-entrypoint-initdb.d/schema.sql
    ports:
      - "5432:5432"
    networks:
      - uniportals_network
    restart: unless-stopped

  # Redis Cache
  redis:
    image: redis:6-alpine
    container_name: uniportals_redis
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - uniportals_network
    restart: unless-stopped

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: uniportals_backend
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://uniportals_user:${DB_PASSWORD}@postgres:5432/uniportals
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
    env_file:
      - .env
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    networks:
      - uniportals_network
    restart: unless-stopped
    volumes:
      - ./backend/logs:/app/logs

  # Frontend - Student Portal
  student_portal:
    build:
      context: ./frontend/student-portal
      dockerfile: Dockerfile
    container_name: uniportals_student_portal
    ports:
      - "3001:80"
    networks:
      - uniportals_network
    restart: unless-stopped

  # Frontend - Admissions Portal
  admissions_portal:
    build:
      context: ./frontend/admissions-portal
      dockerfile: Dockerfile
    container_name: uniportals_admissions_portal
    ports:
      - "3002:80"
    networks:
      - uniportals_network
    restart: unless-stopped

  # Frontend - Admin Dashboard
  admin_portal:
    build:
      context: ./frontend/admin-portal
      dockerfile: Dockerfile
    container_name: uniportals_admin_portal
    ports:
      - "3003:80"
    networks:
      - uniportals_network
    restart: unless-stopped

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: uniportals_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./infrastructure/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./infrastructure/nginx/ssl:/etc/nginx/ssl
    depends_on:
      - backend
      - student_portal
      - admissions_portal
      - admin_portal
    networks:
      - uniportals_network
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

networks:
  uniportals_network:
    driver: bridge
```

#### 2. Deploy with Docker Compose

```bash
# Clone repository
git clone https://github.com/olatokunbookulaja/uniportals.git
cd uniportals

# Create and configure .env file
cp .env.example .env
nano .env  # Edit with your values

# Build and start services
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop services
docker-compose down

# Update and restart
git pull
docker-compose up -d --build
```

### Option 2: Kubernetes (Production Scale)

#### 1. Create Kubernetes Manifests

```yaml
# infrastructure/kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: uniportals

---
# infrastructure/kubernetes/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: uniportals-config
  namespace: uniportals
data:
  NODE_ENV: "production"
  APP_NAME: "UniPortals"
  DATABASE_POOL_MIN: "2"
  DATABASE_POOL_MAX: "10"

---
# infrastructure/kubernetes/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: uniportals-secrets
  namespace: uniportals
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:password@postgres:5432/uniportals"
  JWT_SECRET: "your-jwt-secret"
  REDIS_PASSWORD: "your-redis-password"

---
# infrastructure/kubernetes/postgres-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: uniportals
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: uniportals
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: uniportals-secrets
              key: DB_PASSWORD
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
# infrastructure/kubernetes/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: uniportals
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: uniportals/backend:latest
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: uniportals-config
        - secretRef:
            name: uniportals-secrets
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

---
# infrastructure/kubernetes/backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: uniportals
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP

---
# infrastructure/kubernetes/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: uniportals-ingress
  namespace: uniportals
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - uniportals.ng
    - api.uniportals.ng
    secretName: uniportals-tls
  rules:
  - host: api.uniportals.ng
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
  - host: uniportals.ng
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80

---
# infrastructure/kubernetes/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: uniportals
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

#### 2. Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f infrastructure/kubernetes/

# Check deployments
kubectl get deployments -n uniportals

# Check pods
kubectl get pods -n uniportals

# Check services
kubectl get services -n uniportals

# View logs
kubectl logs -f deployment/backend -n uniportals

# Scale deployment
kubectl scale deployment backend --replicas=5 -n uniportals
```

## Nginx Configuration

```nginx
# infrastructure/nginx/nginx.conf

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;

    # API Backend
    upstream backend_api {
        server backend:3000;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name uniportals.ng www.uniportals.ng api.uniportals.ng;
        return 301 https://$server_name$request_uri;
    }

    # API Server
    server {
        listen 443 ssl http2;
        server_name api.uniportals.ng;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            limit_req zone=api_limit burst=20 nodelay;
            
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        location /auth/login {
            limit_req zone=login_limit burst=5 nodelay;
            proxy_pass http://backend_api;
        }
    }

    # Student Portal
    server {
        listen 443 ssl http2;
        server_name uniportals.ng www.uniportals.ng;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Admissions Portal
    server {
        listen 443 ssl http2;
        server_name admissions.uniportals.ng;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        root /usr/share/nginx/html/admissions;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }

    # Admin Portal
    server {
        listen 443 ssl http2;
        server_name admin.uniportals.ng;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        root /usr/share/nginx/html/admin;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
```

## Database Migration

```bash
# Run migrations
docker-compose exec backend npm run migrate

# Or if using direct PostgreSQL
psql -U uniportals_user -d uniportals -f database/schemas/schema.sql
```

## SSL/TLS Configuration

### Using Let's Encrypt (Certbot)

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d uniportals.ng -d www.uniportals.ng -d api.uniportals.ng

# Auto-renewal (add to cron)
0 0 * * * certbot renew --quiet
```

## Monitoring Setup

### 1. Application Monitoring

```bash
# Add Prometheus monitoring
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

### 2. Health Checks

```typescript
// Backend health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/ready', async (req, res) => {
  try {
    await database.ping();
    await redis.ping();
    res.json({ status: 'ready' });
  } catch (error) {
    res.status(503).json({ status: 'not ready' });
  }
});
```

## Backup Strategy

```bash
# Database backup script
#!/bin/bash
BACKUP_DIR="/backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/uniportals_$TIMESTAMP.sql"

# Create backup
docker-compose exec -T postgres pg_dump -U uniportals_user uniportals > $BACKUP_FILE

# Compress
gzip $BACKUP_FILE

# Upload to S3
aws s3 cp $BACKUP_FILE.gz s3://uniportals-backups/

# Keep only last 30 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check database status
   docker-compose logs postgres
   
   # Verify connection
   docker-compose exec postgres psql -U uniportals_user -d uniportals
   ```

2. **Redis Connection Failed**
   ```bash
   # Check Redis
   docker-compose exec redis redis-cli ping
   ```

3. **High Memory Usage**
   ```bash
   # Check container stats
   docker stats
   
   # Adjust memory limits in docker-compose.yml
   ```

4. **SSL Certificate Issues**
   ```bash
   # Test certificate
   openssl s_client -connect uniportals.ng:443
   ```

## Performance Optimization

1. **Enable Redis Caching**
2. **Configure CDN for static assets**
3. **Enable Gzip compression**
4. **Optimize database queries**
5. **Use connection pooling**
6. **Enable HTTP/2**

## Security Checklist

- [ ] Change all default passwords
- [ ] Configure firewall rules
- [ ] Enable SSL/TLS
- [ ] Set up fail2ban
- [ ] Configure rate limiting
- [ ] Enable security headers
- [ ] Set up monitoring and alerts
- [ ] Regular security updates
- [ ] Database encryption
- [ ] Backup encryption

## Maintenance

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade

# Update Docker images
docker-compose pull
docker-compose up -d

# Clean up old images
docker system prune -a

# Restart services
docker-compose restart
```

---

For support, contact: devops@uniportals.ng
