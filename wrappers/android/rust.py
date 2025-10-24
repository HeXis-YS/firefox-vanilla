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
        prepend_flags = []
        append_flags = ["-C", "opt-level=3", "-C", "debuginfo=none", "-C", "force-frame-pointers=no", "-C", "force-unwind-tables=no", "-C", "panic=abort"]
        is_target = False
        try:
            i = self.args.index("--target")
            if self.args[i + 1] == "aarch64-linux-android":
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
                        if self.args[i + 1] in ["audio_thread_priority", "gkrust"]:
                            use_lto = False
                    except:
                        pass
                    if use_lto:
                        append_flags += ["-C", "embed-bitcode=yes", "-C", "lto=fat"]
            gecko = os.getenv("GECKO_PATH", "")
            match pgo_stage:
                case 1:
                    append_flags += ["-C", "profile-generate", "-C", "llvm-args=--pgo-temporal-instrumentation"]
                case 2:
                    append_flags += ["-C", f"profile-use={gecko}/workspace/merged.profdata", "-C", "llvm-args=--cs-profile-generate", "-C", "llvm-args=--pgo-temporal-instrumentation"]
                case 3:
                    append_flags += ["-C", f"profile-use={gecko}/workspace/merged-cs.profdata"]
            env_prepend = os.getenv("RUST_WRAPPER_TARGET_PREPEND")
            env_append = os.getenv("RUST_WRAPPER_TARGET_APPEND")
        else:
            append_flags += ["-C", "codegen-units=16"]
            env_prepend = os.getenv("RUST_WRAPPER_HOST_PREPEND")
            env_append = os.getenv("RUST_WRAPPER_HOST_APPEND")
        if env_prepend:
            prepend_flags += env_prepend.split()
        if env_append:
            append_flags += env_append.split()
        self.args = prepend_flags + self.args + append_flags

    def invoke_compiler(self):
        self.parse_custom_flags()
        execargs = [self.argv0] + self.args
        if os.getenv("WRAPPER_WRITE_LOG"):
            with open("/tmp/rust-wrapper-log.txt", "a") as log_file:
                log_file.write(' '.join(execargs) + '\n')
        os.execv(self.real_compiler, execargs)


def main(argv):
    cw = CompilerWrapper(argv)
    cw.invoke_compiler()

if __name__ == "__main__":
    main(sys.argv)
