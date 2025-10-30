import * as vscode from 'vscode';
import { exec } from 'child_process';
import * as path from 'path';

export function activate(context: vscode.ExtensionContext) {
    console.log('OMEGA Language Support extension is now active!');

    // Register compile command
    let compileCommand = vscode.commands.registerCommand('omega.compile', () => {
        const activeEditor = vscode.window.activeTextEditor;
        if (!activeEditor) {
            vscode.window.showErrorMessage('No active OMEGA file to compile');
            return;
        }

        const document = activeEditor.document;
        if (document.languageId !== 'omega') {
            vscode.window.showErrorMessage('Current file is not an OMEGA file');
            return;
        }

        const filePath = document.fileName;
        const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
        
        if (!workspaceFolder) {
            vscode.window.showErrorMessage('No workspace folder found');
            return;
        }

        const config = vscode.workspace.getConfiguration('omega');
        const compilerPath = config.get<string>('compilerPath', 'omega');

        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: "Compiling OMEGA contract...",
            cancellable: false
        }, (progress) => {
            return new Promise<void>((resolve, reject) => {
                exec(`${compilerPath} build`, {
                    cwd: workspaceFolder.uri.fsPath
                }, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`Compilation failed: ${error.message}`);
                        reject(error);
                        return;
                    }

                    if (stderr) {
                        vscode.window.showWarningMessage(`Compilation warnings: ${stderr}`);
                    }

                    vscode.window.showInformationMessage('OMEGA contract compiled successfully!');
                    resolve();
                });
            });
        });
    });

    // Register deploy command
    let deployCommand = vscode.commands.registerCommand('omega.deploy', async () => {
        const config = vscode.workspace.getConfiguration('omega');
        const targetChains = config.get<string[]>('targetChains', ['evm', 'solana']);
        
        const selectedChain = await vscode.window.showQuickPick(targetChains, {
            placeHolder: 'Select target blockchain'
        });

        if (!selectedChain) {
            return;
        }

        const networks = selectedChain === 'evm' 
            ? ['localhost', 'sepolia', 'mainnet'] 
            : ['devnet', 'testnet', 'mainnet'];

        const selectedNetwork = await vscode.window.showQuickPick(networks, {
            placeHolder: 'Select network'
        });

        if (!selectedNetwork) {
            return;
        }

        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (!workspaceFolder) {
            vscode.window.showErrorMessage('No workspace folder found');
            return;
        }

        const compilerPath = config.get<string>('compilerPath', 'omega');

        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: `Deploying to ${selectedChain} ${selectedNetwork}...`,
            cancellable: false
        }, (progress) => {
            return new Promise<void>((resolve, reject) => {
                exec(`${compilerPath} deploy --target ${selectedChain} --network ${selectedNetwork}`, {
                    cwd: workspaceFolder.uri.fsPath
                }, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`Deployment failed: ${error.message}`);
                        reject(error);
                        return;
                    }

                    vscode.window.showInformationMessage(`Contract deployed successfully to ${selectedChain} ${selectedNetwork}!`);
                    resolve();
                });
            });
        });
    });

    // Register test command
    let testCommand = vscode.commands.registerCommand('omega.test', () => {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (!workspaceFolder) {
            vscode.window.showErrorMessage('No workspace folder found');
            return;
        }

        const config = vscode.workspace.getConfiguration('omega');
        const compilerPath = config.get<string>('compilerPath', 'omega');

        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: "Running OMEGA tests...",
            cancellable: false
        }, (progress) => {
            return new Promise<void>((resolve, reject) => {
                exec(`${compilerPath} test`, {
                    cwd: workspaceFolder.uri.fsPath
                }, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`Tests failed: ${error.message}`);
                        reject(error);
                        return;
                    }

                    vscode.window.showInformationMessage('All tests passed!');
                    resolve();
                });
            });
        });
    });

    // Register diagnostics provider
    const diagnosticCollection = vscode.languages.createDiagnosticCollection('omega');
    context.subscriptions.push(diagnosticCollection);

    // Auto-compile on save if enabled
    const onSave = vscode.workspace.onDidSaveTextDocument((document) => {
        if (document.languageId === 'omega') {
            const config = vscode.workspace.getConfiguration('omega');
            const enableLinting = config.get<boolean>('enableLinting', true);
            
            if (enableLinting) {
                // Run basic syntax check
                validateOmegaFile(document, diagnosticCollection);
            }
        }
    });

    context.subscriptions.push(
        compileCommand,
        deployCommand,
        testCommand,
        onSave
    );
}

function validateOmegaFile(document: vscode.TextDocument, diagnosticCollection: vscode.DiagnosticCollection) {
    const diagnostics: vscode.Diagnostic[] = [];
    const text = document.getText();
    const lines = text.split('\n');

    // Basic syntax validation
    lines.forEach((line, index) => {
        // Check for missing semicolons (basic check)
        if (line.trim().match(/^(let|const|mapping|uint256|address|string|bool)\s+\w+.*[^;{}\s]$/)) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, 0, index, line.length),
                'Missing semicolon',
                vscode.DiagnosticSeverity.Warning
            );
            diagnostics.push(diagnostic);
        }

        // Check for unclosed brackets
        const openBrackets = (line.match(/\{/g) || []).length;
        const closeBrackets = (line.match(/\}/g) || []).length;
        if (openBrackets > closeBrackets && !line.includes('//')) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, 0, index, line.length),
                'Potential unclosed bracket',
                vscode.DiagnosticSeverity.Information
            );
            diagnostics.push(diagnostic);
        }
    });

    diagnosticCollection.set(document.uri, diagnostics);
}

export function deactivate() {
    console.log('OMEGA Language Support extension is now deactivated');
}