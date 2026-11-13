
FILE ?= comm
CMP_FLAGS ?= -gnat2022
BUILD ?= build

.PHONY: all run clean

all:
	mkdir -p $(BUILD)
	gnatmake $(CMP_FLAGS) -D $(BUILD) -o $(BUILD)/$(FILE) $(FILE).adb

run: all
	cd $(BUILD) && ./$(FILE)

clean:
	rm -rf $(BUILD)
