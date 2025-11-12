import * as vscode from 'vscode';
import { DebugSession, InitializedEvent, TerminatedEvent, StoppedEvent, BreakpointEvent, OutputEvent, Thread, StackFrame, Scope, Source, Handles } from '@vscode/debugadapter';
import { DebugProtocol } from '@vscode/debugprotocol';
import { EventEmitter } from 'events';
import * as path from 'path';
import * as fs from 'fs';

export interface LaunchRequestArguments extends DebugProtocol.LaunchRequestArguments {
    program: string;
    args?: string[];
    cwd?: string;
    env?: { [key: string]: string };
    stopOnEntry?: boolean;
    console?: 'internalConsole' | 'integratedTerminal' | 'externalTerminal';
}

export class OmegaDebugAdapter extends DebugSession {
    private static threadId = 1;
    private variableHandles = new Handles<string>();
    private breakpoints = new Map<string, DebugProtocol.Breakpoint[]>();
    private currentLine = 0;
    private currentFile = '';
    private omegaProcess?: any;
    private outputEmitter = new EventEmitter();

    constructor() {
        super();
        this.setDebuggerLinesStartAt1(true);
        this.setDebuggerColumnsStartAt1(true);
    }

    protected initializeRequest(response: DebugProtocol.InitializeResponse, args: DebugProtocol.InitializeRequestArguments): void {
        response.body = response.body || {};
        
        response.body.supportsConfigurationDoneRequest = true;
        response.body.supportsEvaluateForHovers = true;
        response.body.supportsStepBack = false;
        response.body.supportsDataBreakpoints = false;
        response.body.supportsCompletionsRequest = true;
        response.body.supportsBreakpointLocationsRequest = true;
        response.body.supportsConditionalBreakpoints = true;
        response.body.supportsHitConditionalBreakpoints = true;
        response.body.supportsLogPoints = true;
        response.body.supportsRestartRequest = true;
        response.body.supportsExceptionOptions = false;
        response.body.supportsValueFormattingOptions = true;
        response.body.supportsExceptionInfoRequest = true;
        response.body.supportTerminateDebuggee = true;
        response.body.supportsDelayedStackTraceLoading = true;
        response.body.supportsLoadedSourcesRequest = true;
        response.body.supportsSetExpression = true;
        response.body.supportsSetVariable = true;
        response.body.supportsGotoTargetsRequest = true;
        response.body.supportsStepInTargetsRequest = true;

        this.sendResponse(response);
        this.sendEvent(new InitializedEvent());
    }

    protected async launchRequest(response: DebugProtocol.LaunchResponse, args: LaunchRequestArguments): Promise<void> {
        try {
            this.currentFile = args.program;
            this.currentLine = 0;

            // Validate the program file exists
            if (!fs.existsSync(args.program)) {
                this.sendErrorResponse(response, {
                    id: 1001,
                    format: `Program '${args.program}' does not exist`,
                    showUser: true
                });
                return;
            }

            // Set up working directory
            const cwd = args.cwd || path.dirname(args.program);
            
            // Set up environment variables
            const env = { ...process.env, ...args.env };

            // Create debug configuration file
            const debugConfig = {
                program: args.program,
                args: args.args || [],
                cwd: cwd,
                env: env,
                breakpoints: Array.from(this.breakpoints.entries()).map(([file, bps]) => ({
                    file,
                    lines: bps.map(bp => bp.line)
                })),
                stopOnEntry: args.stopOnEntry || false
            };

            const configPath = path.join(cwd, '.omega-debug.json');
            fs.writeFileSync(configPath, JSON.stringify(debugConfig, null, 2));

            // Start the OMEGA debugger
            const omegaPath = this.getOmegaExecutablePath();
            const spawn = require('child_process').spawn;
            
            this.omegaProcess = spawn(omegaPath, [
                'debug',
                args.program,
                '--config',
                configPath
            ], {
                cwd: cwd,
                env: env,
                stdio: ['pipe', 'pipe', 'pipe']
            });

            this.setupProcessHandlers();

            this.sendResponse(response);

            // Send stop on entry if configured
            if (args.stopOnEntry) {
                this.sendEvent(new StoppedEvent('entry', OmegaDebugAdapter.threadId));
            }

        } catch (error) {
            this.sendErrorResponse(response, {
                id: 1002,
                format: `Failed to launch OMEGA debugger: ${error}`,
                showUser: true
            });
        }
    }

    protected setBreakPointsRequest(response: DebugProtocol.SetBreakpointsResponse, args: DebugProtocol.SetBreakpointsArguments): void {
        const path = args.source.path as string;
        const clientBreakpoints = args.breakpoints || [];

        // Clear existing breakpoints for this file
        this.breakpoints.delete(path);

        // Set new breakpoints
        const breakpoints: DebugProtocol.Breakpoint[] = clientBreakpoints.map(bp => {
            const verified = this.verifyBreakpoint(path, bp.line);
            return new Breakpoint(verified, bp.line, bp.column || 0) as DebugProtocol.Breakpoint;
        });

        this.breakpoints.set(path, breakpoints);
        response.body = { breakpoints };
        this.sendResponse(response);
    }

    protected threadsRequest(response: DebugProtocol.ThreadsResponse): void {
        response.body = {
            threads: [
                new Thread(OmegaDebugAdapter.threadId, 'main')
            ]
        };
        this.sendResponse(response);
    }

    protected stackTraceRequest(response: DebugProtocol.StackTraceResponse, args: DebugProtocol.StackTraceArguments): void {
        const frames: StackFrame[] = [];
        
        // Add current frame
        frames.push(new StackFrame(
            0,
            'main',
            new Source(
                path.basename(this.currentFile),
                this.currentFile
            ),
            this.currentLine,
            0
        ));

        response.body = {
            stackFrames: frames,
            totalFrames: frames.length
        };
        this.sendResponse(response);
    }

    protected scopesRequest(response: DebugProtocol.ScopesResponse, args: DebugProtocol.ScopesArguments): void {
        const scopes: Scope[] = [];
        
        // Global scope
        scopes.push(new Scope(
            'Global',
            this.variableHandles.create('global'),
            false
        ));

        // Local scope
        scopes.push(new Scope(
            'Local',
            this.variableHandles.create('local'),
            false
        ));

        response.body = { scopes };
        this.sendResponse(response);
    }

    protected variablesRequest(response: DebugProtocol.VariablesResponse, args: DebugProtocol.VariablesArguments): void {
        const variables: DebugProtocol.Variable[] = [];
        const id = this.variableHandles.get(args.variablesReference);

        if (id === 'global') {
            variables.push({
                name: 'current_file',
                value: this.currentFile,
                type: 'string',
                variablesReference: 0
            });
            variables.push({
                name: 'current_line',
                value: this.currentLine.toString(),
                type: 'number',
                variablesReference: 0
            });
        } else if (id === 'local') {
            variables.push({
                name: 'program_state',
                value: 'running',
                type: 'string',
                variablesReference: 0
            });
        }

        response.body = { variables };
        this.sendResponse(response);
    }

    protected continueRequest(response: DebugProtocol.ContinueResponse, args: DebugProtocol.ContinueArguments): void {
        this.sendResponse(response);
        this.sendEvent(new ContinuedEvent(OmegaDebugAdapter.threadId));
    }

    protected nextRequest(response: DebugProtocol.NextResponse, args: DebugProtocol.NextArguments): void {
        this.currentLine++;
        this.sendResponse(response);
        this.sendEvent(new StoppedEvent('step', OmegaDebugAdapter.threadId));
    }

    protected stepInRequest(response: DebugProtocol.StepInResponse, args: DebugProtocol.StepInArguments): void {
        this.sendResponse(response);
        this.sendEvent(new StoppedEvent('step', OmegaDebugAdapter.threadId));
    }

    protected stepOutRequest(response: DebugProtocol.StepOutResponse, args: DebugProtocol.StepOutArguments): void {
        this.sendResponse(response);
        this.sendEvent(new StoppedEvent('step', OmegaDebugAdapter.threadId));
    }

    protected pauseRequest(response: DebugProtocol.PauseResponse, args: DebugProtocol.PauseArguments): void {
        this.sendResponse(response);
        this.sendEvent(new StoppedEvent('pause', OmegaDebugAdapter.threadId));
    }

    protected disconnectRequest(response: DebugProtocol.DisconnectResponse, args: DebugProtocol.DisconnectArguments): void {
        if (this.omegaProcess) {
            this.omegaProcess.kill();
        }
        this.sendResponse(response);
        this.sendEvent(new TerminatedEvent());
    }

    protected evaluateRequest(response: DebugProtocol.EvaluateResponse, args: DebugProtocol.EvaluateArguments): void {
        let reply: string | undefined;
        const expression = args.expression;

        if (expression === 'current_file') {
            reply = this.currentFile;
        } else if (expression === 'current_line') {
            reply = this.currentLine.toString();
        } else {
            reply = `Unknown expression: ${expression}`;
        }

        if (reply) {
            response.body = {
                result: reply,
                variablesReference: 0
            };
        }

        this.sendResponse(response);
    }

    private getOmegaExecutablePath(): string {
        const config = vscode.workspace.getConfiguration('omega');
        const customPath = config.get<string>('executablePath');
        
        if (customPath && customPath !== 'omega') {
            return customPath;
        }

        // Try to find omega executable in common locations
        const possiblePaths = [
            path.join(vscode.workspace.rootPath || '', 'omega'),
            path.join(vscode.workspace.rootPath || '', 'omega.exe'),
            'omega',
            'omega.exe'
        ];

        for (const possiblePath of possiblePaths) {
            if (fs.existsSync(possiblePath)) {
                return possiblePath;
            }
        }

        return 'omega';
    }

    private verifyBreakpoint(filePath: string, line: number): boolean {
        // Simple verification - check if the line exists in the file
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const lines = content.split('\n');
            return line > 0 && line <= lines.length;
        } catch {
            return false;
        }
    }

    private setupProcessHandlers(): void {
        if (!this.omegaProcess) return;

        this.omegaProcess.stdout.on('data', (data: Buffer) => {
            this.sendEvent(new OutputEvent(data.toString(), 'stdout'));
        });

        this.omegaProcess.stderr.on('data', (data: Buffer) => {
            this.sendEvent(new OutputEvent(data.toString(), 'stderr'));
        });

        this.omegaProcess.on('close', (code: number) => {
            this.sendEvent(new TerminatedEvent());
        });

        this.omegaProcess.on('error', (error: Error) => {
            this.sendEvent(new OutputEvent(`Process error: ${error.message}\n`, 'stderr'));
        });
    }
}

// Import missing classes
import { Breakpoint, ContinuedEvent } from '@vscode/debugadapter';