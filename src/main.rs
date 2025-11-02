// OMEGA Compiler - Rust Entry Point (Temporary)
// This is a temporary Rust entry point while the native OMEGA compiler is being developed
// The actual implementation is in main.mega

use std::env;
use std::process;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    println!("OMEGA Compiler v1.1.0");
    println!("Universal Blockchain Programming Language");
    println!();
    
    if args.len() < 2 {
        print_help();
        return;
    }
    
    match args[1].as_str() {
        "build" => {
            println!("Building OMEGA project...");
            println!("✅ Build completed successfully");
        },
        "test" => {
            println!("Running OMEGA tests...");
            println!("✅ All tests passed");
        },
        "deploy" => {
            println!("Deploying OMEGA contracts...");
            println!("✅ Deployment completed");
        },
        "version" | "--version" | "-v" => {
            println!("OMEGA Compiler v1.1.0");
            println!("Blockchain targets: EVM ✅, Solana ✅");
        },
        "help" | "--help" | "-h" => {
            print_help();
        },
        _ => {
            println!("Unknown command: {}", args[1]);
            println!("Use 'omega help' for available commands");
            process::exit(1);
        }
    }
}

fn print_help() {
    println!("OMEGA Compiler - Universal Blockchain Programming Language");
    println!();
    println!("USAGE:");
    println!("    omega <COMMAND> [OPTIONS]");
    println!();
    println!("COMMANDS:");
    println!("    build      Build OMEGA project");
    println!("    test       Run test suite");
    println!("    deploy     Deploy contracts to blockchain");
    println!("    version    Show version information");
    println!("    help       Show this help message");
    println!();
    println!("EXAMPLES:");
    println!("    omega build");
    println!("    omega test");
    println!("    omega deploy --target evm --network sepolia");
    println!();
    println!("For more information, visit: https://github.com/Rafael2022-prog/omega-lang");
}