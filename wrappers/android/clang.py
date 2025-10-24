#!/usr/bin/python3
import os
import sys
from pathlib import Path

class CompilerWrapper():
    def __init__(self, argv):
        self.args = argv[1:]
        self.real_compiler = None
        self.argv0 = argv[0]
        self.real_compiler = Path(__file__).resolve().parent / "clang.real"

    def parse_custom_flags(self):
        prepend_flags = []
        append_flags = ["-O3", "-g0", "-fno-stack-protector", "-fno-plt"]
        is_target = any(arg.startswith("--target=aarch64-linux-android") for arg in self.args)
        if is_target:
            try:
                pgo_stage = int(os.getenv("PGO_STAGE", "0"))
            except ValueError:
                pgo_stage = 0
            if pgo_stage != 1 and pgo_stage != 2:
                append_flags += ["-flto=full"]
            gecko = os.getenv("GECKO_PATH", "")
            match pgo_stage:
                case 1:
                    append_flags += ["-fprofile-generate", "-mllvm=-pgo-temporal-instrumentation"]
                case 2:
                    append_flags += [f"-fprofile-use={gecko}/workspace/merged.profdata", "-DMOZ_PROFILE_GENERATE", "-fcs-profile-generate", "-mllvm=-pgo-temporal-instrumentation"]
                case 3:
                    append_flags += [f"-fprofile-use={gecko}/workspace/merged-cs.profdata"]
            env_prepend = os.getenv("CLANG_WRAPPER_TARGET_PREPEND")
            env_append = os.getenv("CLANG_WRAPPER_TARGET_APPEND")
        else:
            env_prepend = os.getenv("CLANG_WRAPPER_HOST_PREPEND")
            env_append = os.getenv("CLANG_WRAPPER_HOST_APPEND")
        if env_prepend:
            prepend_flags += env_prepend.split()
        if env_append:
            append_flags += env_append.split()
        self.args = prepend_flags + self.args + append_flags

    def invoke_compiler(self):
        self.parse_custom_flags()
        execargs = [self.argv0] + self.args
        if os.getenv("WRAPPER_WRITE_LOG"):
            with open("/tmp/clang-wrapper-log.txt", "a") as log_file:
                log_file.write(' '.join(execargs) + '\n')
        os.execv(self.real_compiler, execargs)


def main(argv):
    cw = CompilerWrapper(argv)
    cw.invoke_compiler()

if __name__ == "__main__":
    main(sys.argv)
