#!/usr/bin/python3
import os
import subprocess
import sys

class CompilerWrapper():
    def __init__(self, argv):
        wrapper_path = os.path.abspath(sys.executable)
        basename = os.path.basename(wrapper_path)
        self.driver_mode = 1
        if basename.startswith("clang++"):
            self.driver_mode = 2
        elif basename.startswith("clang-cl"):
            self.driver_mode = 3
        self.real_compiler = os.path.join(os.path.dirname(wrapper_path), "clang.real.exe")
        self.args = argv[1:]

    def parse_custom_flags(self):
        prepend_flags = []
        append_flags = []
        match self.driver_mode:
            case 1:
                prepend_flags += ["--driver-mode=gcc"]
            case 2:
                prepend_flags += ["--driver-mode=g++"]
            case 3:
                prepend_flags += ["--driver-mode=cl"]
        if self.driver_mode == 3:
            append_flags += ["/clang:-O3", "/clang:-fno-stack-protector", "/clang:-ffp-contract=fast", "/Gr"]
        else:
            append_flags += ["-O3", "-fno-stack-protector", "-ffp-contract=fast"]
        gecko = os.getenv("GECKO_PATH", "")
        if os.getenv("GEN_PGO"):
            append_flags += ["-fprofile-generate", "-mllvm=-pgo-temporal-instrumentation"]
        elif os.getenv("CSIR_PGO"):
            append_flags += [f"-fprofile-use={gecko}/workspace/merged.profdata", "-DMOZ_PROFILE_GENERATE", "-fcs-profile-generate", "-mllvm=-pgo-temporal-instrumentation"]
        elif os.getenv("USE_PGO"):
            append_flags += ["-flto=full", f"-fprofile-use={gecko}/workspace/merged-cs.profdata"]
        env_prepend = os.getenv("WRAPPER_PREPEND")
        if env_prepend:
            prepend_flags += env_prepend.split()
        env_append = os.getenv("WRAPPER_APPEND")
        if env_append:
            append_flags += env_append.split()
        append_flags += ["-w"]
        self.args = prepend_flags + self.args
        if "--" in self.args:
            idx = self.args.index("--")
            self.args = self.args[:idx] + append_flags + self.args[idx:]
        else:
            self.args += append_flags


    def invoke_compiler(self):
        self.parse_custom_flags()
        execargs = [self.real_compiler] + self.args
        # with open(r"C:\Users\HeXis\firefox-vanilla\wrapper-log.txt", "a") as log_file:
        #     log_file.write(' '.join(execargs) + '\n')
        result = subprocess.run(execargs)
        sys.exit(result.returncode)


def main(argv):
    cw = CompilerWrapper(argv)
    cw.invoke_compiler()

if __name__ == "__main__":
    main(sys.argv)
