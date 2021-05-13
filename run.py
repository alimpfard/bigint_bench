import re
from subprocess import call, Popen, DEVNULL
import os
from time import sleep, time
import psutil

SKIP=1
RUN=2

all_tests = {
    "multiply": {
        "compile": {
            "C++": [["g++", "cpp.cxx", "-lgmp", "-lgmpxx", "-o", "build/cxx"]],
            "Citron (Unopt)": [["ctrc", "ctr.ctr", "build/ctru", "--heap-max=256M"]],
            "Citron (Opt)": [["ctrc", "ctr.ctr", "build/ctrx", "-O", "--heap-max=256M"]],
            "Citron (Opt, Heap=512M)": [["ctrc", "ctr.ctr", "build/ctrh", "-O", "--heap-max=512M", "--heap-size=512M"]],
            "Haskell": [["ghc", "hask.hs", "-o", "build/hask", "-no-keep-hi-files", "-no-keep-o-files"]],
            "Go": [["go", "build", "-o", "build/go", "go.go"]],
            "Java": [["javac", "-d", "build", "java.java"]],
            "Scala": [["scalac", "-d", "build", "-opt:_", "scala.sc"]],
            "Rust": [["cargo", "build", "--release", "--manifest-path", "rust/Cargo.toml", "-Z", "unstable-options", "--out-dir", "build"]],
            "Scheme": [["scheme", "--script", "scm.compile"]],
            "Kotlin": [["kotlinc", "kotlin.kt", "-include-runtime", "-d", "build/kotlin.jar"]],
        },
        "execute": {
            "C++": ["./cxx"],
            "Citron (Unopt)": ["./ctru"],
            "Citron (Opt)": ["./ctrx"],
            "Citron (Opt, Heap=512M)": ["./ctrh"],
            "Citron (Interp)": ["ctr", "../ctr.ctr"],
            "Haskell": ["./hask"],
            "Go": ["./go"],
            "Java": ["java", "F4"],
            "Scala": ["scala", "Main"],
            "Kotlin": ["kotlin", "kotlin.jar"],
            "Python (CPy)": ["python", "../python.py"],
            "Python (PyPy)": ["pypy3", "../python.py"],
            "PHP": ["php", "../php.php"],
            "Ruby": ["ruby", "../ruby.rb"],
            "Rust": ["./rust"],
            "JavaScript (Node)": ["node", "../js.js"],
            "JavaScript (LibJS)": ["serenity-js", "../js.js"],
        }
    }
}

def do_lang(lang):
    global env_specifics, env_override
    name, mode, *_ = list(map(lambda x: x.lower(), re.sub("[^a-zA-Z _+/-@#%^:]", "", lang).split(" ") + ['']))

    if env_override == SKIP and (env_specifics.get(name, False) or env_specifics.get(mode, False)):
        return False

    if env_override == RUN and not (env_specifics.get(name, False) or env_specifics.get(mode, False)):
        return False

    return True

class Process:
    def __init__(self, command):
        self.command = command
        self.is_running = False

    def run_and_wait(self):
        try:
            self.exec()
            while self.poll():
                sleep(0.2)
        finally:
            self.kill()

    def exec(self):
        self.max_rss = 0
        self.end = None
        self.start = time()
        self.p = Popen(self.command, stdout=DEVNULL, stderr=DEVNULL)
        self.is_running = True

    def poll(self):
        if not self.check():
            return False
        self.end = time()
        try:
            p = psutil.Process(self.p.pid)
            cs = [p] + p.children(recursive=True)
            rss = 0
            for c in cs:
                try:
                    meminfo = c.memory_info()
                    rss += meminfo.rss
                except psutil.NoSuchProcess:
                    pass
            self.max_rss = max(self.max_rss, rss)
        except psutil.NoSuchProcess:
            pass
        return self.check()

    def check(self):
        if not self.is_running:
            return False
        if psutil.pid_exists(self.p.pid) and self.p.poll() is None:
            return True
        self.is_running = False
        self.end = time()
        return False

    def kill(self):
        try:
            p = psutil.Process(self.p.pid)
            p.terminate()
        except:
            pass

def compile_suite(suite, name):
    if "compile" not in suite:
        return []

    print("-- Compiling suite", name)
    failed = []

    os.chdir(name)
    try:
        os.mkdir("build")
    except:
        pass

    for lang, spec in suite["compile"].items():
        if not do_lang(lang):
            continue
        print("-- Compile/Start", lang)
        for cmd in spec:
            ec = call(cmd)
            if ec != 0:
                failed.append(lang)
                print("-- Compile/Fail", lang)
                break
        print("-- Compile/End", lang)

    os.chdir("..")

    return failed

def run_suite(suite, name):
    if "execute" not in suite:
        return {}

    results = {}
    print("-- Executing suite", name)

    os.chdir(f'{name}/build')

    for lang, spec in suite["execute"].items():
        if not do_lang(lang):
            continue
        print("-- Execute/Start", lang)
        p = Process(spec)
        p.run_and_wait()
        results[lang] = {
            "time": p.end - p.start,
            "memory": p.max_rss,
        }
        print("-- Execute/End", lang)

    os.chdir('../..')
    return results

GNUPLOT_SOURCE_FORMAT = """
set term pngcairo size 1200,800;
set output "plots/{}.png";
set boxwidth 0.2;
set style fill solid;
set y2tics;
set y2label "Memory Usage (MiB)";
set title "Runtime; {}";
set xtic rotate by 45 right;
set ylabel "Time (s)";
plot "data.dat" using 3:xtic(2) with boxes title "Runtime",
     "memories" using ($2/1024/1024) axes x1y2 lc rgb "red" with histogram title "Memory",
     "data.dat" using 1:($3+10):3 with labels font "Helvetica,10" offset 0,-1 notitle;
"""

def generate_plot(res):
    try:
        os.mkdir("plots")
    except:
        pass

    for name, res in res.items():
        source = GNUPLOT_SOURCE_FORMAT.format(name, name)
        mf = open("memories", "w")
        md = open("data.dat", "w")
        for (index, (lang, mt)) in enumerate(sorted(res.items(), key=lambda x: x[1]["time"])):
            md.write(f'{index} " {lang} " {mt["time"]:0.3f}\n')
            mf.write(f'" {lang} " {mt["memory"]}\n')
        mf.close()
        md.close()
        call(["gnuplot", "-e", source])

def run_all_tests():
    comp_fails = {}
    for name, suite in all_tests.items():
        res = compile_suite(suite, name)
        if len(res):
            comp_fails[name] = res
    if len(comp_fails):
        print("!!! The following suites failed to compile")
        for name, entries in comp_fails.items():
            print('-', name)
            for name in entries:
                print('    -', name)
        return
    res = {}
    for name, suite in all_tests.items():
        res[name] = run_suite(suite, name)
    generate_plot(res)

env_override = None
env_specifics = {}

if __name__ == '__main__':
    override = os.environ.get("BENCH_OVERRIDE", "")
    if override.lower() == "skip":
        env_override = SKIP
    elif override.lower() == "run":
        env_override = RUN

    if env_override is not None:
        for name, value in os.environ.items():
            if name.lower().startswith("bench_"):
                env_specifics[name.lower()[len("bench_"):]] = value.lower() in ("true", "yes", "1")

    run_all_tests()
