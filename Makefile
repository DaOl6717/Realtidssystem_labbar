FILE ?= cyclic_scheduler

.PHONY: all run

all:
	gnatmake $(FILE).adb
	gcc -c $(FILE).adb
	gnatbind -x $(FILE).ali
	gnatlink $(FILE).ali
	
	gnatmake $(FILE).adb

run: all
	./$(FILE)

make:
	gnatmake hello_world.adb
	gcc -c hello_world.adb
	gnatbind -x hello_world.ali
	gnatlink hello_world.ali