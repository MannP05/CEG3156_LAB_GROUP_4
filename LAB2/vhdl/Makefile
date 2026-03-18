# List of all files in the project
DEPS = *.vhdl *.vhd

# Entrypoint entity, which is what gets run
E_ENTITY = register_file_sim

# Compiler path
GHDL = ghdl

# Compiler flags
C_FLAGS = -fsynopsys

# Wave file (open with something like gtkwave)
WAVE_F = wave.vcd

# Additional runtime flags
R_FLAGS =

default: clean
	@$(GHDL) -i $(C_FLAGS) $(DEPS)
	@$(GHDL) -m $(C_FLAGS) $(E_ENTITY)
	@$(GHDL) -r $(C_FLAGS) $(E_ENTITY) --stop-time=4us --vcd=$(WAVE_F) $(R_FLAGS)

clean:
	@rm -f $(WAVE_F)
	@rm -f work-obj*.cf
	@rm -f *.o $(E_ENTITY) e~*