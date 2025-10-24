#!/usr/bin/python3
import os
import subprocess
import sys
from pathlib import Path

class CompilerWrapper():
    def __init__(self, argv):
        wrapper_path = os.path.abspath(sys.executable)
        self.real_compiler = os.path.join(os.path.dirname(wrapper_path), "rustc.real.exe")
        self.args = argv[1:]

    def parse_custom_flags(self):
        if not any(arg.startswith("--crate-name") for arg in self.args):
            return
        prepend_flags = []
        append_flags = ["-C", "opt-level=3", "-C", "debuginfo=none", "-C", "force-frame-pointers=no", "-C", "panic=abort", "-C", "control-flow-guard=no"]
        if os.getenv("TREAT_HOST_AS_TARGET"):
            is_target = True
        else:
            is_target = False
            try:
                i = self.args.index("--target")
                if self.args[i + 1] == "x86_64-pc-windows-msvc" and "--crate-name" in self.args:
                    is_target = True
            except:
                pass
        if is_target:
            try:
                pgo_stage = int(os.getenv("PGO_STAGE", "0"))
            except ValueError:
                pgo_stage = 0
            match pgo_stage:
                case 1 | 2:
                    append_flags += ["-C", "codegen-units=16"]
                case _:
                    append_flags += ["-C", "codegen-units=1"]
                    use_lto = True
                    try:
                        i = self.args.index("--crate-name")
                        if self.args[i + 1] in ["audio_thread_priority", "gkrust_uniffi_components"]:
                            use_lto = False
                    except:
                        pass
                    if use_lto:
                        append_flags += ["-C", "embed-bitcode=yes", "-C", "lto=fat", "-Z", "dylib-lto"]
            gecko = os.getenv("GECKO_PATH", "")
            match pgo_stage:
                case 1:
                    append_flags += ["-C", "profile-generate", "-C", "llvm-args=--pgo-temporal-instrumentation"]
                case 2:
                    append_flags += ["-C", f"profile-use={gecko}/workspace/merged.profdata"]
                case 3:
                    append_flags += ["-C", f"profile-use={gecko}/workspace/merged-cs.profdata"]
            env_prepend = os.getenv("RUST_WRAPPER_TARGET_PREPEND")
            env_append = os.getenv("RUST_WRAPPER_TARGET_APPEND")
        else:
            append_flags += ["-C", "codegen-units=16"]
            env_prepend = os.getenv("RUST_WRAPPER_HOST_PREPEND")
            env_append = os.getenv("RUST_WRAPPER_HOST_APPEND")
        if env_prepend is not None:
            prepend_flags += env_prepend.split()
        if env_append is not None:
            append_flags += env_append.split()
        self.args = prepend_flags + self.args + append_flags


    def invoke_compiler(self):
        self.parse_custom_flags()
        execargs = [self.real_compiler] + self.args
        if os.getenv("WRAPPER_WRITE_LOG"):
            with open(r"C:\mozilla-build\msys2\tmp\rust-wrapper-log.txt", "a") as log_file:
                log_file.write(' '.join(execargs) + '\n')
        result = subprocess.run(execargs)
        sys.exit(result.returncode)


def main(argv):
    cw = CompilerWrapper(argv)
    cw.invoke_compiler()

if __name__ == "__main__":
    main(sys.argv)
