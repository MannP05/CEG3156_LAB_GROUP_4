OBJ_DIR = obj
ENTITY_DIR = entities
OUTPUT_DIR = output
TESTBENCH_DIR = tb
ENTITY_NAME = tb_register_file
TEST_NAME = $(ENTITY_NAME)

# Source files - packages first, then everything else
VHDL_PACKAGES = $(wildcard *_package.vhd)
EXCLUDE_SOURCES = data_memory.vhd instruction_memory.vhd
VHDL_SOURCES = $(filter-out $(VHDL_PACKAGES) $(EXCLUDE_SOURCES), $(wildcard *.vhd))

# Testbench Logic
ALL_TB_SOURCES = $(wildcard $(TESTBENCH_DIR)/*.vhd)
ALL_TB_ENTITIES = $(basename $(notdir $(ALL_TB_SOURCES)))

TESTBENCHES = $(TESTBENCH_DIR)/$(TEST_NAME).vhd
TOP_ENTITY = $(TEST_NAME)

all: run

# 1. Create Directories
init:
	mkdir -p $(OBJ_DIR) $(ENTITY_DIR) $(OUTPUT_DIR)

# 2. Analyze (Compile)
analyze: init
	@echo "--- Analyzing Packages ---"
	ghdl -a -fsynopsys --workdir=$(OBJ_DIR) $(VHDL_PACKAGES)
	@echo "--- Analyzing Core Sources ---"
	ghdl -a -fsynopsys --workdir=$(OBJ_DIR) $(VHDL_SOURCES)
	@echo "--- Analyzing Testbenches ---"
	ghdl -a -fsynopsys --workdir=$(OBJ_DIR) $(ALL_TB_SOURCES) || true

# 3. Run Specific Test (make run)
elaborate: analyze
	(cd $(OBJ_DIR) && ghdl -e -fsynopsys $(TOP_ENTITY))

run: elaborate
	(cd $(OBJ_DIR) && ghdl -r -fsynopsys $(TOP_ENTITY) --vcd=../$(OUTPUT_DIR)/$(ENTITY_NAME).vcd --stop-time=100ms)

# 4. Run ALL Tests (make run_all)
run_all: analyze
	@echo "============================================="
	@echo "       RUNNING ALL TESTBENCHES"
	@echo "============================================="
	@for tb in $(ALL_TB_ENTITIES); do \
		echo "---------------------------------------------"; \
		echo "Target: $$tb"; \
		if (cd $(OBJ_DIR) && ghdl -e -fsynopsys $$tb); then \
			echo " [OK] Running simulation..."; \
			(cd $(OBJ_DIR) && ghdl -r -fsynopsys $$tb --vcd=../$(OUTPUT_DIR)/$$tb.vcd --stop-time=100ms) || true; \
		else \
			echo " [ERROR] Elaboration failed (see above)"; \
		fi; \
	done
	@echo "---------------------------------------------"
	@echo "All tests finished."

view:
	gtkwave $(OUTPUT_DIR)/$(ENTITY_NAME).vcd &

surfer:
	surfer $(OUTPUT_DIR)/$(ENTITY_NAME).vcd &

clean:
	ghdl --clean --workdir=$(OBJ_DIR)
	rm -rf $(ENTITY_DIR)/* $(OUTPUT_DIR)/*