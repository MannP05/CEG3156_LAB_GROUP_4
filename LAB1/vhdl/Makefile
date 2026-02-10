# GHDL Docs
# https://ghdl.github.io/ghdl/index.html

# List of all files in DEPENDENCY ORDER (Bottom-Up)
# 1. Base components (Adders, FFs, Mux parts)
# 2. Middle components (Registers, ALUs)
# 3. Top Level components (Control, fpAdd)
# 4. Testbench
DEPS = \
	oneBitAdder.vhd \
	enARdFF_2.vhd \
	quad_n_mux_selector.vhdl \
	onebitcomparator.vhdl \
	mux_2x1.vhdl \
	mux_2x1_16bit.vhdl \
	ripple_adder.vhdl \
	nbit_register.vhdl \
	bidirectional_shifter.vhdl \
	smallALU.vhdl \
	bigALU.vhdl \
	controlUnit.vhdl \
	fpAdd.vhdl \
	fpAdd_sim.vhdl \
	controlUnit_Mult.vhdl \
	fpMult.vhdl \
	fpMult_sim.vhdl \


# Entrypoint entity
E_ENTITY = fpMult_sim
# Compiler path
GHDL = ghdl
# Compiler flags (using 2008 standard handles some syntax better)
C_FLAGS = --std=08
# Wave file
WAVE_F = wave.vcd

default:
	@echo "--- cleaning old build artifacts ---"
	@rm -f work-obj93.cf
	@echo "--- analyzing files ---"
	@$(GHDL) -a $(C_FLAGS) $(DEPS) 
	@echo "--- elaborating ---"
	@$(GHDL) -e $(C_FLAGS) $(E_ENTITY)
	@echo "--- running simulation ---"
	@$(GHDL) -r $(C_FLAGS) $(E_ENTITY) --stop-time=3us --vcd=$(WAVE_F)

clean:
	@rm -f $(WAVE_F)
	@rm -f work-obj93.cf