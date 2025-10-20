#!/usr/bin/python3
import os
import sys

class CompilerWrapper():
    def __init__(self, argv):
        self.args = argv[1:]
        self.real_compiler = None
        self.argv0 = argv[0]
        self.real_compiler = Path(__file__).resolve().parent / "rustc.real"

    def parse_custom_flags(self):
        if not any(arg.startswith("--crate-name") for arg in self.args):
            return
        fast_build_flags = ["-C", "opt-level=s", "-C", "codegen-units=16", "-C", "embed-bitcode=no", "-C", "lto=no"]
        prepend_flags = []
        append_flags = ["-C", "debuginfo=none", "-C", "force-frame-pointers=no", "-C", "force-unwind-tables=no", "-C", "panic=abort"]
        is_target = False
        try:
            i = self.args.index("--target")
            if self.args[i + 1] == "aarch64-linux-android":
                is_target = True
        except:
            pass
        if not is_target:
            append_flags += fast_build_flags
            append_flags += ["-C", "target-cpu=native"]
            self.args += append_flags
            return
        gecko = os.getenv("GECKO_PATH", "")
        if not os.getenv("USE_PGO"):
            append_flags += fast_build_flags
            if os.getenv("GEN_PGO"):
                append_flags += ["-C", "profile-generate", "-C", "llvm-args=--pgo-temporal-instrumentation"]
            elif os.getenv("CSIR_PGO"):
                append_flags += ["-C", f"profile-use={gecko}/workspace/merged.profdata", "-C", "llvm-args=--cs-profile-generate", "-C", "llvm-args=--pgo-temporal-instrumentation"]
        else:
            append_flags += ["-C", "opt-level=3", "-C", "codegen-units=1"]
            disable_lto = False
            try:
                i = self.args.index("--crate-name")
                if self.args[i + 1] in ["audio_thread_priority", "gkrust"]:
                    disable_lto = True
            except:
                pass
            if disable_lto:
                append_flags += ["-C", "embed-bitcode=no", "-C", "lto=no"]
            else:
                append_flags += ["-C", "embed-bitcode=yes", "-C", "lto=fat"]
            append_flags += ["-C", f"profile-use={gecko}/workspace/merged-cs.profdata"]
        env_prepend = os.getenv("RUST_WRAPPER_PREPEND")
        if env_prepend:
            prepend_flags += env_prepend.split()
        env_append = os.getenv("RUST_WRAPPER_APPEND")
        if env_append:
            append_flags += env_append.split()
        self.args = prepend_flags + self.args + append_flags

    def invoke_compiler(self):
        self.parse_custom_flags()
        execargs = [self.argv0] + self.args
        # with open("/tmp/rust-wrapper-log", "a") as log_file:
        #     log_file.write(' '.join(execargs) + '\n')
        os.execv(self.real_compiler, execargs)


def main(argv):
    cw = CompilerWrapper(argv)
    cw.invoke_compiler()

if __name__ == "__main__":
    main(sys.argv)
