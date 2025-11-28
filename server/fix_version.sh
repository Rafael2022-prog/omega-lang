#!/bin/bash
# Fix version display in API server

sed -i "s/let compilerVersion = 'unknown'/let compilerVersion = '1.3.0'/" /opt/omega-api/server.js

# Restart service
systemctl restart omega-api

# Verify
sleep 2
curl -s http://127.0.0.1:3000/api/info
