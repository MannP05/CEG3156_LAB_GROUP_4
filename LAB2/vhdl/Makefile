
# GHDL Docs
# https://ghdl.github.io/ghdl/index.html

# List of all files in the project
DEPS = *.vhdl 
# Entrypoint entity, which is what gets run
E_ENTITY = control_unit_sim
# Compiler path
GHDL = ghdl
# Compiler flags
C_FLAGS = -fsynopsys
# Wave file (open with something like gtkwave)
WAVE_F = wave.vcd
# Addotional runtime lags
R_FLAGS = 

default:
	@$(GHDL)  -a $(C_FLAGS) $(DEPS) # Analyzing the files
	@$(GHDL)  -e $(C_FLAGS) $(E_ENTITY)  # elaborate the entrypoint entity
	@$(GHDL)  -r $(C_FLAGS) $(E_ENTITY) --stop-time=4us --vcd=$(WAVE_F) $(R_FLAGS) # run the entity 

clean:
	@rm -f $(WAVE_F)
	@rm -f work-obj*.cf
