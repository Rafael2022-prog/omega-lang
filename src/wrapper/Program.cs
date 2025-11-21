using System;
using System.IO;
using Omega.Production;

internal static class Program
{
    private static int Main(string[] args)
    {
        var config = OmegaConfig.Load(GetRepoRoot());
        var wrapper = new OmegaProductionWrapper();

        if (args.Length == 0)
        {
            Console.WriteLine(wrapper.GetHelp());
            return 0;
        }

        var command = args[0].ToLowerInvariant();
        switch (command)
        {
            case "version":
                Console.WriteLine(wrapper.GetVersion(config));
                return 0;
            case "help":
                Console.WriteLine(wrapper.GetHelp());
                return 0;
            case "compile":
                return HandleCompile(args, wrapper, config);
            default:
                Console.Error.WriteLine($"Unknown command: {command}");
                Console.WriteLine(wrapper.GetHelp());
                return 1;
        }
    }

    private static int HandleCompile(string[] args, IOmegaProductionWrapper wrapper, OmegaConfig config)
    {
        string? targetStr = null;
        string? inputPath = null;
        string? outputPath = null;

        for (int i = 1; i < args.Length; i++)
        {
            var a = args[i];
            if (a == "--target" && i + 1 < args.Length) { targetStr = args[++i]; }
            else if (a == "--input" && i + 1 < args.Length) { inputPath = args[++i]; }
            else if (a == "--output" && i + 1 < args.Length) { outputPath = args[++i]; }
        }

        if (string.IsNullOrWhiteSpace(targetStr) || string.IsNullOrWhiteSpace(inputPath))
        {
            Console.Error.WriteLine("compile requires --target and --input");
            Console.WriteLine(wrapper.GetHelp());
            return 1;
        }

        if (!File.Exists(inputPath))
        {
            Console.Error.WriteLine($"Input file not found: {inputPath}");
            // Allow fallback to still succeed
        }

        var target = targetStr!.ToLowerInvariant() switch
        {
            "evm" => TargetType.Evm,
            "solana" => TargetType.Solana,
            "cosmos" => TargetType.Cosmos,
            _ => throw new ArgumentException($"Unsupported target: {targetStr}")
        };

        var result = wrapper.Compile(inputPath!, target, outputPath, config);
        if (result.Success)
        {
            Console.WriteLine($"Output: {result.OutputPath}");
            if (!string.IsNullOrWhiteSpace(result.Message)) Console.WriteLine(result.Message);
            return 0;
        }
        else
        {
            if (!string.IsNullOrWhiteSpace(result.Message)) Console.Error.WriteLine(result.Message);
            return result.ExitCode != 0 ? result.ExitCode : 1;
        }
    }

    private static string GetRepoRoot()
    {
        var dir = Directory.GetCurrentDirectory();
        for (int i = 0; i < 4; i++)
        {
            var ver = Path.Combine(dir, "VERSION");
            if (File.Exists(ver)) return dir;
            var parent = Directory.GetParent(dir)?.FullName;
            if (parent == null) break;
            dir = parent;
        }
        return Directory.GetCurrentDirectory();
    }
}