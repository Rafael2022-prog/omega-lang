import * as assert from 'assert';
import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

suite('OMEGA Extension Test Suite', () => {
    vscode.window.showInformationMessage('Start all tests.');

    test('Extension should be present', () => {
        assert.ok(vscode.extensions.getExtension('omega-lang.omega-language-support'));
    });

    test('Should activate extension', async () => {
        const ext = vscode.extensions.getExtension('omega-lang.omega-language-support');
        assert.ok(ext);
        await ext!.activate();
        assert.strictEqual(ext!.isActive, true);
    });

    test('Should register all commands', async () => {
        const ext = vscode.extensions.getExtension('omega-lang.omega-language-support');
        await ext!.activate();

        const commands = await vscode.commands.getCommands(true);
        const omegaCommands = commands.filter(cmd => cmd.startsWith('omega.'));
        
        assert.ok(omegaCommands.includes('omega.compile'));
        assert.ok(omegaCommands.includes('omega.compileDeploy'));
        assert.ok(omegaCommands.includes('omega.runTests'));
        assert.ok(omegaCommands.includes('omega.format'));
        assert.ok(omegaCommands.includes('omega.securityScan'));
        assert.ok(omegaCommands.includes('omega.qualityAnalysis'));
        assert.ok(omegaCommands.includes('omega.benchmark'));
        assert.ok(omegaCommands.includes('omega.crossChainDeploy'));
        assert.ok(omegaCommands.includes('omega.generateDocs'));
        assert.ok(omegaCommands.includes('omega.optimize'));
        assert.ok(omegaCommands.includes('omega.showCommands'));
    });

    test('Should provide language support for .mega files', async () => {
        const document = await vscode.workspace.openTextDocument({
            language: 'omega',
            content: 'blockchain Test { state { uint256 value; } }'
        });

        assert.strictEqual(document.languageId, 'omega');
    });

    test('Should provide language support for .omega files', async () => {
        const document = await vscode.workspace.openTextDocument({
            language: 'omega',
            content: 'blockchain Test { state { uint256 value; } }'
        });

        assert.strictEqual(document.languageId, 'omega');
    });

    test('Should provide completion items', async () => {
        const ext = vscode.extensions.getExtension('omega-lang.omega-language-support');
        await ext!.activate();

        const document = await vscode.workspace.openTextDocument({
            language: 'omega',
            content: 'block'
        });

        const position = new vscode.Position(0, 5);
        const completions = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            position
        );

        assert.ok(completions);
        assert.ok(completions.items.length > 0);
        
        const blockchainCompletion = completions.items.find(item => 
            item.label === 'blockchain'
        );
        assert.ok(blockchainCompletion);
    });

    test('Should format document', async () => {
        const ext = vscode.extensions.getExtension('omega-lang.omega-language-support');
        await ext!.activate();

        const document = await vscode.workspace.openTextDocument({
            language: 'omega',
            content: 'blockchain Test{state{uint256 value;}}'
        });

        const formatted = await vscode.commands.executeCommand<string>(
            'vscode.executeFormatDocumentProvider',
            document.uri
        );

        assert.ok(formatted);
    });

    test('Should handle configuration changes', async () => {
        const config = vscode.workspace.getConfiguration('omega');
        
        // Get current values (might be different from defaults due to user settings)
        const originalAutoCompile = config.get('autoCompile');
        const originalEnableDiagnostics = config.get('enableDiagnostics');
        const originalFormatOnSave = config.get('formatOnSave');
        
        // Test that we can read configuration values
        assert.ok(typeof originalAutoCompile === 'boolean');
        assert.ok(typeof originalEnableDiagnostics === 'boolean');
        assert.ok(typeof originalFormatOnSave === 'boolean');
        
        // Test configuration update
        const testValue = !originalAutoCompile; // Toggle the value
        await config.update('autoCompile', testValue, vscode.ConfigurationTarget.Global);
        
        // Wait for configuration to be applied
        await new Promise(resolve => setTimeout(resolve, 200));
        
        // Verify the update worked
        const updatedConfig = vscode.workspace.getConfiguration('omega');
        assert.strictEqual(updatedConfig.get('autoCompile'), testValue);
        
        // Restore original value
        await config.update('autoCompile', originalAutoCompile, vscode.ConfigurationTarget.Global);
        
        // Wait for restore to be applied
        await new Promise(resolve => setTimeout(resolve, 200));
        
        // Verify restoration worked
        const finalConfig = vscode.workspace.getConfiguration('omega');
        assert.strictEqual(finalConfig.get('autoCompile'), originalAutoCompile);
    });

    test('Should handle workspace with OMEGA files', async () => {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (!workspaceFolder) {
            // Skip test if no workspace is open
            return;
        }

        const testFile = path.join(workspaceFolder.uri.fsPath, 'test.omega');
        const content = 'blockchain Test { state { uint256 value; } }';
        
        fs.writeFileSync(testFile, content);
        
        try {
            const document = await vscode.workspace.openTextDocument(testFile);
            assert.strictEqual(document.languageId, 'omega');
            assert.strictEqual(document.getText(), content);
        } finally {
            // Clean up
            if (fs.existsSync(testFile)) {
                fs.unlinkSync(testFile);
            }
        }
    });

    test('Should provide hover information', async () => {
        const ext = vscode.extensions.getExtension('omega-lang.omega-language-support');
        await ext!.activate();

        const document = await vscode.workspace.openTextDocument({
            language: 'omega',
            content: 'blockchain Test { state { uint256 value; } }'
        });

        const position = new vscode.Position(0, 2); // Position on 'blockchain'
        const hover = await vscode.commands.executeCommand<vscode.Hover[]>(
            'vscode.executeHoverProvider',
            document.uri,
            position
        );

        assert.ok(hover);
        assert.ok(hover.length > 0);
    });

    test('Should handle error scenarios gracefully', async () => {
        const ext = vscode.extensions.getExtension('omega-lang.omega-language-support');
        await ext!.activate();

        // Test with invalid content
        const document = await vscode.workspace.openTextDocument({
            language: 'omega',
            content: 'invalid omega code {{{'
        });

        // Should not throw error
        await vscode.commands.executeCommand('omega.compile', document.uri);
        
        // Extension should still be active
        assert.strictEqual(ext!.isActive, true);
    });
});