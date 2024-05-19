
all: clean compile run

compile:
	vlib work
	vlog FILES.svh
run:
	vsim -c top_tb -do "run -all; quit"

clean:
	rm -rf work
	rm -rf transcript






