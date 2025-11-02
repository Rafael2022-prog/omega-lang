#!/usr/bin/env node

/**
 * OMEGA Universal File Handler
 * Cross-platform file association and icon handler for .mega files
 * Supports Windows, macOS, and Linux
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync, spawn } = require('child_process');

class OmegaFileHandler {
    constructor() {
        this.platform = os.platform();
        this.omegaPath = path.resolve(__dirname, '../../');
        this.iconPath = path.join(this.omegaPath, 'temp-logo.svg');
        this.configPath = path.join(os.homedir(), '.omega');
        
        this.ensureConfigDir();
    }

    ensureConfigDir() {
        if (!fs.existsSync(this.configPath)) {
            fs.mkdirSync(this.configPath, { recursive: true });
        }
    }

    /**
     * Install file associations for the current platform
     */
    async install() {
        console.log(`Installing OMEGA file associations for ${this.platform}...`);
        
        try {
            switch (this.platform) {
                case 'win32':
                    await this.installWindows();
                    break;
                case 'darwin':
                    await this.installMacOS();
                    break;
                case 'linux':
                    await this.installLinux();
                    break;
                default:
                    throw new Error(`Unsupported platform: ${this.platform}`);
            }
            
            console.log('✅ File associations installed successfully!');
            this.saveConfig();
        } catch (error) {
            console.error('⚠️ OMEGA file association could not complete automatically:', error.message);
            console.warn('Hint: On Windows, you may need to run "npm run icons:install" in an elevated (Administrator) PowerShell to register icons.');
            console.warn('Postinstall will continue without failing to avoid interrupting your setup.');
            // Do not fail postinstall; allow setup to continue
        }
    }

    /**
     * Windows installation
     */
    async installWindows() {
        const regFile = path.join(this.omegaPath, 'system-integration/windows/omega-context-menu.reg');
        
        if (!fs.existsSync(regFile)) {
            throw new Error('Windows registry file not found');
        }
    
        // Prepare icon fallback handling
        const icoPath = path.join(this.omegaPath, 'omega-icon.ico');
        let regContent = fs.readFileSync(regFile, 'utf8');
    
        if (fs.existsSync(icoPath)) {
            // Ensure .ico is used instead of .svg
            regContent = regContent.replace(/r:\\OMEGA\\temp-logo\.svg,0/g, 'r:\\OMEGA\\omega-icon.ico,0');
        } else {
            // Fallback to VS Code icon if OMEGA .ico is not available
            const vsCodeIcon = '"C:\\Users\\%USERNAME%\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe",0';
            // Replace DefaultIcon entries
            regContent = regContent.replace(/@="r:\\OMEGA\\[^"]+,0"/g, `@="${vsCodeIcon}"`);
            // Replace menu Icon entries pointing to OMEGA paths
            regContent = regContent.replace(/"Icon"="r:\\OMEGA\\[^"]+"/g, `"Icon"="${vsCodeIcon}"`);
        }
    
        // Write temp registry file and attempt import (HKCR)
        const tempRegFile = path.join(this.configPath, 'omega-context-menu.reg');
        fs.writeFileSync(tempRegFile, regContent, 'utf8');
    
        try {
            // Try system-wide import (requires admin)
            execSync(`reg import "${tempRegFile}"`, { stdio: 'inherit' });
        } catch (error) {
            console.warn('HKCR import failed, falling back to per-user registry (HKCU)');
            // Fallback: rewrite registry to HKCU\Software\Classes paths
            let userRegContent = regContent
                .replace(/\[HKEY_CLASSES_ROOT\\\.mega\]/g, '[HKEY_CURRENT_USER\\Software\\Classes\\.mega]')
                .replace(/\[HKEY_CLASSES_ROOT\\OmegaSourceFile/g, '[HKEY_CURRENT_USER\\Software\\Classes\\OmegaSourceFile')
                .replace(/\[HKEY_CLASSES_ROOT\\SystemFileAssociations\\\.mega/g, '[HKEY_CURRENT_USER\\Software\\Classes\\SystemFileAssociations\\.mega')
                .replace(/\[HKEY_CLASSES_ROOT\\MIME\\Database\\Content Type\\/g, '[HKEY_CURRENT_USER\\Software\\Classes\\MIME\\Database\\Content Type\\');
            const tempUserReg = path.join(this.configPath, 'omega-context-menu-user.reg');
            fs.writeFileSync(tempUserReg, userRegContent, 'utf8');
            execSync(`reg import "${tempUserReg}"`, { stdio: 'inherit' });
        }
        
        // Refresh shell icons
        execSync('ie4uinit.exe -show', { stdio: 'inherit' });
        
        console.log('Windows file associations registered');
    }

    /**
     * macOS installation
     */
    async installMacOS() {
        const installScript = path.join(this.omegaPath, 'system-integration/macos/install-file-associations.sh');
        
        if (!fs.existsSync(installScript)) {
            throw new Error('macOS installation script not found');
        }

        // Make script executable
        execSync(`chmod +x "${installScript}"`);
        
        // Run installation script
        execSync(`"${installScript}"`, { stdio: 'inherit' });
        
        console.log('macOS file associations registered');
    }

    /**
     * Linux installation
     */
    async installLinux() {
        const installScript = path.join(this.omegaPath, 'system-integration/linux/install-mime-types.sh');
        
        if (!fs.existsSync(installScript)) {
            throw new Error('Linux installation script not found');
        }

        // Make script executable
        execSync(`chmod +x "${installScript}"`);
        
        // Run installation script
        execSync(`"${installScript}"`, { stdio: 'inherit' });
        
        console.log('Linux file associations registered');
    }

    /**
     * Uninstall file associations
     */
    async uninstall() {
        console.log(`Uninstalling OMEGA file associations for ${this.platform}...`);
        
        try {
            switch (this.platform) {
                case 'win32':
                    await this.uninstallWindows();
                    break;
                case 'darwin':
                    await this.uninstallMacOS();
                    break;
                case 'linux':
                    await this.uninstallLinux();
                    break;
            }
            
            console.log('✅ File associations uninstalled successfully!');
            this.removeConfig();
        } catch (error) {
            console.error('❌ Uninstallation failed:', error.message);
        }
    }

    /**
     * Windows uninstallation
     */
    async uninstallWindows() {
        // Remove registry entries
        const commands = [
            'reg delete "HKEY_CLASSES_ROOT\\.mega" /f',
            'reg delete "HKEY_CLASSES_ROOT\\OmegaSourceFile" /f',
            'reg delete "HKEY_CLASSES_ROOT\\SystemFileAssociations\\.mega" /f'
        ];

        for (const cmd of commands) {
            try {
                execSync(cmd, { stdio: 'pipe' });
            } catch (error) {
                // Ignore errors for non-existent keys
            }
        }

        // Refresh shell icons
        execSync('ie4uinit.exe -show', { stdio: 'inherit' });
    }

    /**
     * macOS uninstallation
     */
    async uninstallMacOS() {
        // Remove app bundle
        const appPath = '/Applications/OMEGA Editor.app';
        if (fs.existsSync(appPath)) {
            execSync(`sudo rm -rf "${appPath}"`);
        }

        // Remove Quick Look plugin
        const qlPath = path.join(os.homedir(), 'Library/QuickLook/OmegaQL.qlgenerator');
        if (fs.existsSync(qlPath)) {
            execSync(`rm -rf "${qlPath}"`);
        }

        // Remove Spotlight importer
        const spotlightPath = path.join(os.homedir(), 'Library/Spotlight/OmegaSpotlight.mdimporter');
        if (fs.existsSync(spotlightPath)) {
            execSync(`rm -rf "${spotlightPath}"`);
        }

        // Reset Launch Services
        execSync('/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user');
    }

    /**
     * Linux uninstallation
     */
    async uninstallLinux() {
        const homeDir = os.homedir();
        
        // Remove MIME type
        const mimeFile = path.join(homeDir, '.local/share/mime/packages/omega.xml');
        if (fs.existsSync(mimeFile)) {
            fs.unlinkSync(mimeFile);
        }

        // Remove desktop entry
        const desktopFile = path.join(homeDir, '.local/share/applications/omega-editor.desktop');
        if (fs.existsSync(desktopFile)) {
            fs.unlinkSync(desktopFile);
        }

        // Remove icons
        const iconSizes = ['16x16', '32x32', '48x48', '64x64', '128x128', '256x256'];
        for (const size of iconSizes) {
            const iconFile = path.join(homeDir, `.local/share/icons/hicolor/${size}/mimetypes/application-x-omega.png`);
            if (fs.existsSync(iconFile)) {
                fs.unlinkSync(iconFile);
            }
        }

        // Update databases
        execSync('update-mime-database ~/.local/share/mime', { stdio: 'inherit' });
        execSync('gtk-update-icon-cache ~/.local/share/icons/hicolor', { stdio: 'inherit' });
    }

    /**
     * Check if file associations are installed
     */
    isInstalled() {
        const configFile = path.join(this.configPath, 'file-associations.json');
        return fs.existsSync(configFile);
    }

    /**
     * Save configuration
     */
    saveConfig() {
        const config = {
            platform: this.platform,
            installedAt: new Date().toISOString(),
            version: '1.0.0',
            omegaPath: this.omegaPath
        };

        const configFile = path.join(this.configPath, 'file-associations.json');
        fs.writeFileSync(configFile, JSON.stringify(config, null, 2));
    }

    /**
     * Remove configuration
     */
    removeConfig() {
        const configFile = path.join(this.configPath, 'file-associations.json');
        if (fs.existsSync(configFile)) {
            fs.unlinkSync(configFile);
        }
    }

    /**
     * Open .mega file with appropriate editor
     */
    openFile(filePath) {
        if (!fs.existsSync(filePath)) {
            console.error(`File not found: ${filePath}`);
            return;
        }

        console.log(`Opening ${filePath}...`);

        // Try to find VS Code first
        const editors = this.getAvailableEditors();
        
        for (const editor of editors) {
            try {
                spawn(editor.command, [filePath], { 
                    detached: true, 
                    stdio: 'ignore' 
                }).unref();
                console.log(`Opened with ${editor.name}`);
                return;
            } catch (error) {
                continue;
            }
        }

        console.error('No suitable editor found');
    }

    /**
     * Get list of available editors
     */
    getAvailableEditors() {
        const editors = [];

        switch (this.platform) {
            case 'win32':
                editors.push(
                    { name: 'VS Code', command: 'code' },
                    { name: 'VS Code (User)', command: path.join(os.homedir(), 'AppData/Local/Programs/Microsoft VS Code/Code.exe') },
                    { name: 'Notepad++', command: 'notepad++' },
                    { name: 'Notepad', command: 'notepad' }
                );
                break;
            case 'darwin':
                editors.push(
                    { name: 'VS Code', command: 'code' },
                    { name: 'VS Code (App)', command: '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' },
                    { name: 'TextEdit', command: 'open -a TextEdit' }
                );
                break;
            case 'linux':
                editors.push(
                    { name: 'VS Code', command: 'code' },
                    { name: 'Gedit', command: 'gedit' },
                    { name: 'Nano', command: 'nano' },
                    { name: 'Vim', command: 'vim' }
                );
                break;
        }

        return editors;
    }

    /**
     * Show status information
     */
    status() {
        console.log('OMEGA File Handler Status');
        console.log('========================');
        console.log(`Platform: ${this.platform}`);
        console.log(`OMEGA Path: ${this.omegaPath}`);
        console.log(`Config Path: ${this.configPath}`);
        console.log(`Installed: ${this.isInstalled() ? '✅ Yes' : '❌ No'}`);
        
        if (this.isInstalled()) {
            const configFile = path.join(this.configPath, 'file-associations.json');
            const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
            console.log(`Installed At: ${config.installedAt}`);
            console.log(`Version: ${config.version}`);
        }

        console.log('\nAvailable Editors:');
        const editors = this.getAvailableEditors();
        editors.forEach(editor => {
            console.log(`- ${editor.name}: ${editor.command}`);
        });
    }
}

// CLI Interface
function main() {
    const handler = new OmegaFileHandler();
    const args = process.argv.slice(2);
    const command = args[0];

    switch (command) {
        case 'install':
            handler.install();
            break;
        case 'uninstall':
            handler.uninstall();
            break;
        case 'status':
            handler.status();
            break;
        case 'open':
            if (args[1]) {
                handler.openFile(args[1]);
            } else {
                console.error('Usage: omega-file-handler open <file.mega>');
            }
            break;
        default:
            console.log('OMEGA Universal File Handler');
            console.log('Usage:');
            console.log('  node omega-file-handler.js install   - Install file associations');
            console.log('  node omega-file-handler.js uninstall - Remove file associations');
            console.log('  node omega-file-handler.js status    - Show installation status');
            console.log('  node omega-file-handler.js open <file> - Open .mega file');
            break;
    }
}

if (require.main === module) {
    main();
}

module.exports = OmegaFileHandler;