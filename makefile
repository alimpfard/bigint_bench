

define run_single_test
	echo "[$$(date)] $(1) started"
	( /usr/bin/time -f "$(1) %M" zsh -c "{time $(2) >/dev/null 2>&3} 3>&2 2>>results" ) 2>&1 | tr \' '"' | tee -a mem_results
	echo "[$$(date)] $(1) finished"
endef


all: clean build_buildables check format_results sort_results generate_gnuplot

quick: clean build_buildables check_fast format_results sort_results generate_gnuplot

clean:
	rm -f hask hask.hi hask.o a.out go *.class rustx rust/target/release/rust ctr
	mv results results.last || true
	mv mem_results mem_results.last || true

build_buildables: b_cxx b_hask b_go b_java b_scala b_rust b_scm b_ctr

check: c_cxx c_hask c_go c_java c_scala c_rust c_ctr_n c_ctr_c c_py c_rb c_scm c_js

check_fast: c_cxx c_hask c_go c_java c_scala c_rust c_ctr_n c_ctr_c c_py c_rb

define gnuplot
	gnuplot -e 'set term pngcairo size 1200,800; set output "plot.png"; set boxwidth 0.2; set style fill solid; set y2tics; set y2label "Memory Usage (MB)"; set title "Runtime; calc/print of 500000!"; set xtic rotate by 45 right; set ylabel "seconds"; plot "mem_results" using ($$2/1024) axes x1y2 lc rgb "red" with histogram title "memory", "data.dat" using 3:xtic(2) with boxes title "runtime", "data.dat" using 1:($$3+10):3 with labels font "Helvetica,10" offset 0,-1 notitle'
endef

generate_gnuplot:
	cat results | sed -e 's/( /(/g' | awk -e '{print NR-1, "\"", $$1, "\"", substr($$5, 0,length($$5)-1)}' > data.dat.u
	./transl.sh data.dat.u > data.dat
	$(call gnuplot)

generate_gnuplot_no_node:
	cat results | sed -e 's/( /(/g' | awk -e '{print NR, "\"", $$1, "\"", substr($$5, 0,length($$5)-1)}' > data.dat.u
	sed -i -e '/node/d' data.dat.u
	./transl.sh data.dat.u > data.dat
	$(call gnuplot)

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
	ctrc ctr.ctr ctrh -O --heap-size=512M >/dev/null 2>&1
	ctrc ctr.ctr ctru >/dev/null 2>&1

c_scm:
	$(call run_single_test,Scheme,scheme --optimize-level 3 --script scheme.so)

c_cxx:
	$(call run_single_test,C++,./a.out)

c_hask:
	$(call run_single_test,Haskell,./hask)
	
c_go:
	$(call run_single_test,Go,./go)

c_java:
	$(call run_single_test,Java,java F4)

c_rust:
	$(call run_single_test,Rust,./rustx)

c_ctr_n:
	$(call run_single_test,'Citron (JIT)',ctr ctr.ctr)

c_ctr_c:
	$(call run_single_test,'Citron (Unopt)',./ctru)
	$(call run_single_test,'Citron (Opt)',./ctrx)
	$(call run_single_test,'Citron (Opt,heap=512M)',./ctrh)

c_py:
	$(call run_single_test,'Python',python python.py)

c_rb:
	$(call run_single_test,'Ruby',ruby ruby.rb)

c_js:
	$(call run_single_test,'Nodejs',node js/js.js)

c_scala:
	$(call run_single_test,'Scala',scala Main)
