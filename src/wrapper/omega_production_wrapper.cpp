// OMEGA Production Wrapper (relocated)
// - Provides a stable entrypoint for native production builds
// - Adds robust diagnostics for uncaught exceptions via std::set_terminate
// - Implements run_in_dir with Windows-safe quoting for arguments containing spaces
//
// NOTE: This wrapper is intentionally minimal. Complex EVM emitter logic should
// reside in dedicated modules; the wrapper focuses on process orchestration and diagnostics.

#include <windows.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <string>
#include <vector>
#include <iostream>
#include <sstream>
#include <algorithm>
#include <fstream>

// Global terminate handler for diagnostics
static void omega_terminate_handler() noexcept {
    // Best-effort logging. Avoid allocations to reduce risk during termination.
    std::fputs("[FATAL] std::terminate invoked. An uncaught exception occurred.\n", stderr);
    std::fputs("[FATAL] If this happened during EVM wrapper emission, a bounds or mapping error likely occurred.\n", stderr);
    std::fflush(stderr);
    // On Windows, abort to propagate non-zero exit code
    std::abort();
}

static bool has_unquoted_space(const std::wstring &arg) {
    if (arg.empty()) return false;
    bool quoted = arg.size() >= 2 && arg.front() == L'"' && arg.back() == L'"';
    if (quoted) return false;
    return arg.find(L' ') != std::wstring::npos;
}

static std::wstring quote_if_needed(const std::wstring &arg) {
    if (has_unquoted_space(arg)) {
        std::wstring q; q.reserve(arg.size() + 2);
        q.push_back(L'"');
        q.append(arg);
        q.push_back(L'"');
        return q;
    }
    return arg;
}

static std::wstring join_command_line(const std::wstring &exe, const std::vector<std::wstring> &args) {
    std::wstringstream ss;
    ss << quote_if_needed(exe);
    for (const auto &a : args) {
        ss << L" " << quote_if_needed(a);
    }
    return ss.str();
}

// Run a command within a specific directory using CreateProcessW.
// Returns true on successful process creation; sets exitCode on process completion.
static bool run_in_dir(const std::wstring &workingDir, const std::wstring &exe, const std::vector<std::wstring> &args, DWORD &exitCode) {
    std::wstring cmdline = join_command_line(exe, args);
    std::wcerr << L"[DEBUG] run_in_dir: requested_dir=" << workingDir << L" cmd=" << cmdline << std::endl;

    STARTUPINFOW si; PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si)); si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    // CreateProcessW requires a modifiable buffer for command line
    std::vector<wchar_t> mutableCmd(cmdline.begin(), cmdline.end());
    mutableCmd.push_back(L'\0');

    BOOL ok = CreateProcessW(
        nullptr,                      // lpApplicationName
        mutableCmd.data(),            // lpCommandLine
        nullptr,                      // lpProcessAttributes
        nullptr,                      // lpThreadAttributes
        FALSE,                        // bInheritHandles
        0,                            // dwCreationFlags
        nullptr,                      // lpEnvironment
        workingDir.empty() ? nullptr : workingDir.c_str(), // lpCurrentDirectory
        &si,                          // lpStartupInfo
        &pi                           // lpProcessInformation
    );

    if (!ok) {
        DWORD err = GetLastError();
        std::wcerr << L"[ERROR] CreateProcessW failed. GetLastError()=" << err << std::endl;
        exitCode = static_cast<DWORD>(-1);
        return false;
    }

    // Wait for process to exit
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 0;
    if (!GetExitCodeProcess(pi.hProcess, &code)) {
        std::wcerr << L"[ERROR] GetExitCodeProcess failed" << std::endl;
        code = static_cast<DWORD>(-1);
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    exitCode = code;
    std::wcerr << L"[DEBUG] run_in_dir(CreateProcessW): working_dir=" << workingDir << L" exit_code=" << exitCode << std::endl;
    return true;
}

static std::wstring wide_from_utf8(const std::string &s) {
    if (s.empty()) return std::wstring();
    int len = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0);
    std::wstring out; out.resize(len);
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &out[0], len);
    return out;
}

static std::string narrow_from_wide(const std::wstring &ws) {
    if (ws.empty()) return std::string();
    int len = WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), (int)ws.size(), nullptr, 0, nullptr, nullptr);
    std::string out; out.resize(len);
    WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), (int)ws.size(), &out[0], len, nullptr, nullptr);
    return out;
}

static std::wstring get_filename(const std::wstring &path) {
    size_t pos = path.find_last_of(L"/\\");
    if (pos == std::wstring::npos) return path;
    return path.substr(pos + 1);
}

static std::wstring get_dirname(const std::wstring &path) {
    size_t pos = path.find_last_of(L"/\\");
    if (pos == std::wstring::npos) return L".";
    return path.substr(0, pos);
}

static std::wstring strip_extension(const std::wstring &filename) {
    size_t pos = filename.find_last_of(L'.');
    if (pos == std::wstring::npos) return filename;
    return filename.substr(0, pos);
}

static bool write_text_file(const std::wstring &path, const std::string &content) {
    std::string npath = narrow_from_wide(path);
    std::ofstream ofs(npath, std::ios::out | std::ios::trunc | std::ios::binary);
    if (!ofs) return false;
    ofs.write(content.c_str(), (std::streamsize)content.size());
    return ofs.good();
}

static bool emit_stub_artifacts(const std::wstring &inputPath, const std::wstring &outputDirOpt) {
    std::wstring dir = outputDirOpt.empty() ? get_dirname(inputPath) : outputDirOpt;
    std::wstring moduleNameW = strip_extension(get_filename(inputPath));
    std::string moduleName = narrow_from_wide(moduleNameW);

    std::wstring solPath = dir + L"\\" + moduleNameW + L".sol";
    std::wstring rsPath  = dir + L"\\" + moduleNameW + L".rs";
    std::wstring goPath  = dir + L"\\" + moduleNameW + L".go";

    std::ostringstream sol;
    sol << "// SPDX-License-Identifier: MIT\n"
        << "pragma solidity ^0.8.19;\n\n"
        << "// Generated by OMEGA Production Wrapper (stub)\n"
        << "contract " << moduleName << " {\n"
        << "    // Placeholder implementation generated due to native emitter failure\n"
        << "}\n";

    std::ostringstream rs;
    rs << "// Generated by OMEGA Production Wrapper (stub)\n"
       << "use anchor_lang::prelude::*;\n\n"
       << "#[program]\n"
       << "pub mod " << moduleName << " {\n"
       << "    use super::*;\n"
       << "    // Placeholder implementation generated due to native emitter failure\n"
       << "}\n";

    std::ostringstream go;
    go << "package " << moduleName << "\n\n"
       << "// Generated by OMEGA Production Wrapper (stub)\n"
       << "// Placeholder implementation generated due to native emitter failure\n";

    bool okSol = write_text_file(solPath, sol.str());
    bool okRs  = write_text_file(rsPath, rs.str());
    bool okGo  = write_text_file(goPath, go.str());

    if (!okSol) {
        std::wcerr << L"[ERROR] Failed to write stub Solidity artifact: " << solPath << std::endl;
        return false;
    }
    std::wcout << L"[INFO] Stub EVM output written to: " << solPath << std::endl;
    if (okRs)  std::wcout << L"[INFO] Stub Solana output written to: " << rsPath << std::endl;
    if (okGo)  std::wcout << L"[INFO] Stub Cosmos output written to: " << goPath << std::endl;
    return true;
}

int wmain(int argc, wchar_t* argv[]) {
    std::set_terminate(omega_terminate_handler);

    std::wcout << L"OMEGA Production Wrapper" << std::endl;
    std::wcout << L"Build Date: 2025-01-13" << std::endl;
    if (argc < 2) {
        std::wcerr << L"Usage: omega-production.exe [compile|build|deploy|test|version|help]" << std::endl;
        return 1;
    }

    std::wstring command = argv[1];
    std::wstring omegaExe = L"omega.exe"; // Assume same directory
    std::wstring repoDir = L".";          // Current repo root

    if (command == L"version") {
        std::wcout << L"OMEGA Compiler v1.3.0 - Production Ready" << std::endl;
        return 0;
    } else if (command == L"help") {
        std::wcout << L"Usage: omega-production.exe <command> [options]" << std::endl;
        std::wcout << L"  compile {file.omega}    - Compile an OMEGA source file" << std::endl;
        std::wcout << L"  build                   - Build project" << std::endl;
        std::wcout << L"  deploy --target {chain} - Deploy to target blockchain" << std::endl;
        std::wcout << L"  test                    - Run test suite" << std::endl;
        std::wcout << L"  version                 - Show version" << std::endl;
        return 0;
    } else if (command == L"compile") {
        if (argc < 3) {
            std::wcerr << L"Error: No input file specified" << std::endl;
            std::wcerr << L"Usage: omega-production.exe compile {file.omega}" << std::endl;
            return 1;
        }
        std::wstring input = argv[2];
        // Parse optional flags from original argv
        std::wstring target; std::wstring outputDir;
        for (int i = 3; i < argc; ++i) {
            std::wstring tok = argv[i];
            if (tok == L"--target" && i + 1 < argc) { target = argv[i + 1]; i++; continue; }
            if (tok == L"--output" && i + 1 < argc) { outputDir = argv[i + 1]; i++; continue; }
        }
        // Proxy to omega.exe compile, preserve additional args
        std::vector<std::wstring> args;
        args.push_back(L"compile");
        args.push_back(input);
        for (int i = 3; i < argc; ++i) args.push_back(argv[i]);
        DWORD code = 0; run_in_dir(repoDir, omegaExe, args, code);
        if (code != 0) {
            std::wcerr << L"[ERROR] omega.exe compile failed (exit=" << code << L")" << std::endl;
            return (int)code;
        }
        return (int)code;
    } else if (command == L"test" || command == L"deploy" || command == L"build") {
        // Delegate to omega.exe for now
        std::vector<std::wstring> args; args.push_back(command);
        for (int i = 2; i < argc; ++i) args.push_back(argv[i]);
        DWORD code = 0; run_in_dir(repoDir, omegaExe, args, code);
        return (int)code;
    } else {
        std::wcerr << L"Error: Unknown command '" << command << L"'" << std::endl;
        return 1;
    }
}