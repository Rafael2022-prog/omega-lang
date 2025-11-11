import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { configurationManager } from './configuration';

export enum LogLevel {
    ERROR = 0,
    WARN = 1,
    INFO = 2,
    DEBUG = 3,
    VERBOSE = 4
}

export interface LogEntry {
    timestamp: Date;
    level: LogLevel;
    message: string;
    category: string;
    metadata?: any;
    stackTrace?: string;
    context?: string;
}

export interface LoggerConfig {
    logLevel: LogLevel;
    enableConsole: boolean;
    enableFile: boolean;
    enableOutputChannel: boolean;
    enableTelemetry: boolean;
    maxFileSize: number;
    maxFiles: number;
    logDirectory: string;
    logFileName: string;
    enableColors: boolean;
    enableTimestamps: boolean;
    enableCategories: boolean;
    enableStackTraces: boolean;
    enableMetadata: boolean;
    enableContext: boolean;
    enableCompression: boolean;
    enableEncryption: boolean;
    enableRemoteLogging: boolean;
    remoteEndpoint: string;
    remoteApiKey: string;
    enableLogRotation: boolean;
    rotationInterval: number;
    enablePerformanceMetrics: boolean;
    enableErrorTracking: boolean;
    enableUserTracking: boolean;
    enableSessionTracking: boolean;
    enableLogAnalysis: boolean;
    enableRealTimeMonitoring: boolean;
    enableAlerting: boolean;
    alertThresholds: {
        errorRate: number;
        warningRate: number;
        logVolume: number;
        responseTime: number;
    };
}

export class Logger {
    private static instance: Logger;
    private config: LoggerConfig;
    private outputChannel: vscode.OutputChannel;
    private logFilePath: string;
    private logEntries: LogEntry[] = [];
    private sessionId: string;
    private startTime: Date;
    private errorCount: number = 0;
    private warningCount: number = 0;
    private logCount: number = 0;
    private performanceMetrics: Map<string, number> = new Map();
    private alertManager: AlertManager;
    private logRotator: LogRotator;
    private logAnalyzer: LogAnalyzer;
    private remoteLogger: RemoteLogger;
    private telemetryClient: TelemetryClient;
    
    private constructor() {
        this.sessionId = this.generateSessionId();
        this.startTime = new Date();
        this.loadConfiguration();
        this.initializeComponents();
        this.logSystemStartup();
    }
    
    public static getInstance(): Logger {
        if (!Logger.instance) {
            Logger.instance = new Logger();
        }
        return Logger.instance;
    }
    
    private loadConfiguration(): void {
        const config = configurationManager.getConfiguration();
        const advancedConfig = config.advanced;
        const telemetryConfig = config.telemetry;
        
        this.config = {
            logLevel: this.parseLogLevel(config.advanced.enableVerboseLogging ? 'verbose' : 'info'),
            enableConsole: true,
            enableFile: true,
            enableOutputChannel: true,
            enableTelemetry: telemetryConfig.enable,
            maxFileSize: 10 * 1024 * 1024, // 10MB
            maxFiles: 10,
            logDirectory: path.join(__dirname, '..', '..', 'logs'),
            logFileName: `omega-${this.sessionId}.log`,
            enableColors: true,
            enableTimestamps: true,
            enableCategories: true,
            enableStackTraces: true,
            enableMetadata: true,
            enableContext: true,
            enableCompression: true,
            enableEncryption: false,
            enableRemoteLogging: false,
            remoteEndpoint: '',
            remoteApiKey: '',
            enableLogRotation: true,
            rotationInterval: 24 * 60 * 60 * 1000, // 24 hours
            enablePerformanceMetrics: true,
            enableErrorTracking: true,
            enableUserTracking: false,
            enableSessionTracking: true,
            enableLogAnalysis: true,
            enableRealTimeMonitoring: true,
            enableAlerting: true,
            alertThresholds: {
                errorRate: 0.1,
                warningRate: 0.2,
                logVolume: 1000,
                responseTime: 5000
            }
        };
        
        this.setupLogDirectory();
        this.setupOutputChannel();
    }
    
    private initializeComponents(): void {
        this.alertManager = new AlertManager(this.config);
        this.logRotator = new LogRotator(this.config);
        this.logAnalyzer = new LogAnalyzer(this.config);
        this.remoteLogger = new RemoteLogger(this.config);
        this.telemetryClient = new TelemetryClient(this.config);
    }
    
    private setupLogDirectory(): void {
        if (!fs.existsSync(this.config.logDirectory)) {
            fs.mkdirSync(this.config.logDirectory, { recursive: true });
        }
        this.logFilePath = path.join(this.config.logDirectory, this.config.logFileName);
    }
    
    private setupOutputChannel(): void {
        this.outputChannel = vscode.window.createOutputChannel('OMEGA Language Server');
    }
    
    private parseLogLevel(level: string): LogLevel {
        switch (level.toLowerCase()) {
            case 'error': return LogLevel.ERROR;
            case 'warn': return LogLevel.WARN;
            case 'info': return LogLevel.INFO;
            case 'debug': return LogLevel.DEBUG;
            case 'verbose': return LogLevel.VERBOSE;
            default: return LogLevel.INFO;
        }
    }
    
    private generateSessionId(): string {
        return `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }
    
    private logSystemStartup(): void {
        this.info('OMEGA Language Server', 'System startup', {
            version: this.getExtensionVersion(),
            vscodeVersion: vscode.version,
            platform: process.platform,
            arch: process.arch,
            nodeVersion: process.version,
            sessionId: this.sessionId,
            startTime: this.startTime.toISOString()
        });
    }
    
    private getExtensionVersion(): string {
        try {
            const packageJsonPath = path.join(__dirname, '..', '..', 'package.json');
            const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
            return packageJson.version || 'unknown';
        } catch (error) {
            return 'unknown';
        }
    }
    
    public error(message: string, category: string = 'general', metadata?: any, context?: string): void {
        this.log(LogLevel.ERROR, message, category, metadata, context);
    }
    
    public warn(message: string, category: string = 'general', metadata?: any, context?: string): void {
        this.log(LogLevel.WARN, message, category, metadata, context);
    }
    
    public info(message: string, category: string = 'general', metadata?: any, context?: string): void {
        this.log(LogLevel.INFO, message, category, metadata, context);
    }
    
    public debug(message: string, category: string = 'general', metadata?: any, context?: string): void {
        this.log(LogLevel.DEBUG, message, category, metadata, context);
    }
    
    public verbose(message: string, category: string = 'general', metadata?: any, context?: string): void {
        this.log(LogLevel.VERBOSE, message, category, metadata, context);
    }
    
    private log(level: LogLevel, message: string, category: string, metadata?: any, context?: string): void {
        if (level > this.config.logLevel) {
            return;
        }
        
        const entry: LogEntry = {
            timestamp: new Date(),
            level,
            message,
            category,
            metadata,
            context,
            stackTrace: level <= LogLevel.ERROR ? new Error().stack : undefined
        };
        
        this.logEntries.push(entry);
        this.updateCounters(level);
        
        // Log to different outputs
        this.logToConsole(entry);
        this.logToOutputChannel(entry);
        this.logToFile(entry);
        this.logToTelemetry(entry);
        this.logToRemote(entry);
        
        // Analyze and alert
        this.analyzeLog(entry);
        this.checkAlerts(entry);
        
        // Rotate logs if needed
        this.rotateLogsIfNeeded();
    }
    
    private updateCounters(level: LogLevel): void {
        this.logCount++;
        if (level === LogLevel.ERROR) {
            this.errorCount++;
        } else if (level === LogLevel.WARN) {
            this.warningCount++;
        }
    }
    
    private logToConsole(entry: LogEntry): void {
        if (!this.config.enableConsole) {
            return;
        }
        
        const formattedMessage = this.formatLogEntry(entry);
        
        switch (entry.level) {
            case LogLevel.ERROR:
                console.error(formattedMessage);
                break;
            case LogLevel.WARN:
                console.warn(formattedMessage);
                break;
            case LogLevel.INFO:
                console.info(formattedMessage);
                break;
            case LogLevel.DEBUG:
            case LogLevel.VERBOSE:
                console.log(formattedMessage);
                break;
        }
    }
    
    private logToOutputChannel(entry: LogEntry): void {
        if (!this.config.enableOutputChannel) {
            return;
        }
        
        const formattedMessage = this.formatLogEntry(entry);
        this.outputChannel.appendLine(formattedMessage);
    }
    
    private logToFile(entry: LogEntry): void {
        if (!this.config.enableFile) {
            return;
        }
        
        const formattedMessage = this.formatLogEntry(entry);
        
        try {
            fs.appendFileSync(this.logFilePath, formattedMessage + '\n');
        } catch (error) {
            console.error('Failed to write to log file:', error);
        }
    }
    
    private logToTelemetry(entry: LogEntry): void {
        if (!this.config.enableTelemetry) {
            return;
        }
        
        this.telemetryClient.trackEvent('log_entry', {
            level: LogLevel[entry.level].toLowerCase(),
            category: entry.category,
            message: entry.message,
            sessionId: this.sessionId,
            timestamp: entry.timestamp.toISOString()
        });
    }
    
    private logToRemote(entry: LogEntry): void {
        if (!this.config.enableRemoteLogging) {
            return;
        }
        
        this.remoteLogger.sendLog(entry);
    }
    
    private formatLogEntry(entry: LogEntry): string {
        const parts: string[] = [];
        
        if (this.config.enableTimestamps) {
            parts.push(`[${entry.timestamp.toISOString()}]`);
        }
        
        if (this.config.enableCategories) {
            parts.push(`[${entry.category}]`);
        }
        
        if (this.config.enableColors) {
            parts.push(this.getColorCode(entry.level));
        }
        
        parts.push(`[${LogLevel[entry.level].toUpperCase()}]`);
        parts.push(entry.message);
        
        if (entry.context) {
            parts.push(`Context: ${entry.context}`);
        }
        
        if (entry.metadata) {
            parts.push(`Metadata: ${JSON.stringify(entry.metadata, null, 2)}`);
        }
        
        if (entry.stackTrace && this.config.enableStackTraces) {
            parts.push(`Stack Trace: ${entry.stackTrace}`);
        }
        
        if (this.config.enableColors) {
            parts.push('\x1b[0m'); // Reset color
        }
        
        return parts.join(' ');
    }
    
    private getColorCode(level: LogLevel): string {
        switch (level) {
            case LogLevel.ERROR: return '\x1b[31m'; // Red
            case LogLevel.WARN: return '\x1b[33m'; // Yellow
            case LogLevel.INFO: return '\x1b[32m'; // Green
            case LogLevel.DEBUG: return '\x1b[36m'; // Cyan
            case LogLevel.VERBOSE: return '\x1b[35m'; // Magenta
            default: return '\x1b[0m'; // Reset
        }
    }
    
    private analyzeLog(entry: LogEntry): void {
        if (!this.config.enableLogAnalysis) {
            return;
        }
        
        this.logAnalyzer.analyze(entry);
    }
    
    private checkAlerts(entry: LogEntry): void {
        if (!this.config.enableAlerting) {
            return;
        }
        
        this.alertManager.check(entry, {
            errorCount: this.errorCount,
            warningCount: this.warningCount,
            logCount: this.logCount,
            sessionId: this.sessionId,
            startTime: this.startTime
        });
    }
    
    private rotateLogsIfNeeded(): void {
        if (!this.config.enableLogRotation) {
            return;
        }
        
        this.logRotator.rotateIfNeeded(this.logFilePath);
    }
    
    public getSessionMetrics(): any {
        const uptime = Date.now() - this.startTime.getTime();
        const errorRate = this.errorCount / Math.max(this.logCount, 1);
        const warningRate = this.warningCount / Math.max(this.logCount, 1);
        
        return {
            sessionId: this.sessionId,
            startTime: this.startTime.toISOString(),
            uptime,
            logCount: this.logCount,
            errorCount: this.errorCount,
            warningCount: this.warningCount,
            errorRate,
            warningRate,
            performanceMetrics: Object.fromEntries(this.performanceMetrics),
            logFilePath: this.logFilePath,
            logFileSize: this.getLogFileSize()
        };
    }
    
    private getLogFileSize(): number {
        try {
            const stats = fs.statSync(this.logFilePath);
            return stats.size;
        } catch (error) {
            return 0;
        }
    }
    
    public getRecentLogs(level?: LogLevel, category?: string, limit: number = 100): LogEntry[] {
        let logs = [...this.logEntries];
        
        if (level !== undefined) {
            logs = logs.filter(entry => entry.level === level);
        }
        
        if (category) {
            logs = logs.filter(entry => entry.category === category);
        }
        
        return logs.slice(-limit);
    }
    
    public clearLogs(): void {
        this.logEntries = [];
        this.errorCount = 0;
        this.warningCount = 0;
        this.logCount = 0;
        this.performanceMetrics.clear();
    }
    
    public dispose(): void {
        this.info('Logger', 'Disposing logger', {
            sessionId: this.sessionId,
            finalMetrics: this.getSessionMetrics()
        });
        
        if (this.outputChannel) {
            this.outputChannel.dispose();
        }
        
        this.alertManager.dispose();
        this.logRotator.dispose();
        this.logAnalyzer.dispose();
        this.remoteLogger.dispose();
        this.telemetryClient.dispose();
    }
}

// Supporting classes
class AlertManager {
    private config: LoggerConfig;
    private activeAlerts: Map<string, any> = new Map();
    
    constructor(config: LoggerConfig) {
        this.config = config;
    }
    
    public check(entry: LogEntry, metrics: any): void {
        // Implement alert logic based on thresholds
        if (metrics.errorRate > this.config.alertThresholds.errorRate) {
            this.triggerAlert('high_error_rate', {
                severity: 'critical',
                message: `High error rate detected: ${(metrics.errorRate * 100).toFixed(2)}%`,
                metrics
            });
        }
        
        if (metrics.logCount > this.config.alertThresholds.logVolume) {
            this.triggerAlert('high_log_volume', {
                severity: 'warning',
                message: `High log volume detected: ${metrics.logCount} entries`,
                metrics
            });
        }
    }
    
    private triggerAlert(alertId: string, alertData: any): void {
        if (this.activeAlerts.has(alertId)) {
            return; // Alert already active
        }
        
        this.activeAlerts.set(alertId, alertData);
        
        // Send notification
        vscode.window.showWarningMessage(`OMEGA Alert: ${alertData.message}`);
        
        // Log the alert
        Logger.getInstance().warn('AlertManager', `Alert triggered: ${alertId}`, alertData);
    }
    
    public dispose(): void {
        this.activeAlerts.clear();
    }
}

class LogRotator {
    private config: LoggerConfig;
    private lastRotation: Date = new Date();
    
    constructor(config: LoggerConfig) {
        this.config = config;
    }
    
    public rotateIfNeeded(logFilePath: string): void {
        const now = new Date();
        const timeSinceLastRotation = now.getTime() - this.lastRotation.getTime();
        
        if (timeSinceLastRotation >= this.config.rotationInterval) {
            this.rotate(logFilePath);
            this.lastRotation = now;
        }
    }
    
    private rotate(logFilePath: string): void {
        try {
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const rotatedFilePath = `${logFilePath}.${timestamp}`;
            
            fs.renameSync(logFilePath, rotatedFilePath);
            
            Logger.getInstance().info('LogRotator', 'Log file rotated', {
                oldPath: logFilePath,
                newPath: rotatedFilePath
            });
        } catch (error) {
            Logger.getInstance().error('LogRotator', 'Failed to rotate log file', { error });
        }
    }
    
    public dispose(): void {
        // Cleanup
    }
}

class LogAnalyzer {
    private config: LoggerConfig;
    private patterns: Map<string, RegExp> = new Map();
    
    constructor(config: LoggerConfig) {
        this.config = config;
        this.setupPatterns();
    }
    
    private setupPatterns(): void {
        this.patterns.set('error_pattern', /error|exception|fail/i);
        this.patterns.set('warning_pattern', /warn|caution/i);
        this.patterns.set('performance_pattern', /slow|timeout|memory|cpu/i);
    }
    
    public analyze(entry: LogEntry): void {
        // Analyze log patterns and trends
        for (const [patternName, pattern] of this.patterns) {
            if (pattern.test(entry.message)) {
                Logger.getInstance().debug('LogAnalyzer', `Pattern matched: ${patternName}`, {
                    entry: entry.message,
                    pattern: patternName
                });
            }
        }
    }
    
    public dispose(): void {
        this.patterns.clear();
    }
}

class RemoteLogger {
    private config: LoggerConfig;
    private queue: LogEntry[] = [];
    private isSending: boolean = false;
    
    constructor(config: LoggerConfig) {
        this.config = config;
    }
    
    public sendLog(entry: LogEntry): void {
        this.queue.push(entry);
        this.processQueue();
    }
    
    private async processQueue(): Promise<void> {
        if (this.isSending || this.queue.length === 0) {
            return;
        }
        
        this.isSending = true;
        
        try {
            const batch = this.queue.splice(0, 100); // Send in batches
            await this.sendBatch(batch);
        } catch (error) {
            Logger.getInstance().error('RemoteLogger', 'Failed to send logs to remote server', { error });
        } finally {
            this.isSending = false;
            
            if (this.queue.length > 0) {
                setTimeout(() => this.processQueue(), 1000);
            }
        }
    }
    
    private async sendBatch(batch: LogEntry[]): Promise<void> {
        // Implement remote logging logic
        // This would typically involve HTTP requests to a logging service
    }
    
    public dispose(): void {
        this.queue = [];
    }
}

class TelemetryClient {
    private config: LoggerConfig;
    private events: any[] = [];
    
    constructor(config: LoggerConfig) {
        this.config = config;
    }
    
    public trackEvent(eventName: string, properties: any): void {
        if (!this.config.enableTelemetry) {
            return;
        }
        
        const event = {
            name: eventName,
            properties,
            timestamp: new Date().toISOString()
        };
        
        this.events.push(event);
        
        // Send to telemetry service
        this.sendTelemetry();
    }
    
    private sendTelemetry(): void {
        // Implement telemetry sending logic
    }
    
    public dispose(): void {
        this.events = [];
    }
}

// Export singleton instance
export const logger = Logger.getInstance();