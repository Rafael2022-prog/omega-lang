import * as vscode from 'vscode';

export interface OmegaConfiguration {
    // Language Server Configuration
    languageServer: {
        path: string;
        args: string[];
        env: Record<string, string>;
        maxMemory: number;
        timeout: number;
    };
    
    // Compiler Configuration
    compiler: {
        path: string;
        targetPlatforms: string[];
        optimizationLevel: 'none' | 'basic' | 'standard' | 'aggressive';
        debugMode: boolean;
        enableParallelCompilation: boolean;
        maxThreads: number;
        outputDirectory: string;
        tempDirectory: string;
    };
    
    // Language Features
    features: {
        enableDiagnostics: boolean;
        enableCodeActions: boolean;
        enableCodeLens: boolean;
        enableFormatting: boolean;
        enableHover: boolean;
        enableCompletion: boolean;
        enableSemanticTokens: boolean;
        enableSecurityScanning: boolean;
        enablePerformanceMonitoring: boolean;
        enableCrossCompilation: boolean;
        enableBootstrapCompiler: boolean;
    };
    
    // Diagnostics Configuration
    diagnostics: {
        maxNumberOfProblems: number;
        showWarnings: boolean;
        showInfos: boolean;
        showHints: boolean;
        enableRelatedInformation: boolean;
        enableCodeDescription: boolean;
        severityOverrides: Record<string, 'error' | 'warning' | 'info' | 'hint'>;
    };
    
    // Completion Configuration
    completion: {
        triggerCharacters: string[];
        resolveProvider: boolean;
        enableSnippets: boolean;
        enableAutoImport: boolean;
        enableContextAwareCompletion: boolean;
        maxItems: number;
    };
    
    // Formatting Configuration
    formatting: {
        enable: boolean;
        enableOnSave: boolean;
        enableOnType: boolean;
        tabSize: number;
        insertSpaces: boolean;
        maxLineLength: number;
        braceStyle: 'allman' | 'k&r' | 'stroustrup' | 'whitesmiths' | 'gnu';
        indentStyle: 'space' | 'tab';
        newlineStyle: 'lf' | 'crlf' | 'auto';
    };
    
    // Hover Configuration
    hover: {
        enable: boolean;
        showDocumentation: boolean;
        showTypeInformation: boolean;
        showDefinition: boolean;
        showReferences: boolean;
        delay: number;
    };
    
    // Code Lens Configuration
    codeLens: {
        enable: boolean;
        showReferences: boolean;
        showImplementations: boolean;
        showTests: boolean;
        showPerformanceMetrics: boolean;
        showSecurityInfo: boolean;
        resolveProvider: boolean;
    };
    
    // Security Configuration
    security: {
        enableScanning: boolean;
        enableVulnerabilityDetection: boolean;
        enableStaticAnalysis: boolean;
        enableFuzzing: boolean;
        severityThreshold: 'low' | 'medium' | 'high' | 'critical';
        autoFix: boolean;
        showNotifications: boolean;
    };
    
    // Performance Configuration
    performance: {
        enableMonitoring: boolean;
        enableProfiling: boolean;
        enableMetrics: boolean;
        enableAlerts: boolean;
        alertThresholds: {
            compilationTime: number;
            memoryUsage: number;
            cpuUsage: number;
            diskIO: number;
        };
        metricsRetention: number;
        samplingInterval: number;
    };
    
    // Testing Configuration
    testing: {
        enable: boolean;
        autoRun: boolean;
        showCodeLens: boolean;
        showDecorations: boolean;
        enableCoverage: boolean;
        coverageThreshold: number;
        testFramework: 'builtin' | 'custom';
        timeout: number;
    };
    
    // Package Management Configuration
    packages: {
        enable: boolean;
        registryUrl: string;
        autoUpdate: boolean;
        enableSecurityScan: boolean;
        cacheDirectory: string;
        proxy: string;
        timeout: number;
    };
    
    // Debugging Configuration
    debugging: {
        enable: boolean;
        enableBreakpoints: boolean;
        enableStepThrough: boolean;
        enableVariableInspection: boolean;
        enableCallStack: boolean;
        enableMemoryInspection: boolean;
        enablePerformanceProfiling: boolean;
    };
    
    // Deployment Configuration
    deployment: {
        enable: boolean;
        enableNetworkSelection: boolean;
        enableGasEstimation: boolean;
        enableTransactionPreview: boolean;
        enableMultiSig: boolean;
        enableAuditTrail: boolean;
        networks: Record<string, {
            url: string;
            chainId: number;
            gasPrice: string;
            gasLimit: number;
            privateKey: string;
            mnemonic: string;
            explorerUrl: string;
        }>;
    };
    
    // UI Configuration
    ui: {
        showStatusBar: boolean;
        showOutputChannel: boolean;
        showTerminal: boolean;
        showWelcomeNotification: boolean;
        revealOutputChannelOn: 'info' | 'warn' | 'error' | 'never';
        enableNotifications: boolean;
        notificationLevel: 'error' | 'warning' | 'info' | 'debug';
    };
    
    // Telemetry Configuration
    telemetry: {
        enable: boolean;
        enableCrashReporting: boolean;
        enableUsageReporting: boolean;
        enablePerformanceReporting: boolean;
        enableErrorReporting: boolean;
        endpoint: string;
        interval: number;
    };
    
    // Advanced Configuration
    advanced: {
        enableExperimentalFeatures: boolean;
        enableDebugMode: boolean;
        enableVerboseLogging: boolean;
        enableTracing: boolean;
        traceServer: 'off' | 'messages' | 'verbose';
        enableCustomCommands: boolean;
        enableScripting: boolean;
        enableAutomation: boolean;
    };
}

export class ConfigurationManager {
    private static instance: ConfigurationManager;
    private config: OmegaConfiguration;
    private disposables: vscode.Disposable[] = [];
    
    private constructor() {
        this.config = this.loadConfiguration();
        this.setupConfigurationChangeListener();
    }
    
    public static getInstance(): ConfigurationManager {
        if (!ConfigurationManager.instance) {
            ConfigurationManager.instance = new ConfigurationManager();
        }
        return ConfigurationManager.instance;
    }
    
    public getConfiguration(): OmegaConfiguration {
        return this.config;
    }
    
    public reloadConfiguration(): void {
        this.config = this.loadConfiguration();
    }
    
    private loadConfiguration(): OmegaConfiguration {
        const workspaceConfig = vscode.workspace.getConfiguration('omega');
        
        return {
            languageServer: {
                path: workspaceConfig.get('languageServer.path', 'omega-language-server'),
                args: workspaceConfig.get('languageServer.args', []),
                env: workspaceConfig.get('languageServer.env', {}),
                maxMemory: workspaceConfig.get('languageServer.maxMemory', 512),
                timeout: workspaceConfig.get('languageServer.timeout', 30000)
            },
            
            compiler: {
                path: workspaceConfig.get('compiler.path', 'omega'),
                targetPlatforms: workspaceConfig.get('compiler.targetPlatforms', ['evm', 'solana']),
                optimizationLevel: workspaceConfig.get('compiler.optimizationLevel', 'standard'),
                debugMode: workspaceConfig.get('compiler.debugMode', false),
                enableParallelCompilation: workspaceConfig.get('compiler.enableParallelCompilation', true),
                maxThreads: workspaceConfig.get('compiler.maxThreads', 4),
                outputDirectory: workspaceConfig.get('compiler.outputDirectory', './build'),
                tempDirectory: workspaceConfig.get('compiler.tempDirectory', './tmp')
            },
            
            features: {
                enableDiagnostics: workspaceConfig.get('features.enableDiagnostics', true),
                enableCodeActions: workspaceConfig.get('features.enableCodeActions', true),
                enableCodeLens: workspaceConfig.get('features.enableCodeLens', true),
                enableFormatting: workspaceConfig.get('features.enableFormatting', true),
                enableHover: workspaceConfig.get('features.enableHover', true),
                enableCompletion: workspaceConfig.get('features.enableCompletion', true),
                enableSemanticTokens: workspaceConfig.get('features.enableSemanticTokens', true),
                enableSecurityScanning: workspaceConfig.get('features.enableSecurityScanning', true),
                enablePerformanceMonitoring: workspaceConfig.get('features.enablePerformanceMonitoring', true),
                enableCrossCompilation: workspaceConfig.get('features.enableCrossCompilation', true),
                enableBootstrapCompiler: workspaceConfig.get('features.enableBootstrapCompiler', true)
            },
            
            diagnostics: {
                maxNumberOfProblems: workspaceConfig.get('diagnostics.maxNumberOfProblems', 1000),
                showWarnings: workspaceConfig.get('diagnostics.showWarnings', true),
                showInfos: workspaceConfig.get('diagnostics.showInfos', true),
                showHints: workspaceConfig.get('diagnostics.showHints', true),
                enableRelatedInformation: workspaceConfig.get('diagnostics.enableRelatedInformation', true),
                enableCodeDescription: workspaceConfig.get('diagnostics.enableCodeDescription', true),
                severityOverrides: workspaceConfig.get('diagnostics.severityOverrides', {})
            },
            
            completion: {
                triggerCharacters: workspaceConfig.get('completion.triggerCharacters', ['.', ':', '(', '[', '{', ' ', '@', '#']),
                resolveProvider: workspaceConfig.get('completion.resolveProvider', true),
                enableSnippets: workspaceConfig.get('completion.enableSnippets', true),
                enableAutoImport: workspaceConfig.get('completion.enableAutoImport', true),
                enableContextAwareCompletion: workspaceConfig.get('completion.enableContextAwareCompletion', true),
                maxItems: workspaceConfig.get('completion.maxItems', 50)
            },
            
            formatting: {
                enable: workspaceConfig.get('formatting.enable', true),
                enableOnSave: workspaceConfig.get('formatting.enableOnSave', true),
                enableOnType: workspaceConfig.get('formatting.enableOnType', false),
                tabSize: workspaceConfig.get('formatting.tabSize', 4),
                insertSpaces: workspaceConfig.get('formatting.insertSpaces', true),
                maxLineLength: workspaceConfig.get('formatting.maxLineLength', 120),
                braceStyle: workspaceConfig.get('formatting.braceStyle', 'allman'),
                indentStyle: workspaceConfig.get('formatting.indentStyle', 'space'),
                newlineStyle: workspaceConfig.get('formatting.newlineStyle', 'lf')
            },
            
            hover: {
                enable: workspaceConfig.get('hover.enable', true),
                showDocumentation: workspaceConfig.get('hover.showDocumentation', true),
                showTypeInformation: workspaceConfig.get('hover.showTypeInformation', true),
                showDefinition: workspaceConfig.get('hover.showDefinition', true),
                showReferences: workspaceConfig.get('hover.showReferences', true),
                delay: workspaceConfig.get('hover.delay', 300)
            },
            
            codeLens: {
                enable: workspaceConfig.get('codeLens.enable', true),
                showReferences: workspaceConfig.get('codeLens.showReferences', true),
                showImplementations: workspaceConfig.get('codeLens.showImplementations', true),
                showTests: workspaceConfig.get('codeLens.showTests', true),
                showPerformanceMetrics: workspaceConfig.get('codeLens.showPerformanceMetrics', true),
                showSecurityInfo: workspaceConfig.get('codeLens.showSecurityInfo', true),
                resolveProvider: workspaceConfig.get('codeLens.resolveProvider', true)
            },
            
            security: {
                enableScanning: workspaceConfig.get('security.enableScanning', true),
                enableVulnerabilityDetection: workspaceConfig.get('security.enableVulnerabilityDetection', true),
                enableStaticAnalysis: workspaceConfig.get('security.enableStaticAnalysis', true),
                enableFuzzing: workspaceConfig.get('security.enableFuzzing', false),
                severityThreshold: workspaceConfig.get('security.severityThreshold', 'medium'),
                autoFix: workspaceConfig.get('security.autoFix', false),
                showNotifications: workspaceConfig.get('security.showNotifications', true)
            },
            
            performance: {
                enableMonitoring: workspaceConfig.get('performance.enableMonitoring', true),
                enableProfiling: workspaceConfig.get('performance.enableProfiling', true),
                enableMetrics: workspaceConfig.get('performance.enableMetrics', true),
                enableAlerts: workspaceConfig.get('performance.enableAlerts', true),
                alertThresholds: workspaceConfig.get('performance.alertThresholds', {
                    compilationTime: 5000,
                    memoryUsage: 512,
                    cpuUsage: 80,
                    diskIO: 100
                }),
                metricsRetention: workspaceConfig.get('performance.metricsRetention', 7),
                samplingInterval: workspaceConfig.get('performance.samplingInterval', 1000)
            },
            
            testing: {
                enable: workspaceConfig.get('testing.enable', true),
                autoRun: workspaceConfig.get('testing.autoRun', false),
                showCodeLens: workspaceConfig.get('testing.showCodeLens', true),
                showDecorations: workspaceConfig.get('testing.showDecorations', true),
                enableCoverage: workspaceConfig.get('testing.enableCoverage', true),
                coverageThreshold: workspaceConfig.get('testing.coverageThreshold', 80),
                testFramework: workspaceConfig.get('testing.testFramework', 'builtin'),
                timeout: workspaceConfig.get('testing.timeout', 30000)
            },
            
            packages: {
                enable: workspaceConfig.get('packages.enable', true),
                registryUrl: workspaceConfig.get('packages.registryUrl', 'https://packages.omega-lang.org'),
                autoUpdate: workspaceConfig.get('packages.autoUpdate', true),
                enableSecurityScan: workspaceConfig.get('packages.enableSecurityScan', true),
                cacheDirectory: workspaceConfig.get('packages.cacheDirectory', './.omega-cache'),
                proxy: workspaceConfig.get('packages.proxy', ''),
                timeout: workspaceConfig.get('packages.timeout', 30000)
            },
            
            debugging: {
                enable: workspaceConfig.get('debugging.enable', true),
                enableBreakpoints: workspaceConfig.get('debugging.enableBreakpoints', true),
                enableStepThrough: workspaceConfig.get('debugging.enableStepThrough', true),
                enableVariableInspection: workspaceConfig.get('debugging.enableVariableInspection', true),
                enableCallStack: workspaceConfig.get('debugging.enableCallStack', true),
                enableMemoryInspection: workspaceConfig.get('debugging.enableMemoryInspection', true),
                enablePerformanceProfiling: workspaceConfig.get('debugging.enablePerformanceProfiling', true)
            },
            
            deployment: {
                enable: workspaceConfig.get('deployment.enable', true),
                enableNetworkSelection: workspaceConfig.get('deployment.enableNetworkSelection', true),
                enableGasEstimation: workspaceConfig.get('deployment.enableGasEstimation', true),
                enableTransactionPreview: workspaceConfig.get('deployment.enableTransactionPreview', true),
                enableMultiSig: workspaceConfig.get('deployment.enableMultiSig', true),
                enableAuditTrail: workspaceConfig.get('deployment.enableAuditTrail', true),
                networks: workspaceConfig.get('deployment.networks', {
                    ethereum: {
                        url: 'https://mainnet.infura.io/v3/YOUR_PROJECT_ID',
                        chainId: 1,
                        gasPrice: 'auto',
                        gasLimit: 8000000,
                        privateKey: '',
                        mnemonic: '',
                        explorerUrl: 'https://etherscan.io'
                    },
                    sepolia: {
                        url: 'https://sepolia.infura.io/v3/YOUR_PROJECT_ID',
                        chainId: 11155111,
                        gasPrice: 'auto',
                        gasLimit: 8000000,
                        privateKey: '',
                        mnemonic: '',
                        explorerUrl: 'https://sepolia.etherscan.io'
                    }
                })
            },
            
            ui: {
                showStatusBar: workspaceConfig.get('ui.showStatusBar', true),
                showOutputChannel: workspaceConfig.get('ui.showOutputChannel', true),
                showTerminal: workspaceConfig.get('ui.showTerminal', true),
                showWelcomeNotification: workspaceConfig.get('ui.showWelcomeNotification', true),
                revealOutputChannelOn: workspaceConfig.get('ui.revealOutputChannelOn', 'warn'),
                enableNotifications: workspaceConfig.get('ui.enableNotifications', true),
                notificationLevel: workspaceConfig.get('ui.notificationLevel', 'info')
            },
            
            telemetry: {
                enable: workspaceConfig.get('telemetry.enable', true),
                enableCrashReporting: workspaceConfig.get('telemetry.enableCrashReporting', true),
                enableUsageReporting: workspaceConfig.get('telemetry.enableUsageReporting', true),
                enablePerformanceReporting: workspaceConfig.get('telemetry.enablePerformanceReporting', true),
                enableErrorReporting: workspaceConfig.get('telemetry.enableErrorReporting', true),
                endpoint: workspaceConfig.get('telemetry.endpoint', 'https://telemetry.omega-lang.org'),
                interval: workspaceConfig.get('telemetry.interval', 300000)
            },
            
            advanced: {
                enableExperimentalFeatures: workspaceConfig.get('advanced.enableExperimentalFeatures', false),
                enableDebugMode: workspaceConfig.get('advanced.enableDebugMode', false),
                enableVerboseLogging: workspaceConfig.get('advanced.enableVerboseLogging', false),
                enableTracing: workspaceConfig.get('advanced.enableTracing', false),
                traceServer: workspaceConfig.get('advanced.traceServer', 'off'),
                enableCustomCommands: workspaceConfig.get('advanced.enableCustomCommands', false),
                enableScripting: workspaceConfig.get('advanced.enableScripting', false),
                enableAutomation: workspaceConfig.get('advanced.enableAutomation', false)
            }
        };
    }
    
    private setupConfigurationChangeListener(): void {
        this.disposables.push(
            vscode.workspace.onDidChangeConfiguration(event => {
                if (event.affectsConfiguration('omega')) {
                    this.reloadConfiguration();
                }
            })
        );
    }
    
    public dispose(): void {
        this.disposables.forEach(disposable => disposable.dispose());
        this.disposables = [];
    }
}

// Export singleton instance
export const configurationManager = ConfigurationManager.getInstance();

// Export configuration interface for backward compatibility
export class OmegaConfiguration {
    private config: OmegaConfiguration;
    
    constructor(initialConfig?: OmegaConfiguration) {
        this.config = initialConfig || configurationManager.getConfiguration();
    }
    
    public reload(): void {
        this.config = configurationManager.getConfiguration();
    }
    
    // Language Server Configuration
    public getLanguageServerPath(): string {
        return this.config.languageServer.path;
    }
    
    public getLanguageServerArgs(): string[] {
        return this.config.languageServer.args;
    }
    
    public getLanguageServerEnv(): Record<string, string> {
        return this.config.languageServer.env;
    }
    
    public getLanguageServerMaxMemory(): number {
        return this.config.languageServer.maxMemory;
    }
    
    public getLanguageServerTimeout(): number {
        return this.config.languageServer.timeout;
    }
    
    // Compiler Configuration
    public getCompilerPath(): string {
        return this.config.compiler.path;
    }
    
    public getTargetPlatforms(): string[] {
        return this.config.compiler.targetPlatforms;
    }
    
    public getOptimizationLevel(): string {
        return this.config.compiler.optimizationLevel;
    }
    
    public getDebugMode(): boolean {
        return this.config.compiler.debugMode;
    }
    
    public getEnableParallelCompilation(): boolean {
        return this.config.compiler.enableParallelCompilation;
    }
    
    public getMaxThreads(): number {
        return this.config.compiler.maxThreads;
    }
    
    public getOutputDirectory(): string {
        return this.config.compiler.outputDirectory;
    }
    
    public getTempDirectory(): string {
        return this.config.compiler.tempDirectory;
    }
    
    // Feature Flags
    public getEnableDiagnostics(): boolean {
        return this.config.features.enableDiagnostics;
    }
    
    public getEnableCodeActions(): boolean {
        return this.config.features.enableCodeActions;
    }
    
    public getEnableCodeLens(): boolean {
        return this.config.features.enableCodeLens;
    }
    
    public getEnableFormatting(): boolean {
        return this.config.features.enableFormatting;
    }
    
    public getEnableHover(): boolean {
        return this.config.features.enableHover;
    }
    
    public getEnableCompletion(): boolean {
        return this.config.features.enableCompletion;
    }
    
    public getEnableSemanticTokens(): boolean {
        return this.config.features.enableSemanticTokens;
    }
    
    public getEnableSecurityScanning(): boolean {
        return this.config.features.enableSecurityScanning;
    }
    
    public getEnablePerformanceMonitoring(): boolean {
        return this.config.features.enablePerformanceMonitoring;
    }
    
    public getEnableCrossCompilation(): boolean {
        return this.config.features.enableCrossCompilation;
    }
    
    public getEnableBootstrapCompiler(): boolean {
        return this.config.features.enableBootstrapCompiler;
    }
    
    // Diagnostics Configuration
    public getMaxNumberOfProblems(): number {
        return this.config.diagnostics.maxNumberOfProblems;
    }
    
    public getShowWarnings(): boolean {
        return this.config.diagnostics.showWarnings;
    }
    
    public getShowInfos(): boolean {
        return this.config.diagnostics.showInfos;
    }
    
    public getShowHints(): boolean {
        return this.config.diagnostics.showHints;
    }
    
    public getEnableRelatedInformation(): boolean {
        return this.config.diagnostics.enableRelatedInformation;
    }
    
    public getEnableCodeDescription(): boolean {
        return this.config.diagnostics.enableCodeDescription;
    }
    
    public getSeverityOverrides(): Record<string, string> {
        return this.config.diagnostics.severityOverrides;
    }
    
    // Completion Configuration
    public getTriggerCharacters(): string[] {
        return this.config.completion.triggerCharacters;
    }
    
    public getResolveProvider(): boolean {
        return this.config.completion.resolveProvider;
    }
    
    public getEnableSnippets(): boolean {
        return this.config.completion.enableSnippets;
    }
    
    public getEnableAutoImport(): boolean {
        return this.config.completion.enableAutoImport;
    }
    
    public getEnableContextAwareCompletion(): boolean {
        return this.config.completion.enableContextAwareCompletion;
    }
    
    public getMaxCompletionItems(): number {
        return this.config.completion.maxItems;
    }
    
    // Formatting Configuration
    public getAutoFormatOnSave(): boolean {
        return this.config.formatting.enableOnSave;
    }
    
    public getAutoFormatOnType(): boolean {
        return this.config.formatting.enableOnType;
    }
    
    public getTabSize(): number {
        return this.config.formatting.tabSize;
    }
    
    public getInsertSpaces(): boolean {
        return this.config.formatting.insertSpaces;
    }
    
    public getMaxLineLength(): number {
        return this.config.formatting.maxLineLength;
    }
    
    public getBraceStyle(): string {
        return this.config.formatting.braceStyle;
    }
    
    public getIndentStyle(): string {
        return this.config.formatting.indentStyle;
    }
    
    public getNewlineStyle(): string {
        return this.config.formatting.newlineStyle;
    }
    
    // Hover Configuration
    public getHoverDelay(): number {
        return this.config.hover.delay;
    }
    
    public getShowDocumentation(): boolean {
        return this.config.hover.showDocumentation;
    }
    
    public getShowTypeInformation(): boolean {
        return this.config.hover.showTypeInformation;
    }
    
    public getShowDefinition(): boolean {
        return this.config.hover.showDefinition;
    }
    
    public getShowReferences(): boolean {
        return this.config.hover.showReferences;
    }
    
    // Code Lens Configuration
    public getShowReferencesCodeLens(): boolean {
        return this.config.codeLens.showReferences;
    }
    
    public getShowImplementationsCodeLens(): boolean {
        return this.config.codeLens.showImplementations;
    }
    
    public getShowTestsCodeLens(): boolean {
        return this.config.codeLens.showTests;
    }
    
    public getShowPerformanceMetricsCodeLens(): boolean {
        return this.config.codeLens.showPerformanceMetrics;
    }
    
    public getShowSecurityInfoCodeLens(): boolean {
        return this.config.codeLens.showSecurityInfo;
    }
    
    public getCodeLensResolveProvider(): boolean {
        return this.config.codeLens.resolveProvider;
    }
    
    // UI Configuration
    public getShowStatusBar(): boolean {
        return this.config.ui.showStatusBar;
    }
    
    public getShowOutputChannel(): boolean {
        return this.config.ui.showOutputChannel;
    }
    
    public getShowTerminal(): boolean {
        return this.config.ui.showTerminal;
    }
    
    public getShowWelcomeNotification(): boolean {
        return this.config.ui.showWelcomeNotification;
    }
    
    public setShowWelcomeNotification(value: boolean): void {
        this.config.ui.showWelcomeNotification = value;
    }
    
    public getRevealOutputChannelOn(): string {
        return this.config.ui.revealOutputChannelOn;
    }
    
    public getEnableNotifications(): boolean {
        return this.config.ui.enableNotifications;
    }
    
    public getNotificationLevel(): string {
        return this.config.ui.notificationLevel;
    }
    
    // Telemetry Configuration
    public isTelemetryEnabled(): boolean {
        return this.config.telemetry.enable;
    }
    
    public getLogLevel(): string {
        return this.config.advanced.enableVerboseLogging ? 'verbose' : 'info';
    }
    
    public getPerformanceConfig(): any {
        return this.config.performance;
    }
    
    public getSecurityConfig(): any {
        return this.config.security;
    }
    
    public getPackageConfig(): any {
        return this.config.packages;
    }
    
    public getProjectConfig(): any {
        return this.config.advanced;
    }
    
    public getAnalyzerConfig(): any {
        return this.config.diagnostics;
    }
    
    public getCompilerConfig(): any {
        return this.config.compiler;
    }
}