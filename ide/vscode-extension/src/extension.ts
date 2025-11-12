import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    console.log('OMEGA Language Support extension is now active!');

    // Register the compile command
    let compileCommand = vscode.commands.registerCommand('omega.compile', () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active OMEGA file');
            return;
        }

        const document = editor.document;
        if (document.languageId !== 'omega') {
            vscode.window.showErrorMessage('Current file is not an OMEGA file');
            return;
        }

        // Simple compilation simulation
        vscode.window.showInformationMessage(`Compiling ${document.fileName}...`);
        
        // Simulate compilation delay
        setTimeout(() => {
            vscode.window.showInformationMessage('OMEGA compilation completed successfully!');
        }, 2000);
    });

    context.subscriptions.push(compileCommand);

    // Register completion provider
    const provider = vscode.languages.registerCompletionItemProvider('omega', {
        provideCompletionItems(document: vscode.TextDocument, position: vscode.Position) {
            const linePrefix = document.lineAt(position).text.substr(0, position.character);
            
            const completions = [
                new vscode.CompletionItem('blockchain', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('state', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('function', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('constructor', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('public', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('private', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('view', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('pure', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('payable', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('returns', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('require', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('emit', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('mapping', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('address', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('uint256', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('string', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('bool', vscode.CompletionItemKind.Keyword),
                new vscode.CompletionItem('event', vscode.CompletionItemKind.Keyword)
            ];

            return completions;
        }
    }, ' ', '.');

    context.subscriptions.push(provider);
}

export function deactivate() {
    console.log('OMEGA Language Support extension is now deactivated');
}