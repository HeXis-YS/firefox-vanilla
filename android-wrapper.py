#!/usr/bin/python3
import os
import sys

class CompilerWrapper():
    def __init__(self, argv):
        self.args = argv[1:]
        self.real_compiler = None
        self.argv0 = argv[0]
        compiler_path = os.path.dirname(os.path.abspath(__file__))
        self.real_compiler = os.path.join(compiler_path, "clang-18")

    def parse_custom_flags(self):
        prepend_flags = []
        append_flags = []
        self.args = [item for item in self.args if not item.startswith('-O')]
        append_flags += ["-w", "-O3", "-fno-stack-protector", "-s"]
        if not "--target=aarch64-linux-android21" in self.args:
            append_flags += ["-march=native"]
            return
        gecko = os.getenv("GECKO_PATH", "")
        if os.getenv("GEN_PGO"):
            append_flags += ["-fprofile-generate", "-mllvm=-pgo-temporal-instrumentation"]
        elif os.getenv("CSIR_PGO"):
            append_flags += [f"-fprofile-use={gecko}/workspace/merged.profdata", "-DMOZ_PROFILE_GENERATE", "-fcs-profile-generate", "-mllvm=-pgo-temporal-instrumentation"]
        elif os.getenv("USE_PGO"):
            append_flags += [f"-fprofile-use={gecko}/workspace/merged-cs.profdata", "-flto"]
        env_prepend = os.getenv("WRAPPER_PREPEND")
        if env_prepend:
            prepend_flags += env_prepend.split()
        env_append = os.getenv("WRAPPER_APPEND")
        if env_append:
            append_flags += env_append.split()
        self.args = prepend_flags + self.args + append_flags

    def invoke_compiler(self):
        self.parse_custom_flags()
        execargs = [self.argv0] + self.args
        # with open("/tmp/wrapper-log", "a") as log_file:
        #     log_file.write(' '.join(execargs) + '\n')
        os.execv(self.real_compiler, execargs)


def main(argv):
    cw = CompilerWrapper(argv)
    cw.invoke_compiler()

if __name__ == "__main__":
    main(sys.argv)
