#!/bin/bash
# Deploy OMEGA API Server

set -e

echo "=== OMEGA API Server Deployment ==="

# Create directories
mkdir -p /opt/omega-api
mkdir -p /opt/omega
mkdir -p /tmp/omega-compile

# Copy files
cp /tmp/omega-deploy/server.js /opt/omega-api/
cp /tmp/omega-deploy/package.json /opt/omega-api/

# Install dependencies
cd /opt/omega-api
npm install --production

# Set permissions
chown -R nginx:nginx /opt/omega-api
chown -R nginx:nginx /tmp/omega-compile
chmod 755 /opt/omega-api

# Install systemd service
cp /tmp/omega-deploy/omega-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable omega-api
systemctl restart omega-api

# Check status
sleep 2
systemctl status omega-api --no-pager

echo ""
echo "=== Testing API ==="
curl -s http://127.0.0.1:3000/api/health | head -20

echo ""
echo "=== Deployment Complete ==="
