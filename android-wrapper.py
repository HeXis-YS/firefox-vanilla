#!/usr/bin/python3
import os
import sys

class CompilerWrapper():
    def __init__(self, argv):
        self.args = argv[1:]
        self.real_compiler = None
        self.argv0 = argv[0]

    def set_real_compiler(self):
        compiler_path = os.path.dirname(os.path.abspath(__file__))
        self.real_compiler = os.path.join(compiler_path, "clang-18")

    def parse_custom_flags(self):
        self.args = [item for item in self.args if not item.startswith('-O')]
        self.args += ["-Wno-unused-command-line-argument", "-O3", "-fno-stack-protector", "-s"]
        if not "--target=aarch64-linux-android21" in self.args:
            self.args += ["-march=native"]
            return
        def add_flags_if_missing(prefix, flags):
            if not any(arg.startswith(prefix) for arg in self.args):
                self.args += flags
        gecko = os.getenv("GECKO_PATH", "")
        if os.getenv("GEN_PGO"):
            add_flags_if_missing("-fprofile-generate", ["-fprofile-generate", "-mllvm=-pgo-temporal-instrumentation"])
        elif os.getenv("CSIR_PGO"):
            add_flags_if_missing("-fprofile-use", [f"-fprofile-use={gecko}/workspace/merged.profdata"])
            self.args += ["-DMOZ_PROFILE_GENERATE", "-fcs-profile-generate", "-mllvm=-pgo-temporal-instrumentation"]
        elif os.getenv("USE_PGO"):
            add_flags_if_missing("-flto", "-flto")
            add_flags_if_missing("-fprofile-use", [f"-fprofile-use={gecko}/workspace/merged-cs.profdata"])
        env_prepend = os.getenv("WRAPPER_PREPEND")
        if env_prepend:
            self.args = env_prepend.split() + self.args
        env_append = os.getenv("WRAPPER_APPEND")
        if env_append:
            self.args += env_append.split()

    def invoke_compiler(self):
        self.set_real_compiler()
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
