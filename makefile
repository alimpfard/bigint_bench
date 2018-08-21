all: clean build_buildables check format_results sort_results generate_gnuplot

quick: clean build_buildables check_fast format_results sort_results generate_gnuplot

clean:
	rm -f hask hask.hi hask.o a.out go *.class rustx rust/target/release/rust ctr
	mv results results.last || true

build_buildables: b_cxx b_hask b_go b_java b_scala b_rust b_scm b_ctr

check: c_cxx c_hask c_go c_java c_scala c_rust c_ctr_n c_ctr_c c_py c_rb c_scm c_js

check_fast: c_cxx c_hask c_go c_java c_scala c_rust c_ctr_n c_ctr_c c_py c_rb

generate_gnuplot:
	cat results | sed -e 's/( /(/g' | awk -e '{print NR-1, "\"", $$1, "\"", substr($$5, 0,length($$5)-1)}' > data.dat.u
	./transl.sh data.dat.u > data.dat
	gnuplot -e 'set term pngcairo size 1200,800; set output "plot.png"; set boxwidth 0.5; set style fill solid; set title "Runtime; calc/print of 500000! (Lower is better)"; set xtic rotate by 45 right; plot "data.dat" using 1:3:xtic(2) with boxes'

generate_gnuplot_no_node:
	cat results | awk -e '{print NR-1, "\"", $$1, "\"", substr($$5, 0,length($$5)-1)}' > data.dat.u
	sed -i -e '/node/d' data.dat.u
	./transl.sh data.dat.u > data.dat
	gnuplot -e 'set term pngcairo size 1200,800; set output "plot.png"; set boxwidth 0.5; set style fill solid; set title "Runtime; calc/print of 500000! (Lower is better)"; set xtic rotate by 45 right; plot "data.dat" using 1:3:xtic(2) with boxes'

format_results:
	cat results | perl -ne '/^((?:.\/)?\w+).*&3  (.*) user (.*) system (.*) cpu (.*) total/ && print((sprintf  "%-7s -> (%4s cpu) %8s user %5s system %14s total\n", $$1, $$4, $$2, $$3, $$5))' > results_formatted
	mv results_formatted results

sort_results:
	sort -g -s -k1.23 results > results_sorted

b_cxx:
	g++ cpp.cxx -lgmp -lgmpxx >/dev/null 2>&1

b_hask:
	ghc -O hask.hs >/dev/null 2>&1

b_go:
	go build go.go >/dev/null 2>&1

b_java:
	javac java.java >/dev/null 2>&1

b_scala:
	scalac -opt:_ scala.sc >/dev/null 2>&1

b_rust:
	cd rust && cargo build --release >/dev/null 2>&1 && cp target/release/rust ../rustx

b_scm:
	echo '(compile-file "scheme.scm")' | scheme >/dev/null 2>&1

b_ctr:
	ctrc ctr.ctr ctrx -O >/dev/null 2>&1
	ctrc ctr.ctr ctru >/dev/null 2>&1

c_scm:
	echo "Scheme check"
	zsh -c "{time scheme --optimize-level 3 --script scheme.so >/dev/null 2>&3} 3>&2 2>>results"

c_cxx:
	echo "C++ check"
	zsh -c "{time ./a.out > /dev/null 2>&3} 3>&2 2>>results"

c_hask:
	echo "Haskell check"
	zsh -c "{time ./hask > /dev/null 2>&3} 3>&2 2>>results"

c_go:
	echo "Golang check"
	zsh -c "{time ./go > /dev/null 2>&3} 3>&2 2>>results"

c_java:
	echo "Java check"
	zsh -c "{time java F4 > /dev/null 2>&3} 3>&2 2>>results"

c_rust:
	echo "Rust check"
	zsh -c "{time ./rustx > /dev/null 2>&3} 3>&2 2>>results"

c_ctr_n:
	echo "Citron jit check"
	zsh -c "{time ctr ./ctr.ctr > /dev/null 2>&3} 3>&2 2>>results"

c_ctr_c:
	echo "Citron compiled (opt) check"
	zsh -c "{time ./ctrx > /dev/null 2>&3} 3>&2 2>>results"
	echo "Citron compiled (unopt) check"
	zsh -c "{time ./ctru > /dev/null 2>&3} 3>&2 2>>results"
c_py:
	echo "Python check"
	zsh -c "{time python python.py > /dev/null 2>&3} 3>&2 2>>results"

c_rb:
	echo "Ruby check"
	zsh -c "{time ruby ruby.rb > /dev/null 2>&3} 3>&2 2>>results"

c_js:
	echo "Nodejs check"
	zsh -c "{time node js/js.js > /dev/null 2>&3} 3>&2 2>>results"

c_scala:
	echo "Scala check"
	zsh -c "{time scala Main > /dev/null 2>&3} 3>&2 2>>results"
