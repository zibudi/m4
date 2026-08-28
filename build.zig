const std = @import("std");

const sources: []const []const u8 = &.{
    "eval.c",    "expr.c",  "gnum4.c", "look.c",     "main.c",
    "misc.c",    "ohash.c", "trace.c", "strtonum.c",
    // Our own copies rather than the libc ones, so the build does not depend on
    // which libc version happens to have them.
    "reallocarray.c",
    "strlcpy.c",
};

// parser.y and tokenizer.l need yacc and lex, and lex is flex, which needs an m4
// to run. Generated once with our own byacc and flex, and checked against them
// again in CI, because the cycle cannot be broken any other way.
const generated: []const []const u8 = &.{ "parser.c", "tokenizer.c" };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "m4",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    b.installArtifact(exe);

    // Several sources include "config.h"; upstream's configure writes three lines.
    const config = b.addWriteFiles();
    _ = config.add("config.h", "#define __dead __attribute__((__noreturn__))\n");

    exe.root_module.addCMacro("EXTENDED", "1");
    exe.root_module.addCMacro("_GNU_SOURCE", "1");
    exe.root_module.addIncludePath(config.getDirectory());
    exe.root_module.addIncludePath(b.path("."));
    exe.root_module.addIncludePath(b.path("generated"));
    exe.root_module.addCSourceFiles(.{ .root = b.path("."), .files = sources });
    exe.root_module.addCSourceFiles(.{ .root = b.path("generated"), .files = generated });
}
