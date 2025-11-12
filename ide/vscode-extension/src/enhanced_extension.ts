import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export class OmegaLanguageSupport {
    private context: vscode.ExtensionContext;
    private outputChannel: vscode.OutputChannel;
    private statusBarItem: vscode.StatusBarItem;
    private terminal: vscode.Terminal | undefined;
    private languageClient: any; // Will be implemented later

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
        this.outputChannel = vscode.window.createOutputChannel('OMEGA Language Support');
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
        
        this.initializeServices();
        this.registerCommands();
        this.registerLanguageProviders();
        this.setupStatusBar();
    }

    private initializeServices(): void {
        // Initialize language server client
        this.languageClient = null; // Will be implemented
        
        // Setup file watchers
        const watcher = vscode.workspace.createFileSystemWatcher('**/*.{omega,mega}');
        watcher.onDidChange(() => this.onFileChanged());
        watcher.onDidCreate(() => this.onFileCreated());
        watcher.onDidDelete(() => this.onFileDeleted());
    }

    private registerCommands(): void {
        // Core commands
        this.registerCommand('omega.compile', this.compileCommand.bind(this));
        this.registerCommand('omega.compileDeploy', this.compileDeployCommand.bind(this));
        this.registerCommand('omega.runTests', this.runTestsCommand.bind(this));
        this.registerCommand('omega.format', this.formatCommand.bind(this));
        
        // Advanced commands
        this.registerCommand('omega.securityScan', this.securityScanCommand.bind(this));
        this.registerCommand('omega.qualityAnalysis', this.qualityAnalysisCommand.bind(this));
        this.registerCommand('omega.benchmark', this.benchmarkCommand.bind(this));
        this.registerCommand('omega.crossChainDeploy', this.crossChainDeployCommand.bind(this));
        this.registerCommand('omega.generateDocs', this.generateDocsCommand.bind(this));
        this.registerCommand('omega.optimize', this.optimizeCommand.bind(this));
        this.registerCommand('omega.showCommands', this.showCommandsCommand.bind(this));
    }

    private registerCommand(command: string, handler: (...args: any[]) => any): void {
        const disposable = vscode.commands.registerCommand(command, handler);
        this.context.subscriptions.push(disposable);
    }

    private registerLanguageProviders(): void {
        // Completion provider
        vscode.languages.registerCompletionItemProvider('omega', {
            provideCompletionItems: this.provideCompletionItems.bind(this)
        });

        // Hover provider
        vscode.languages.registerHoverProvider('omega', {
            provideHover: this.provideHover.bind(this)
        });

        // Signature help provider
        vscode.languages.registerSignatureHelpProvider('omega', {
            provideSignatureHelp: this.provideSignatureHelp.bind(this)
        });

        // Document symbol provider
        vscode.languages.registerDocumentSymbolProvider('omega', {
            provideDocumentSymbols: this.provideDocumentSymbols.bind(this)
        });

        // Definition provider
        vscode.languages.registerDefinitionProvider('omega', {
            provideDefinition: this.provideDefinition.bind(this)
        });

        // Reference provider
        vscode.languages.registerReferenceProvider('omega', {
            provideReferences: this.provideReferences.bind(this)
        });

        // Formatting provider
        vscode.languages.registerDocumentFormattingEditProvider('omega', {
            provideDocumentFormattingEdits: this.provideDocumentFormattingEdits.bind(this)
        });

        // Code action provider
        vscode.languages.registerCodeActionsProvider('omega', {
            provideCodeActions: this.provideCodeActions.bind(this)
        });

        // Semantic tokens provider
        vscode.languages.registerDocumentSemanticTokensProvider('omega', {
            provideDocumentSemanticTokens: this.provideDocumentSemanticTokens.bind(this)
        }, {
            tokenTypes: ['keyword', 'string', 'comment', 'number', 'operator', 'variable', 'function', 'type'],
            tokenModifiers: ['declaration', 'definition', 'readonly', 'static', 'deprecated', 'abstract', 'async', 'modification', 'documentation', 'defaultLibrary']
        });
    }

    private setupStatusBar(): void {
        this.statusBarItem.text = '$(omega-icon) OMEGA';
        this.statusBarItem.tooltip = 'OMEGA Language Support';
        this.statusBarItem.command = 'omega.showCommands';
        this.statusBarItem.show();
    }

    // Command implementations
    private async compileCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Compiling ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('compile', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA compilation completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA compilation failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async compileDeployCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Compiling and deploying ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('compile-deploy', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA compilation and deployment completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA compilation/deploy failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async runTestsCommand(uri?: vscode.Uri): Promise<void> {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (!workspaceFolder) {
            vscode.window.showWarningMessage('No workspace folder open');
            return;
        }

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine('Running OMEGA tests...');
            
            const result = await this.runOmegaCommand('test', workspaceFolder.uri.fsPath);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA tests completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA tests failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async formatCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            const result = await this.runOmegaCommand('format', document.fileName);
            
            // Apply formatting to document
            const edit = new vscode.WorkspaceEdit();
            const fullRange = new vscode.Range(
                document.positionAt(0),
                document.positionAt(document.getText().length)
            );
            edit.replace(document.uri, fullRange, result);
            
            await vscode.workspace.applyEdit(edit);
            vscode.window.showInformationMessage('OMEGA document formatted');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA formatting failed: ${errorMessage}`);
        }
    }

    private async securityScanCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Running security scan on ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('security-scan', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA security scan completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA security scan failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async qualityAnalysisCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Running quality analysis on ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('quality-analysis', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA quality analysis completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA quality analysis failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async benchmarkCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Running performance benchmark on ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('benchmark', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA benchmark completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA benchmark failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async crossChainDeployCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Cross-chain deploying ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('cross-chain-deploy', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA cross-chain deployment completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA cross-chain deploy failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async generateDocsCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Generating documentation for ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('generate-docs', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA documentation generated');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA documentation generation failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async optimizeCommand(uri?: vscode.Uri): Promise<void> {
        const document = await this.getDocument(uri);
        if (!document) return;

        try {
            this.outputChannel.clear();
            this.outputChannel.appendLine(`Optimizing ${document.fileName}...`);
            
            const result = await this.runOmegaCommand('optimize', document.fileName);
            this.outputChannel.appendLine(result);
            this.outputChannel.show();
            
            vscode.window.showInformationMessage('OMEGA contract optimization completed');
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`OMEGA optimization failed: ${errorMessage}`);
            this.outputChannel.appendLine(`Error: ${errorMessage}`);
        }
    }

    private async showCommandsCommand(): Promise<void> {
        const commands = [
            'omega.compile',
            'omega.compileDeploy',
            'omega.runTests',
            'omega.format',
            'omega.securityScan',
            'omega.qualityAnalysis',
            'omega.benchmark',
            'omega.crossChainDeploy',
            'omega.generateDocs',
            'omega.optimize'
        ];

        const selected = await vscode.window.showQuickPick(commands, {
            placeHolder: 'Select an OMEGA command to execute'
        });

        if (selected) {
            await vscode.commands.executeCommand(selected);
        }
    }

    // Language provider implementations
    private provideCompletionItems(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
        const line = document.lineAt(position);
        const text = line.text.substr(0, position.character);
        
        const completions: vscode.CompletionItem[] = [];
        
        // Keywords
        const keywords = [
            'blockchain', 'state', 'function', 'constructor', 'event', 'mapping',
            'public', 'private', 'internal', 'external', 'view', 'pure', 'payable',
            'require', 'assert', 'revert', 'emit', 'return', 'returns',
            'address', 'uint256', 'int256', 'bool', 'string', 'bytes', 'bytes32',
            'if', 'else', 'for', 'while', 'do', 'break', 'continue'
        ];

        keywords.forEach(keyword => {
            const item = new vscode.CompletionItem(keyword, vscode.CompletionItemKind.Keyword);
            item.detail = 'OMEGA keyword';
            completions.push(item);
        });

        // Snippets
        const snippets = [
            {
                label: 'blockchain',
                insertText: 'blockchain ${1:ContractName} {\n\tstate {\n\t\t$0\n\t}\n}',
                detail: 'Blockchain contract template'
            },
            {
                label: 'function',
                insertText: 'function ${1:functionName}(${2:params}) ${3:public} ${4:returns (${5:returnType})} {\n\t$0\n}',
                detail: 'Function template'
            }
        ];

        snippets.forEach(snippet => {
            const item = new vscode.CompletionItem(snippet.label, vscode.CompletionItemKind.Snippet);
            item.insertText = new vscode.SnippetString(snippet.insertText);
            item.detail = snippet.detail;
            completions.push(item);
        });

        return completions;
    }

    private provideHover(document: vscode.TextDocument, position: vscode.Position): vscode.Hover {
        const range = document.getWordRangeAtPosition(position);
        const word = document.getText(range);
        
        const hoverInfo: { [key: string]: string } = {
            'blockchain': 'Defines a blockchain contract',
            'state': 'Defines contract state variables',
            'function': 'Defines a contract function',
            'constructor': 'Contract constructor function',
            'event': 'Defines an event that can be emitted',
            'mapping': 'Defines a key-value mapping',
            'public': 'Function visibility: public',
            'private': 'Function visibility: private',
            'uint256': '256-bit unsigned integer type',
            'address': 'Blockchain address type'
        };

        if (hoverInfo[word]) {
            return new vscode.Hover(hoverInfo[word]);
        }

        return new vscode.Hover('');
    }

    private provideSignatureHelp(document: vscode.TextDocument, position: vscode.Position): vscode.SignatureHelp {
        // Basic signature help implementation
        return new vscode.SignatureHelp();
    }

    private provideDocumentSymbols(document: vscode.TextDocument): vscode.SymbolInformation[] {
        const symbols: vscode.SymbolInformation[] = [];
        const text = document.getText();
        const lines = text.split('\n');

        lines.forEach((line, index) => {
            // Simple regex to find blockchain contracts
            const blockchainMatch = line.match(/blockchain\s+(\w+)/);
            if (blockchainMatch) {
                const symbol = new vscode.SymbolInformation(
                    blockchainMatch[1],
                    vscode.SymbolKind.Class,
                    '',
                    new vscode.Location(document.uri, new vscode.Position(index, 0))
                );
                symbols.push(symbol);
            }

            // Find functions
            const functionMatch = line.match(/function\s+(\w+)/);
            if (functionMatch) {
                const symbol = new vscode.SymbolInformation(
                    functionMatch[1],
                    vscode.SymbolKind.Function,
                    '',
                    new vscode.Location(document.uri, new vscode.Position(index, 0))
                );
                symbols.push(symbol);
            }
        });

        return symbols;
    }

    private provideDefinition(document: vscode.TextDocument, position: vscode.Position): vscode.Location | vscode.Location[] | null {
        // Basic definition provider
        return null;
    }

    private provideReferences(document: vscode.TextDocument, position: vscode.Position, context: vscode.ReferenceContext): vscode.Location[] {
        // Basic reference provider
        return [];
    }

    private provideDocumentFormattingEdits(document: vscode.TextDocument): vscode.TextEdit[] {
        // Enhanced formatting for OMEGA language
        const edits: vscode.TextEdit[] = [];
        const text = document.getText();
        const lines = text.split('\n');
        
        lines.forEach((line, index) => {
            const trimmed = line.trim();
            
            // Skip empty lines
            if (trimmed.length === 0) return;
            
            // Format blockchain declarations
            if (trimmed.includes('blockchain') && trimmed.includes('{')) {
                const formatted = trimmed.replace(/\s*{/g, ' {');
                if (formatted !== line) {
                    const range = new vscode.Range(index, 0, index, line.length);
                    edits.push(vscode.TextEdit.replace(range, formatted));
                }
            }
            
            // Format state declarations
            if (trimmed.includes('state') && trimmed.includes('{')) {
                const formatted = trimmed.replace(/\s*{/g, ' {');
                if (formatted !== line) {
                    const range = new vscode.Range(index, 0, index, line.length);
                    edits.push(vscode.TextEdit.replace(range, formatted));
                }
            }
            
            // Format function declarations
            if (trimmed.includes('function') && trimmed.includes('(')) {
                const formatted = trimmed.replace(/\s*\(/g, '(');
                if (formatted !== line) {
                    const range = new vscode.Range(index, 0, index, line.length);
                    edits.push(vscode.TextEdit.replace(range, formatted));
                }
            }
            
            // Add spaces around operators
            const operatorFormatted = trimmed.replace(/([{}();])/g, ' $1 ').replace(/\s+/g, ' ').trim();
            if (operatorFormatted !== trimmed && operatorFormatted.length > 0) {
                const range = new vscode.Range(index, 0, index, line.length);
                edits.push(vscode.TextEdit.replace(range, operatorFormatted));
            }
        });

        return edits;
    }

    private provideCodeActions(document: vscode.TextDocument, range: vscode.Range, context: vscode.CodeActionContext): vscode.CodeAction[] {
        // Basic code actions
        return [];
    }

    private provideDocumentSemanticTokens(document: vscode.TextDocument): vscode.SemanticTokens {
        // Basic semantic tokens
        const builder = new vscode.SemanticTokensBuilder();
        return builder.build();
    }

    // Helper methods
    private async getDocument(uri?: vscode.Uri): Promise<vscode.TextDocument | null> {
        if (uri) {
            return await vscode.workspace.openTextDocument(uri);
        }

        const editor = vscode.window.activeTextEditor;
        if (editor && (editor.document.languageId === 'omega')) {
            return editor.document;
        }

        vscode.window.showWarningMessage('No OMEGA document open');
        return null;
    }

    private async runOmegaCommand(command: string, filePath: string): Promise<string> {
        const config = vscode.workspace.getConfiguration('omega');
        const omegaPath = config.get<string>('executablePath', 'omega');
        
        const fullCommand = `"${omegaPath}" ${command} "${filePath}"`;
        
        try {
            const { stdout, stderr } = await execAsync(fullCommand);
            if (stderr) {
                throw new Error(stderr);
            }
            return stdout;
        } catch (error) {
            throw error;
        }
    }

    // Event handlers
    private onFileChanged(): void {
        const config = vscode.workspace.getConfiguration('omega');
        if (config.get<boolean>('autoCompile', false)) {
            this.compileCommand();
        }
    }

    private onFileCreated(): void {
        // Handle file creation
    }

    private onFileDeleted(): void {
        // Handle file deletion
    }

    dispose(): void {
        this.outputChannel.dispose();
        this.statusBarItem.dispose();
        if (this.terminal) {
            this.terminal.dispose();
        }
    }
}

export function activate(context: vscode.ExtensionContext) {
    const omegaSupport = new OmegaLanguageSupport(context);
    context.subscriptions.push(omegaSupport);
    
    vscode.window.showInformationMessage('OMEGA Language Support Enhanced is now active!');
}

export function deactivate() {
    // Cleanup
}