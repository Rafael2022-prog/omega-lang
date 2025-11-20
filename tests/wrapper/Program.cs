using System;
using System.IO;
using Omega.Production;

internal static class Program
{
    private static int failures = 0;

    private static int Main()
    {
        var root = GetRepoRoot();
        var config = OmegaConfig.Load(root);
        var wrapper = new OmegaProductionWrapper();

        Test("GetVersion returns non-empty", () => !string.IsNullOrWhiteSpace(wrapper.GetVersion(config)));

        Test("GetHelp contains 'compile'", () => wrapper.GetHelp().Contains("compile", StringComparison.OrdinalIgnoreCase));

        var testDir = Path.Combine(root, "validation_output", "wrapper_tests");
        Directory.CreateDirectory(testDir);
        var inputOmega = Path.Combine(testDir, "Sample.omega");
        File.WriteAllText(inputOmega, "// sample contract for wrapper tests");

        // Force fallback to exercise stub emission without native compiler
        var forced = new OmegaConfig
        {
            RootDir = root,
            OmegaExePath = Path.Combine(root, "omega.exe"),
            FallbackEnabled = true,
            ForceFallback = true,
            OutputDir = testDir,
        };

        var res = wrapper.Compile(inputOmega, TargetType.Evm, null, forced);
        Test("Compile with ForceFallback emits stub .sol", () => res.Success && File.Exists(res.OutputPath) && res.OutputPath.EndsWith(".sol", StringComparison.OrdinalIgnoreCase));

        var ok = wrapper.EmitStubArtifacts(TargetType.Cosmos, inputOmega, testDir, "unit-test", out var stubPath);
        Test("EmitStubArtifacts for Cosmos produces .go", () => ok && File.Exists(stubPath) && stubPath.EndsWith(".go", StringComparison.OrdinalIgnoreCase));

        Console.WriteLine(failures == 0 ? "ALL TESTS PASSED" : $"{failures} TEST(S) FAILED");
        return failures == 0 ? 0 : 1;
    }

    private static void Test(string name, Func<bool> check)
    {
        try
        {
            if (check())
            {
                Console.WriteLine($"[PASS] {name}");
            }
            else
            {
                failures++;
                Console.WriteLine($"[FAIL] {name}");
            }
        }
        catch (Exception ex)
        {
            failures++;
            Console.WriteLine($"[FAIL] {name} - Exception: {ex.Message}");
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