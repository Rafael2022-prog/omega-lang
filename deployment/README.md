# OMEGA Deployment Guide

## ⚠️ SECURITY WARNING

**NEVER commit files containing sensitive information to the repository!**

This directory contains template files for server deployment. Before using:

1. **Copy template files** to a secure location outside the repository
2. **Replace all placeholders** with actual values
3. **Keep sensitive files private** - never commit them to version control

## Template Files

### `server-setup.template.ps1`
Template for PowerShell server setup script.

**Placeholders to replace:**
- `YOUR_SERVER_IP_HERE` → Your actual server IP address
- `YOUR_USERNAME_HERE` → Your server username  
- `YOUR_PASSWORD_HERE` → Your server password
- `YOUR_DOMAIN_HERE` → Your domain name

### `nginx.template.conf`
Template for Nginx web server configuration.

**Placeholders to replace:**
- `YOUR_DOMAIN_HERE` → Your domain name (e.g., `example.com`)

## Safe Deployment Process

1. **Copy templates to secure location:**
   ```bash
   cp deployment/*.template.* ~/private-config/
   ```

2. **Edit copied files with real values:**
   ```bash
   # Edit the copied files, NOT the templates!
   nano ~/private-config/server-setup.ps1
   nano ~/private-config/nginx.conf
   ```

3. **Use the configured files:**
   ```bash
   # Run from your private config directory
   cd ~/private-config
   ./server-setup.ps1
   ```

4. **Never commit the configured files:**
   ```bash
   # These should NEVER be in your repository:
   # ❌ server-setup.ps1 (with real credentials)
   # ❌ nginx.conf (with real domain)
   # ❌ Any file with passwords, IPs, or sensitive data
   ```

## Security Best Practices

### ✅ DO:
- Use template files as starting points
- Keep sensitive configurations in private, secure locations
- Use environment variables for sensitive data when possible
- Regularly rotate passwords and credentials
- Use SSH keys instead of passwords when possible

### ❌ DON'T:
- Commit files with real IP addresses
- Commit files with passwords or credentials
- Share sensitive configuration files
- Use default or weak passwords
- Expose internal server configurations

## Environment Variables

For better security, consider using environment variables:

```powershell
# Set environment variables (prefer SSH key; avoid plain passwords)
$env:OMEGA_SERVER_IP = "your-server-ip"
$env:OMEGA_SERVER_USER = "your-username"
$env:OMEGA_SERVER_PASSWORD = "your-password" # optional if not using SSH key
$env:OMEGA_SSH_KEY_PATH = "C:\Users\you\.ssh\id_rsa.ppk" # optional preferred
$env:OMEGA_SERVER_DOMAIN = "your-domain.com"

# Use in scripts
param(
    [string]$ServerIP   = $env:OMEGA_SERVER_IP,
    [string]$Username   = $env:OMEGA_SERVER_USER,
    [string]$Password   = $env:OMEGA_SERVER_PASSWORD,
    [string]$Domain     = $env:OMEGA_SERVER_DOMAIN
)
# Note: Scripts will prefer OMEGA_SSH_KEY_PATH if set; otherwise OMEGA_SERVER_PASSWORD.
```

## Git Security

The repository `.gitignore` is configured to prevent accidental commits of:
- Server setup scripts (`*server*.ps1`, `*setup*.ps1`)
- Configuration files (`*.conf`, `config.json`)
- Environment files (`.env`, `*.env`)
- SSH keys and certificates (`*.pem`, `*.key`)
- Deployment packages (`deploy-package/`)

## Support

If you need help with deployment:
1. Check this documentation first
2. Review template files for guidance
3. Contact the development team (without sharing sensitive info!)

---

**Remember: Security is everyone's responsibility!**