#!/usr/bin/python3
import os
import sys
from pathlib import Path

class CompilerWrapper():
    def __init__(self, argv):
        self.argv0 = argv[0]
        self.args = argv[1:]
        self.real_compiler = Path(__file__).resolve().parent / "clang.real"

    def parse_custom_flags(self):
        is_target = False
        is_conftest = False
        for arg in self.args:
            if not is_target and arg.startswith("--target=aarch64-linux-android"):
                is_target = True
            arg_list = arg.split('/')
            if arg_list[-1].startswith("conftest"):
                is_conftest = True
                break
        do_link = not ("-c" in self.args or "-E" in self.args)

        prepend_flags = []
        append_flags = ["-pipe"]

        if not is_target or is_conftest:
            if do_link:
                append_flags += ["-fuse-ld=mold"]
            self.args += append_flags
            return

        append_flags += ["-Wno-unused-command-line-argument"]
        append_flags += ["-O3", "-g0", "-fno-stack-protector", "-fno-plt"]
        if do_link:
            append_flags += ["-Wl,-O2,--icf=all,--as-needed,--sort-common"]

        try:
            pgo_stage = int(os.getenv("PGO_STAGE", "0"))
        except ValueError:
            pgo_stage = 0

        gecko = os.getenv("GECKO_PATH", "")
        match pgo_stage:
            case 1 | 2:
                append_flags += ["-DMOZ_PROFILE_GENERATE", "-mllvm=-pgo-temporal-instrumentation"]
                if do_link:
                    append_flags += ["-fuse-ld=mold"]
                if pgo_stage == 1:
                    append_flags += ["-fprofile-generate"]
                else:
                    append_flags += [f"-fprofile-use={gecko}/workspace/merged.profdata", "-fcs-profile-generate"]
            case _:
                append_flags += ["-ffunction-sections", "-fdata-sections"]
                append_flags += ["-flto=full", "-fwhole-program-vtables", "-fvirtual-function-elimination"]
                if do_link:
                    append_flags += ["-fuse-ld=lld", "-s", "-Wl,--gc-sections,-mllvm,-enable-ext-tsp-block-placement=1"]
                    append_flags += ["-Wl,--lto-O3,--lto-partitions=1"]
                if pgo_stage == 3:
                    append_flags += [f"-fprofile-use={gecko}/workspace/merged-cs.profdata"]

        env_prepend = os.getenv("CLANG_WRAPPER_TARGET_PREPEND")
        if env_prepend:
            prepend_flags += env_prepend.split()
        env_append = os.getenv("CLANG_WRAPPER_TARGET_APPEND")
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
