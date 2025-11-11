import {
    createConnection,
    TextDocuments,
    Diagnostic,
    DiagnosticSeverity,
    ProposedFeatures,
    InitializeParams,
    DidChangeConfigurationNotification,
    CompletionItem,
    CompletionItemKind,
    TextDocumentPositionParams,
    TextDocumentSyncKind,
    InitializeResult,
    DocumentDiagnosticReportKind,
    type DocumentDiagnosticReport,
    SemanticTokensBuilder,
    SemanticTokensLegend,
    SemanticTokensParams,
    SemanticTokens,
    HoverParams,
    Hover,
    DefinitionParams,
    Definition,
    ReferenceParams,
    Location,
    DocumentSymbolParams,
    DocumentSymbol,
    SymbolKind,
    FoldingRangeParams,
    FoldingRange,
    CodeActionParams,
    CodeAction,
    WorkspaceSymbolParams,
    SymbolInformation,
    RenameParams,
    WorkspaceEdit,
    CodeLensParams,
    CodeLens,
    DocumentColorParams,
    ColorInformation,
    ColorPresentationParams,
    ColorPresentation,
    FormattingOptions,
    DocumentFormattingParams,
    TextEdit
} from 'vscode-languageserver/node';

import { TextDocument } from 'vscode-languageserver-textdocument';
import { OmegaParser } from './parser/omegaParser';
import { OmegaAnalyzer } from './analyzer/omegaAnalyzer';
import { OmegaCompiler } from './compiler/omegaCompiler';
import { OmegaDiagnosticsProvider } from './providers/diagnosticsProvider';
import { OmegaCompletionProvider } from './providers/completionProvider';
import { OmegaHoverProvider } from './providers/hoverProvider';
import { OmegaDefinitionProvider } from './providers/definitionProvider';
import { OmegaReferenceProvider } from './providers/referenceProvider';
import { OmegaSymbolProvider } from './providers/symbolProvider';
import { OmegaFoldingRangeProvider } from './providers/foldingRangeProvider';
import { OmegaCodeActionProvider } from './providers/codeActionProvider';
import { OmegaCodeLensProvider } from './providers/codeLensProvider';
import { OmegaColorProvider } from './providers/colorProvider';
import { OmegaFormattingProvider } from './providers/formattingProvider';
import { OmegaRenameProvider } from './providers/renameProvider';
import { OmegaWorkspaceSymbolProvider } from './providers/workspaceSymbolProvider';
import { OmegaSemanticTokensProvider } from './providers/semanticTokensProvider';
import { OmegaConfiguration } from './configuration/configuration';
import { OmegaLogger } from './utils/logger';
import { OmegaTelemetry } from './utils/telemetry';
import { OmegaErrorHandler } from './utils/errorHandler';
import { OmegaPerformanceMonitor } from './performance/performanceMonitor';
import { OmegaSecurityScanner } from './security/securityScanner';
import { OmegaPackageManager } from './package/packageManager';
import { OmegaProjectManager } from './project/projectManager';

// Create a connection for the server
const connection = createConnection(ProposedFeatures.all);

// Create a simple text document manager
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

// Initialize core components
let config: OmegaConfiguration;
let logger: OmegaLogger;
let telemetry: OmegaTelemetry;
let errorHandler: OmegaErrorHandler;
let performanceMonitor: OmegaPerformanceMonitor;
let securityScanner: OmegaSecurityScanner;
let packageManager: OmegaPackageManager;
let projectManager: OmegaProjectManager;

let parser: OmegaParser;
let analyzer: OmegaAnalyzer;
let compiler: OmegaCompiler;

let diagnosticsProvider: OmegaDiagnosticsProvider;
let completionProvider: OmegaCompletionProvider;
let hoverProvider: OmegaHoverProvider;
let definitionProvider: OmegaDefinitionProvider;
let referenceProvider: OmegaReferenceProvider;
let symbolProvider: OmegaSymbolProvider;
let foldingRangeProvider: OmegaFoldingRangeProvider;
let codeActionProvider: OmegaCodeActionProvider;
let codeLensProvider: OmegaCodeLensProvider;
let colorProvider: OmegaColorProvider;
let formattingProvider: OmegaFormattingProvider;
let renameProvider: OmegaRenameProvider;
let workspaceSymbolProvider: OmegaWorkspaceSymbolProvider;
let semanticTokensProvider: OmegaSemanticTokensProvider;

connection.onInitialize((params: InitializeParams) => {
    const capabilities = params.capabilities;

    // Does the client support the `workspace/configuration` request?
    // If not, we will fall back using global settings
    hasConfigurationCapability = !!(
        capabilities.workspace && !!capabilities.workspace.configuration
    );
    hasWorkspaceFolderCapability = !!(
        capabilities.workspace && !!capabilities.workspace.workspaceFolders
    );
    hasDiagnosticRelatedInformationCapability = !!(
        capabilities.textDocument &&
        capabilities.textDocument.publishDiagnostics &&
        capabilities.textDocument.publishDiagnostics.relatedInformation
    );

    // Initialize configuration
    config = new OmegaConfiguration(params.initializationOptions?.config);
    
    // Initialize logger
    logger = new OmegaLogger(config.getLogLevel());
    
    // Initialize telemetry
    telemetry = new OmegaTelemetry(config.isTelemetryEnabled());
    
    // Initialize error handler
    errorHandler = new OmegaErrorHandler(logger);
    
    // Initialize performance monitor
    performanceMonitor = new OmegaPerformanceMonitor(config.getPerformanceConfig());
    
    // Initialize security scanner
    securityScanner = new OmegaSecurityScanner(config.getSecurityConfig());
    
    // Initialize package manager
    packageManager = new OmegaPackageManager(config.getPackageConfig());
    
    // Initialize project manager
    projectManager = new OmegaProjectManager(config.getProjectConfig());
    
    // Initialize language components
    parser = new OmegaParser(logger, errorHandler);
    analyzer = new OmegaAnalyzer(logger, errorHandler, config.getAnalyzerConfig());
    compiler = new OmegaCompiler(logger, errorHandler, config.getCompilerConfig());
    
    // Initialize providers
    diagnosticsProvider = new OmegaDiagnosticsProvider(logger, errorHandler);
    completionProvider = new OmegaCompletionProvider(logger, errorHandler);
    hoverProvider = new OmegaHoverProvider(logger, errorHandler);
    definitionProvider = new OmegaDefinitionProvider(logger, errorHandler);
    referenceProvider = new OmegaReferenceProvider(logger, errorHandler);
    symbolProvider = new OmegaSymbolProvider(logger, errorHandler);
    foldingRangeProvider = new OmegaFoldingRangeProvider(logger, errorHandler);
    codeActionProvider = OmegaCodeActionProvider(logger, errorHandler);
    codeLensProvider = new OmegaCodeLensProvider(logger, errorHandler);
    colorProvider = new OmegaColorProvider(logger, errorHandler);
    formattingProvider = new OmegaFormattingProvider(logger, errorHandler);
    renameProvider = new OmegaRenameProvider(logger, errorHandler);
    workspaceSymbolProvider = new OmegaWorkspaceSymbolProvider(logger, errorHandler);
    semanticTokensProvider = new OmegaSemanticTokensProvider(logger, errorHandler);

    const result: InitializeResult = {
        capabilities: {
            textDocumentSync: TextDocumentSyncKind.Incremental,
            // Tell the client that this server supports code completion
            completionProvider: {
                resolveProvider: true,
                triggerCharacters: ['.', ':', '(', '[', '{', ' ', '@', '#']
            },
            hoverProvider: true,
            definitionProvider: true,
            referencesProvider: true,
            documentSymbolProvider: true,
            workspaceSymbolProvider: true,
            documentFormattingProvider: true,
            documentRangeFormattingProvider: true,
            codeLensProvider: {
                resolveProvider: true
            },
            renameProvider: {
                prepareProvider: true
            },
            documentHighlightProvider: true,
            codeActionProvider: {
                codeActionKinds: [
                    'quickfix',
                    'refactor',
                    'refactor.extract',
                    'refactor.inline',
                    'refactor.rewrite',
                    'source',
                    'source.organizeImports',
                    'source.fixAll'
                ]
            },
            foldingRangeProvider: true,
            documentColorProvider: true,
            colorProvider: true,
            semanticTokensProvider: {
                legend: getSemanticTokensLegend(),
                range: false,
                full: {
                    delta: true
                }
            },
            diagnosticProvider: {
                interFileDependencies: true,
                workspaceDiagnostics: true
            }
        }
    };
    if (hasWorkspaceFolderCapability) {
        result.capabilities.workspace = {
            workspaceFolders: {
                supported: true
            }
        };
    }

    return result;
});

connection.onInitialized(() => {
    if (hasConfigurationCapability) {
        // Register for all configuration changes
        connection.client.register(DidChangeConfigurationNotification.type, undefined);
    }
    if (hasWorkspaceFolderCapability) {
        connection.workspace.onDidChangeWorkspaceFolders(_event => {
            connection.console.log('Workspace folder change event received');
        });
    }

    // Start performance monitoring
    performanceMonitor.start();
    
    // Send telemetry event
    telemetry.sendEvent('serverInitialized', {
        hasConfigurationCapability,
        hasWorkspaceFolderCapability,
        hasDiagnosticRelatedInformationCapability
    });
});

// The global settings, used when the `workspace/configuration` request is not supported by the client
interface OmegaSettings {
    maxNumberOfProblems: number;
    enableDiagnostics: boolean;
    enableCodeActions: boolean;
    enableCodeLens: boolean;
    enableFormatting: boolean;
    enableHover: boolean;
    enableCompletion: boolean;
    enableSemanticTokens: boolean;
    enableSecurityScanning: boolean;
    enablePerformanceMonitoring: boolean;
    compilerPath: string;
    targetPlatforms: string[];
    optimizationLevel: string;
    debugMode: boolean;
}

// The example settings
const defaultSettings: OmegaSettings = {
    maxNumberOfProblems: 1000,
    enableDiagnostics: true,
    enableCodeActions: true,
    enableCodeLens: true,
    enableFormatting: true,
    enableHover: true,
    enableCompletion: true,
    enableSemanticTokens: true,
    enableSecurityScanning: true,
    enablePerformanceMonitoring: true,
    compilerPath: 'omega',
    targetPlatforms: ['evm', 'solana'],
    optimizationLevel: 'standard',
    debugMode: false
};
let globalSettings: OmegaSettings = defaultSettings;

// Cache the settings of all open documents
const documentSettings: Map<string, Thenable<OmegaSettings>> = new Map();

connection.onDidChangeConfiguration(change => {
    if (hasConfigurationCapability) {
        // Reset all cached document settings
        documentSettings.clear();
    } else {
        globalSettings = <OmegaSettings>(
            (change.settings.omega || defaultSettings)
        );
    }

    // Revalidate all open text documents
    documents.all().forEach(validateTextDocument);
});

function getDocumentSettings(resource: string): Thenable<OmegaSettings> {
    if (!hasConfigurationCapability) {
        return Promise.resolve(globalSettings);
    }
    let result = documentSettings.get(resource);
    if (!result) {
        result = connection.sendRequest<OmegaSettings>('workspace/configuration', {
            items: [{ section: 'omega', scopeUri: resource }]
        });
        documentSettings.set(resource, result);
    }
    return result;
}

// Only keep settings for open documents
documents.onDidClose(e => {
    documentSettings.delete(e.document.uri);
});

// The content of a text document has changed. This event is emitted
// when the text document first opened or when its content has changed.
documents.onDidChangeContent(change => {
    validateTextDocument(change.document);
});

async function validateTextDocument(textDocument: TextDocument): Promise<void> {
    const startTime = performance.now();
    
    try {
        // Get the settings for the validate command
        const settings = await getDocumentSettings(textDocument.uri);
        
        if (!settings.enableDiagnostics) {
            return;
        }

        // Parse the document
        const parseResult = await parser.parse(textDocument.getText(), textDocument.uri);
        
        // Analyze the parsed result
        const analysisResult = await analyzer.analyze(parseResult);
        
        // Get diagnostics
        const diagnostics = await diagnosticsProvider.getDiagnostics(
            textDocument,
            parseResult,
            analysisResult
        );

        // Limit the number of diagnostics based on settings
        const limitedDiagnostics = diagnostics.slice(0, settings.maxNumberOfProblems);

        // Send the computed diagnostics to VS Code
        connection.sendDiagnostics({ uri: textDocument.uri, diagnostics: limitedDiagnostics });
        
        // Record performance metrics
        const endTime = performance.now();
        performanceMonitor.recordMetric('validation_time', endTime - startTime);
        
        // Send telemetry
        telemetry.sendEvent('documentValidated', {
            diagnosticCount: limitedDiagnostics.length,
            validationTime: endTime - startTime
        });
        
    } catch (error) {
        errorHandler.handleError(error, 'validateTextDocument');
        
        // Send error diagnostic
        const errorDiagnostic: Diagnostic = {
            severity: DiagnosticSeverity.Error,
            range: {
                start: { line: 0, character: 0 },
                end: { line: 0, character: 0 }
            },
            message: `Validation error: ${error.message}`,
            source: 'omega'
        };
        
        connection.sendDiagnostics({ uri: textDocument.uri, diagnostics: [errorDiagnostic] });
    }
}

connection.languages.diagnostics.on(async (params) => {
    const document = documents.get(params.textDocument.uri);
    if (document === undefined) {
        return {
            kind: DocumentDiagnosticReportKind.Full,
            resultId: 'omega-diagnostics',
            items: []
        } satisfies DocumentDiagnosticReport;
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableDiagnostics) {
            return {
                kind: DocumentDiagnosticReportKind.Full,
                resultId: 'omega-diagnostics',
                items: []
            } satisfies DocumentDiagnosticReport;
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Analyze the parsed result
        const analysisResult = await analyzer.analyze(parseResult);
        
        // Get diagnostics
        const diagnostics = await diagnosticsProvider.getDiagnostics(
            document,
            parseResult,
            analysisResult
        );

        return {
            kind: DocumentDiagnosticReportKind.Full,
            resultId: 'omega-diagnostics',
            items: diagnostics
        } satisfies DocumentDiagnosticReport;
        
    } catch (error) {
        errorHandler.handleError(error, 'onDiagnostics');
        return {
            kind: DocumentDiagnosticReportKind.Full,
            resultId: 'omega-diagnostics',
            items: []
        } satisfies DocumentDiagnosticReport;
    }
});

connection.languages.diagnostics.onWorkspace(async (params) => {
    const workspaceDiagnostics: DocumentDiagnosticReport[] = [];
    
    for (const document of documents.all()) {
        try {
            const settings = await getDocumentSettings(document.uri);
            
            if (!settings.enableDiagnostics) {
                continue;
            }

            // Parse the document
            const parseResult = await parser.parse(document.getText(), document.uri);
            
            // Analyze the parsed result
            const analysisResult = await analyzer.analyze(parseResult);
            
            // Get diagnostics
            const diagnostics = await diagnosticsProvider.getDiagnostics(
                document,
                parseResult,
                analysisResult
            );

            workspaceDiagnostics.push({
                kind: DocumentDiagnosticReportKind.Full,
                resultId: 'omega-diagnostics',
                uri: document.uri,
                items: diagnostics
            });
            
        } catch (error) {
            errorHandler.handleError(error, 'onWorkspaceDiagnostics');
        }
    }
    
    return workspaceDiagnostics;
});

connection.onCompletion(async (params: TextDocumentPositionParams): Promise<CompletionItem[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableCompletion) {
            return [];
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get completions
        const completions = await completionProvider.getCompletions(
            document,
            params.position,
            parseResult
        );

        return completions;
        
    } catch (error) {
        errorHandler.handleError(error, 'onCompletion');
        return [];
    }
});

connection.onCompletionResolve(async (item: CompletionItem): Promise<CompletionItem> => {
    try {
        const resolvedItem = await completionProvider.resolveCompletionItem(item);
        return resolvedItem;
    } catch (error) {
        errorHandler.handleError(error, 'onCompletionResolve');
        return item;
    }
});

connection.onHover(async (params: HoverParams): Promise<Hover | null> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return null;
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableHover) {
            return null;
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get hover information
        const hover = await hoverProvider.getHover(
            document,
            params.position,
            parseResult
        );

        return hover;
        
    } catch (error) {
        errorHandler.handleError(error, 'onHover');
        return null;
    }
});

connection.onDefinition(async (params: DefinitionParams): Promise<Definition | null> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return null;
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get definition
        const definition = await definitionProvider.getDefinition(
            document,
            params.position,
            parseResult
        );

        return definition;
        
    } catch (error) {
        errorHandler.handleError(error, 'onDefinition');
        return null;
    }
});

connection.onReferences(async (params: ReferenceParams): Promise<Location[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get references
        const references = await referenceProvider.getReferences(
            document,
            params.position,
            params.context,
            parseResult
        );

        return references;
        
    } catch (error) {
        errorHandler.handleError(error, 'onReferences');
        return [];
    }
});

connection.onDocumentSymbol(async (params: DocumentSymbolParams): Promise<DocumentSymbol[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get document symbols
        const symbols = await symbolProvider.getDocumentSymbols(
            document,
            parseResult
        );

        return symbols;
        
    } catch (error) {
        errorHandler.handleError(error, 'onDocumentSymbol');
        return [];
    }
});

connection.onFoldingRanges(async (params: FoldingRangeParams): Promise<FoldingRange[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get folding ranges
        const foldingRanges = await foldingRangeProvider.getFoldingRanges(
            document,
            parseResult
        );

        return foldingRanges;
        
    } catch (error) {
        errorHandler.handleError(error, 'onFoldingRanges');
        return [];
    }
});

connection.onCodeAction(async (params: CodeActionParams): Promise<CodeAction[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableCodeActions) {
            return [];
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get code actions
        const codeActions = await codeActionProvider.getCodeActions(
            document,
            params.range,
            params.context,
            parseResult
        );

        return codeActions;
        
    } catch (error) {
        errorHandler.handleError(error, 'onCodeAction');
        return [];
    }
});

connection.onCodeLens(async (params: CodeLensParams): Promise<CodeLens[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableCodeLens) {
            return [];
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get code lenses
        const codeLenses = await codeLensProvider.getCodeLenses(
            document,
            parseResult
        );

        return codeLenses;
        
    } catch (error) {
        errorHandler.handleError(error, 'onCodeLens');
        return [];
    }
});

connection.onCodeLensResolve(async (codeLens: CodeLens): Promise<CodeLens> => {
    try {
        const resolvedCodeLens = await codeLensProvider.resolveCodeLens(codeLens);
        return resolvedCodeLens;
    } catch (error) {
        errorHandler.handleError(error, 'onCodeLensResolve');
        return codeLens;
    }
});

connection.onDocumentColor(async (params: DocumentColorParams): Promise<ColorInformation[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get color information
        const colors = await colorProvider.getDocumentColors(
            document,
            parseResult
        );

        return colors;
        
    } catch (error) {
        errorHandler.handleError(error, 'onDocumentColor');
        return [];
    }
});

connection.onColorPresentation(async (params: ColorPresentationParams): Promise<ColorPresentation[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get color presentations
        const presentations = await colorProvider.getColorPresentations(
            document,
            params.color,
            params.range,
            parseResult
        );

        return presentations;
        
    } catch (error) {
        errorHandler.handleError(error, 'onColorPresentation');
        return [];
    }
});

connection.onDocumentFormatting(async (params: DocumentFormattingParams): Promise<TextEdit[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableFormatting) {
            return [];
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get formatting edits
        const edits = await formattingProvider.getFormattingEdits(
            document,
            params.options,
            parseResult
        );

        return edits;
        
    } catch (error) {
        errorHandler.handleError(error, 'onDocumentFormatting');
        return [];
    }
});

connection.onDocumentRangeFormatting(async (params: DocumentFormattingParams): Promise<TextEdit[]> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return [];
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableFormatting) {
            return [];
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get range formatting edits
        const edits = await formattingProvider.getRangeFormattingEdits(
            document,
            params.options,
            parseResult
        );

        return edits;
        
    } catch (error) {
        errorHandler.handleError(error, 'onDocumentRangeFormatting');
        return [];
    }
});

connection.onRenameRequest(async (params: RenameParams): Promise<WorkspaceEdit | null> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return null;
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get rename edit
        const edit = await renameProvider.getRenameEdit(
            document,
            params.position,
            params.newName,
            parseResult
        );

        return edit;
        
    } catch (error) {
        errorHandler.handleError(error, 'onRenameRequest');
        return null;
    }
});

connection.onPrepareRename(async (params: RenameParams): Promise<{ range: Range; placeholder: string } | null> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return null;
    }

    try {
        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get rename preparation
        const preparation = await renameProvider.getRenamePreparation(
            document,
            params.position,
            parseResult
        );

        return preparation;
        
    } catch (error) {
        errorHandler.handleError(error, 'onPrepareRename');
        return null;
    }
});

connection.onWorkspaceSymbol(async (params: WorkspaceSymbolParams): Promise<SymbolInformation[]> => {
    try {
        // Get workspace symbols
        const symbols = await workspaceSymbolProvider.getWorkspaceSymbols(
            params.query
        );

        return symbols;
        
    } catch (error) {
        errorHandler.handleError(error, 'onWorkspaceSymbol');
        return [];
    }
});

connection.languages.semanticTokens.on(async (params: SemanticTokensParams): Promise<SemanticTokens> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return { data: [] };
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableSemanticTokens) {
            return { data: [] };
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get semantic tokens
        const tokens = await semanticTokensProvider.getSemanticTokens(
            document,
            parseResult
        );

        return tokens;
        
    } catch (error) {
        errorHandler.handleError(error, 'onSemanticTokens');
        return { data: [] };
    }
});

connection.languages.semanticTokens.onDelta(async (params: SemanticTokensParams): Promise<SemanticTokens> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
        return { data: [] };
    }

    try {
        const settings = await getDocumentSettings(params.textDocument.uri);
        
        if (!settings.enableSemanticTokens) {
            return { data: [] };
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Get semantic tokens delta
        const tokens = await semanticTokensProvider.getSemanticTokensDelta(
            document,
            params.textDocument.version,
            parseResult
        );

        return tokens;
        
    } catch (error) {
        errorHandler.handleError(error, 'onSemanticTokensDelta');
        return { data: [] };
    }
});

// Custom notification handlers
connection.onNotification('omega/compile', async (params: { uri: string; target: string }) => {
    try {
        const document = documents.get(params.uri);
        if (!document) {
            connection.sendNotification('omega/compileResult', {
                success: false,
                error: 'Document not found'
            });
            return;
        }

        // Parse the document
        const parseResult = await parser.parse(document.getText(), document.uri);
        
        // Analyze the parsed result
        const analysisResult = await analyzer.analyze(parseResult);
        
        // Compile to target
        const compileResult = await compiler.compile(analysisResult, params.target);

        connection.sendNotification('omega/compileResult', {
            success: true,
            result: compileResult
        });
        
    } catch (error) {
        errorHandler.handleError(error, 'omega/compile');
        connection.sendNotification('omega/compileResult', {
            success: false,
            error: error.message
        });
    }
});

connection.onNotification('omega/test', async (params: { uri: string }) => {
    try {
        const document = documents.get(params.uri);
        if (!document) {
            connection.sendNotification('omega/testResult', {
                success: false,
                error: 'Document not found'
            });
            return;
        }

        // Run tests
        const testResult = await runTests(document);

        connection.sendNotification('omega/testResult', {
            success: true,
            result: testResult
        });
        
    } catch (error) {
        errorHandler.handleError(error, 'omega/test');
        connection.sendNotification('omega/testResult', {
            success: false,
            error: error.message
        });
    }
});

connection.onNotification('omega/securityScan', async (params: { uri: string }) => {
    try {
        const document = documents.get(params.uri);
        if (!document) {
            connection.sendNotification('omega/securityScanResult', {
                success: false,
                error: 'Document not found'
            });
            return;
        }

        // Run security scan
        const scanResult = await securityScanner.scan(document);

        connection.sendNotification('omega/securityScanResult', {
            success: true,
            result: scanResult
        });
        
    } catch (error) {
        errorHandler.handleError(error, 'omega/securityScan');
        connection.sendNotification('omega/securityScanResult', {
            success: false,
            error: error.message
        });
    }
});

connection.onNotification('omega/performanceProfile', async (params: { uri: string }) => {
    try {
        const document = documents.get(params.uri);
        if (!document) {
            connection.sendNotification('omega/performanceProfileResult', {
                success: false,
                error: 'Document not found'
            });
            return;
        }

        // Run performance profiling
        const profileResult = await performanceMonitor.profile(document);

        connection.sendNotification('omega/performanceProfileResult', {
            success: true,
            result: profileResult
        });
        
    } catch (error) {
        errorHandler.handleError(error, 'omega/performanceProfile');
        connection.sendNotification('omega/performanceProfileResult', {
            success: false,
            error: error.message
        });
    }
});

async function runTests(document: TextDocument): Promise<any> {
    // Implement test runner
    // This would integrate with the testing framework
    return {
        tests: [],
        summary: {
            total: 0,
            passed: 0,
            failed: 0,
            skipped: 0
        }
    };
}

function getSemanticTokensLegend(): SemanticTokensLegend {
    return {
        tokenTypes: [
            'namespace', 'type', 'class', 'enum', 'interface', 'struct',
            'typeParameter', 'parameter', 'variable', 'property', 'enumMember',
            'event', 'function', 'method', 'macro', 'keyword', 'modifier',
            'comment', 'string', 'number', 'regexp', 'operator'
        ],
        tokenModifiers: [
            'declaration', 'definition', 'readonly', 'static', 'deprecated',
            'abstract', 'async', 'modification', 'documentation', 'defaultLibrary'
        ]
    };
}

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen();

// Handle server shutdown
connection.onShutdown(() => {
    // Clean up resources
    performanceMonitor.stop();
    telemetry.sendEvent('serverShutdown');
});

// Handle server exit
connection.onExit(() => {
    process.exit(0);
});