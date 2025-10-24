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
            append_flags += ["/O2", "/clang:-fno-stack-protector", "/clang:-fno-plt", "/clang:-ffp-contract=fast", "/Gr", "/guard:cf-"]
        else:
            append_flags += ["-O3", "-fno-stack-protector", "-fno-plt", "-ffp-contract=fast"]
        if os.getenv("TREAT_HOST_AS_TARGET"):
            is_target = True
        else:
            is_target = any(arg.startswith("-fms-compatibility-version") for arg in self.args)
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
            if self.driver_mode == 3:
                env_prepend = os.getenv("CLANG_CL_WRAPPER_TARGET_PREPEND")
                env_append = os.getenv("CLANG_CL_WRAPPER_TARGET_APPEND")
            else:
                env_prepend = os.getenv("CLANG_WRAPPER_TARGET_PREPEND")
                env_append = os.getenv("CLANG_WRAPPER_TARGET_APPEND")
        else:
            if self.driver_mode == 3:
                env_prepend = os.getenv("CLANG_CL_WRAPPER_HOST_PREPEND")
                env_append = os.getenv("CLANG_CL_WRAPPER_HOST_APPEND")
            else:
                env_prepend = os.getenv("CLANG_WRAPPER_HOST_PREPEND")
                env_append = os.getenv("CLANG_WRAPPER_HOST_APPEND")
        if env_prepend:
            prepend_flags += env_prepend.split()
        if env_append:
            append_flags += env_append.split()
        self.args = prepend_flags + self.args
        if "--" in self.args:
            idx = self.args.index("--")
            self.args = self.args[:idx] + append_flags + self.args[idx:]
        else:
            self.args += append_flags

    def invoke_compiler(self):
        self.parse_custom_flags()
        execargs = [self.real_compiler] + self.args
        if os.getenv("WRAPPER_WRITE_LOG"):
            with open(r"C:\mozilla-build\msys2\tmp\clang-wrapper-log.txt", "a") as log_file:
                log_file.write(' '.join(execargs) + '\n')
        result = subprocess.run(execargs)
        sys.exit(result.returncode)


def main(argv):
    cw = CompilerWrapper(argv)
    cw.invoke_compiler()

if __name__ == "__main__":
    main(sys.argv)
