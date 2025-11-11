import * as vscode from 'vscode';
import { LanguageClient, LanguageClientOptions, ServerOptions, TransportKind } from 'vscode-languageclient/node';
import { OmegaCompilerProvider } from './providers/compilerProvider';
import { OmegaDebugConfigurationProvider } from './providers/debugConfigurationProvider';
import { OmegaPackageManager } from './providers/packageManager';
import { OmegaProjectManager } from './providers/projectManager';
import { OmegaDiagnosticsProvider } from './providers/diagnosticsProvider';
import { OmegaCompletionProvider } from './providers/completionProvider';
import { OmegaFormattingProvider } from './providers/formattingProvider';
import { OmegaHoverProvider } from './providers/hoverProvider';
import { OmegaDefinitionProvider } from './providers/definitionProvider';
import { OmegaReferenceProvider } from './providers/referenceProvider';
import { OmegaSymbolProvider } from './providers/symbolProvider';
import { OmegaCodeLensProvider } from './providers/codeLensProvider';
import { OmegaRenameProvider } from './providers/renameProvider';
import { OmegaDocumentHighlightProvider } from './providers/documentHighlightProvider';
import { OmegaCodeActionProvider } from './providers/codeActionProvider';
import { OmegaFoldingRangeProvider } from './providers/foldingRangeProvider';
import { OmegaColorProvider } from './providers/colorProvider';
import { OmegaWorkspaceSymbolProvider } from './providers/workspaceSymbolProvider';
import { OmegaTreeDataProvider } from './providers/treeDataProvider';
import { OmegaStatusBar } from './ui/statusBar';
import { OmegaOutputChannel } from './ui/outputChannel';
import { OmegaTerminal } from './ui/terminal';
import { OmegaWebviewProvider } from './ui/webviewProvider';
import { OmegaConfiguration } from './configuration/configuration';
import { OmegaLogger } from './utils/logger';
import { OmegaTelemetry } from './utils/telemetry';
import { OmegaCommands } from './commands/commands';
import { OmegaKeybindings } from './keybindings/keybindings';
import { OmegaTaskProvider } from './tasks/taskProvider';
import { OmegaTestController } from './testing/testController';
import { OmegaPerformanceMonitor } from './performance/performanceMonitor';
import { OmegaSecurityScanner } from './security/securityScanner';

let client: LanguageClient;
let outputChannel: OmegaOutputChannel;
let statusBar: OmegaStatusBar;
let logger: OmegaLogger;
let telemetry: OmegaTelemetry;
let config: OmegaConfiguration;

export function activate(context: vscode.ExtensionContext) {
    console.log('OMEGA Language Support extension is now active!');
    
    // Initialize core components
    initializeCoreComponents(context);
    
    // Setup language client
    setupLanguageClient(context);
    
    // Register providers
    registerLanguageProviders(context);
    
    // Register commands
    registerCommands(context);
    
    // Register task providers
    registerTaskProviders(context);
    
    // Register test controller
    registerTestController(context);
    
    // Setup UI components
    setupUIComponents(context);
    
    // Setup event listeners
    setupEventListeners(context);
    
    // Initialize workspace
    initializeWorkspace(context);
    
    // Show welcome message
    showWelcomeMessage();
    
    telemetry.sendEvent('extensionActivated');
}

export function deactivate(): Thenable<void> | undefined {
    telemetry.sendEvent('extensionDeactivated');
    
    if (!client) {
        return undefined;
    }
    return client.stop();
}

function initializeCoreComponents(context: vscode.ExtensionContext) {
    // Initialize configuration
    config = new OmegaConfiguration();
    
    // Initialize logger
    logger = new OmegaLogger(config.getLogLevel());
    
    // Initialize telemetry
    telemetry = new OmegaTelemetry(config.isTelemetryEnabled());
    
    // Initialize output channel
    outputChannel = new OmegaOutputChannel('OMEGA');
    
    // Initialize status bar
    statusBar = new OmegaStatusBar();
}

function setupLanguageClient(context: vscode.ExtensionContext) {
    // Server options
    const serverModule = context.asAbsolutePath('out/server/server.js');
    const serverOptions: ServerOptions = {
        run: { module: serverModule, transport: TransportKind.ipc },
        debug: {
            module: serverModule,
            transport: TransportKind.ipc,
            options: { execArgv: ['--nolazy', '--inspect=6009'] }
        }
    };
    
    // Client options
    const clientOptions: LanguageClientOptions = {
        documentSelector: [
            { scheme: 'file', language: 'omega' },
            { scheme: 'untitled', language: 'omega' }
        ],
        synchronize: {
            fileEvents: [
                vscode.workspace.createFileSystemWatcher('**/*.mega'),
                vscode.workspace.createFileSystemWatcher('**/*.omega'),
                vscode.workspace.createFileSystemWatcher('**/omega.json'),
                vscode.workspace.createFileSystemWatcher('**/omega-package.json')
            ]
        },
        outputChannel: outputChannel.getChannel(),
        revealOutputChannelOn: config.getRevealOutputChannelOn()
    };
    
    // Create and start the language client
    client = new LanguageClient('omegaLanguageServer', 'OMEGA Language Server', serverOptions, clientOptions);
    client.start();
}

function registerLanguageProviders(context: vscode.ExtensionContext) {
    const omegaSelector = { language: 'omega', scheme: 'file' };
    
    // Completion provider
    const completionProvider = new OmegaCompletionProvider();
    context.subscriptions.push(
        vscode.languages.registerCompletionItemProvider(omegaSelector, completionProvider, ...config.getTriggerCharacters())
    );
    
    // Hover provider
    const hoverProvider = new OmegaHoverProvider();
    context.subscriptions.push(
        vscode.languages.registerHoverProvider(omegaSelector, hoverProvider)
    );
    
    // Definition provider
    const definitionProvider = new OmegaDefinitionProvider();
    context.subscriptions.push(
        vscode.languages.registerDefinitionProvider(omegaSelector, definitionProvider)
    );
    
    // Reference provider
    const referenceProvider = new OmegaReferenceProvider();
    context.subscriptions.push(
        vscode.languages.registerReferenceProvider(omegaSelector, referenceProvider)
    );
    
    // Document symbol provider
    const symbolProvider = new OmegaSymbolProvider();
    context.subscriptions.push(
        vscode.languages.registerDocumentSymbolProvider(omegaSelector, symbolProvider)
    );
    
    // Workspace symbol provider
    const workspaceSymbolProvider = new OmegaWorkspaceSymbolProvider();
    context.subscriptions.push(
        vscode.languages.registerWorkspaceSymbolProvider(workspaceSymbolProvider)
    );
    
    // Code lens provider
    const codeLensProvider = new OmegaCodeLensProvider();
    context.subscriptions.push(
        vscode.languages.registerCodeLensProvider(omegaSelector, codeLensProvider)
    );
    
    // Rename provider
    const renameProvider = new OmegaRenameProvider();
    context.subscriptions.push(
        vscode.languages.registerRenameProvider(omegaSelector, renameProvider)
    );
    
    // Document highlight provider
    const documentHighlightProvider = new OmegaDocumentHighlightProvider();
    context.subscriptions.push(
        vscode.languages.registerDocumentHighlightProvider(omegaSelector, documentHighlightProvider)
    );
    
    // Code action provider
    const codeActionProvider = new OmegaCodeActionProvider();
    context.subscriptions.push(
        vscode.languages.registerCodeActionsProvider(omegaSelector, codeActionProvider)
    );
    
    // Folding range provider
    const foldingRangeProvider = new OmegaFoldingRangeProvider();
    context.subscriptions.push(
        vscode.languages.registerFoldingRangeProvider(omegaSelector, foldingRangeProvider)
    );
    
    // Color provider
    const colorProvider = new OmegaColorProvider();
    context.subscriptions.push(
        vscode.languages.registerColorProvider(omegaSelector, colorProvider)
    );
    
    // Formatting provider
    const formattingProvider = new OmegaFormattingProvider();
    context.subscriptions.push(
        vscode.languages.registerDocumentFormattingProvider(omegaSelector, formattingProvider)
    );
    context.subscriptions.push(
        vscode.languages.registerDocumentRangeFormattingProvider(omegaSelector, formattingProvider)
    );
    
    // Diagnostics provider
    const diagnosticsProvider = new OmegaDiagnosticsProvider();
    context.subscriptions.push(diagnosticsProvider);
}

function registerCommands(context: vscode.ExtensionContext) {
    const commands = new OmegaCommands(context, client, outputChannel, statusBar);
    commands.registerAllCommands();
}

function registerTaskProviders(context: vscode.ExtensionContext) {
    const taskProvider = new OmegaTaskProvider();
    context.subscriptions.push(
        vscode.tasks.registerTaskProvider('omega', taskProvider)
    );
}

function registerTestController(context: vscode.ExtensionContext) {
    const testController = new OmegaTestController();
    context.subscriptions.push(testController);
}

function setupUIComponents(context: vscode.ExtensionContext) {
    // Tree data provider
    const treeDataProvider = new OmegaTreeDataProvider();
    const treeView = vscode.window.createTreeView('omegaExplorer', {
        treeDataProvider: treeDataProvider,
        showCollapseAll: true
    });
    context.subscriptions.push(treeView);
    
    // Webview provider
    const webviewProvider = new OmegaWebviewProvider(context);
    context.subscriptions.push(webviewProvider);
}

function setupEventListeners(context: vscode.ExtensionContext) {
    // File system watchers
    const megaFileWatcher = vscode.workspace.createFileSystemWatcher('**/*.mega');
    const omegaFileWatcher = vscode.workspace.createFileSystemWatcher('**/*.omega');
    const configFileWatcher = vscode.workspace.createFileSystemWatcher('**/omega.json');
    
    megaFileWatcher.onDidCreate(uri => handleFileCreated(uri));
    megaFileWatcher.onDidChange(uri => handleFileChanged(uri));
    megaFileWatcher.onDidDelete(uri => handleFileDeleted(uri));
    
    omegaFileWatcher.onDidCreate(uri => handleFileCreated(uri));
    omegaFileWatcher.onDidChange(uri => handleFileChanged(uri));
    omegaFileWatcher.onDidDelete(uri => handleFileDeleted(uri));
    
    configFileWatcher.onDidChange(uri => handleConfigChanged(uri));
    
    context.subscriptions.push(megaFileWatcher, omegaFileWatcher, configFileWatcher);
    
    // Configuration change listener
    context.subscriptions.push(
        vscode.workspace.onDidChangeConfiguration(event => {
            if (event.affectsConfiguration('omega')) {
                handleConfigurationChanged();
            }
        })
    );
    
    // Window state change listener
    context.subscriptions.push(
        vscode.window.onDidChangeWindowState(state => {
            if (state.focused) {
                handleWindowFocused();
            }
        })
    );
    
    // Text document change listener
    context.subscriptions.push(
        vscode.workspace.onDidChangeTextDocument(event => {
            if (event.document.languageId === 'omega') {
                handleDocumentChanged(event);
            }
        })
    );
    
    // Text document open listener
    context.subscriptions.push(
        vscode.workspace.onDidOpenTextDocument(document => {
            if (document.languageId === 'omega') {
                handleDocumentOpened(document);
            }
        })
    );
    
    // Text document close listener
    context.subscriptions.push(
        vscode.workspace.onDidCloseTextDocument(document => {
            if (document.languageId === 'omega') {
                handleDocumentClosed(document);
            }
        })
    );
}

function initializeWorkspace(context: vscode.ExtensionContext) {
    // Check for OMEGA projects in workspace
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (workspaceFolders) {
        workspaceFolders.forEach(folder => {
            checkForOmegaProject(folder.uri.fsPath);
        });
    }
    
    // Initialize project manager
    const projectManager = new OmegaProjectManager(context);
    context.subscriptions.push(projectManager);
    
    // Initialize package manager
    const packageManager = new OmegaPackageManager(context);
    context.subscriptions.push(packageManager);
    
    // Initialize performance monitor
    const performanceMonitor = new OmegaPerformanceMonitor(context);
    context.subscriptions.push(performanceMonitor);
    
    // Initialize security scanner
    const securityScanner = new OmegaSecurityScanner(context);
    context.subscriptions.push(securityScanner);
}

function handleFileCreated(uri: vscode.Uri) {
    logger.info(`File created: ${uri.fsPath}`);
    telemetry.sendEvent('fileCreated', { fileType: getFileType(uri.fsPath) });
}

function handleFileChanged(uri: vscode.Uri) {
    logger.info(`File changed: ${uri.fsPath}`);
    telemetry.sendEvent('fileChanged', { fileType: getFileType(uri.fsPath) });
    
    // Trigger diagnostics update
    if (client) {
        client.sendNotification('workspace/didChangeWatchedFiles', {
            changes: [{ uri: uri.toString(), type: 2 }] // Changed
        });
    }
}

function handleFileDeleted(uri: vscode.Uri) {
    logger.info(`File deleted: ${uri.fsPath}`);
    telemetry.sendEvent('fileDeleted', { fileType: getFileType(uri.fsPath) });
}

function handleConfigChanged(uri: vscode.Uri) {
    logger.info(`Config changed: ${uri.fsPath}`);
    // Reload configuration
    config.reload();
    
    // Update language server
    if (client) {
        client.sendNotification('workspace/didChangeConfiguration', {
            settings: vscode.workspace.getConfiguration('omega')
        });
    }
}

function handleConfigurationChanged() {
    logger.info('Configuration changed');
    config.reload();
    
    // Update UI components
    statusBar.update();
    
    // Update language server
    if (client) {
        client.sendNotification('workspace/didChangeConfiguration', {
            settings: vscode.workspace.getConfiguration('omega')
        });
    }
}

function handleWindowFocused() {
    logger.info('Window focused');
    statusBar.update();
}

function handleDocumentChanged(event: vscode.TextDocumentChangeEvent) {
    logger.info(`Document changed: ${event.document.uri.fsPath}`);
    
    // Auto-format on save if enabled
    if (config.getAutoFormatOnSave() && event.contentChanges.length > 0) {
        const editor = vscode.window.activeTextEditor;
        if (editor && editor.document === event.document) {
            // Trigger formatting
            vscode.commands.executeCommand('editor.action.formatDocument');
        }
    }
}

function handleDocumentOpened(document: vscode.TextDocument) {
    logger.info(`Document opened: ${document.uri.fsPath}`);
    telemetry.sendEvent('documentOpened', { fileType: getFileType(document.uri.fsPath) });
    
    // Show status bar for OMEGA files
    if (document.languageId === 'omega') {
        statusBar.show();
    }
}

function handleDocumentClosed(document: vscode.TextDocument) {
    logger.info(`Document closed: ${document.uri.fsPath}`);
    telemetry.sendEvent('documentClosed', { fileType: getFileType(document.uri.fsPath) });
    
    // Hide status bar if no OMEGA files are open
    const openDocuments = vscode.workspace.textDocuments;
    const hasOmegaFiles = openDocuments.some(doc => doc.languageId === 'omega');
    if (!hasOmegaFiles) {
        statusBar.hide();
    }
}

function checkForOmegaProject(workspacePath: string) {
    const fs = require('fs');
    const path = require('path');
    
    // Check for omega.json or omega-package.json
    const configFiles = ['omega.json', 'omega-package.json'];
    
    for (const configFile of configFiles) {
        const configPath = path.join(workspacePath, configFile);
        if (fs.existsSync(configPath)) {
            logger.info(`Found OMEGA project at: ${workspacePath}`);
            telemetry.sendEvent('omegaProjectDetected', { configFile });
            
            // Initialize project-specific features
            initializeProjectFeatures(workspacePath);
            break;
        }
    }
}

function initializeProjectFeatures(workspacePath: string) {
    // Load project configuration
    const projectManager = new OmegaProjectManager(vscode.extensions.all[0].extensionUri);
    projectManager.loadProject(workspacePath);
    
    // Set up project-specific status bar
    statusBar.setProjectMode(true);
}

function showWelcomeMessage() {
    const welcomeMessage = `🚀 OMEGA Language Support is now active!\n\n` +
        `Features available:\n` +
        `• Syntax highlighting and IntelliSense\n` +
        `• Cross-compilation to multiple blockchains\n` +
        `• Built-in testing and debugging\n` +
        `• Package management\n` +
        `• Security scanning\n\n` +
        `Use Ctrl+Shift+P and type 'OMEGA' to see available commands.`;
    
    outputChannel.appendLine(welcomeMessage);
    
    // Show notification if enabled
    if (config.getShowWelcomeNotification()) {
        vscode.window.showInformationMessage(
            'OMEGA Language Support is now active!',
            'Show Commands',
            'Open Documentation',
            'Don\'t Show Again'
        ).then(selection => {
            switch (selection) {
                case 'Show Commands':
                    vscode.commands.executeCommand('workbench.action.showCommands');
                    break;
                case 'Open Documentation':
                    vscode.env.openExternal(vscode.Uri.parse('https://docs.omega-lang.org'));
                    break;
                case 'Don\'t Show Again':
                    config.setShowWelcomeNotification(false);
                    break;
            }
        });
    }
}

function getFileType(filePath: string): string {
    const ext = filePath.split('.').pop()?.toLowerCase();
    switch (ext) {
        case 'mega':
        case 'omega':
            return 'omega';
        case 'json':
            return 'json';
        case 'md':
            return 'markdown';
        default:
            return 'unknown';
    }
}