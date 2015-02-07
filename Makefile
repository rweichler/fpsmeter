DYLIB=FPSMeter.dylib
PLIST=FPSMeter.plist
MS=/Library/MobileSubstrate/DynamicLibraries

IP=5s

FRAMEWORKS=include/libsubstrate.dylib -framework IOMobileFramebuffer -framework Foundation -framework CoreGraphics -framework CoreSurface -framework CoreText -framework IOSurface

CMD=a.out

BINARIES=$(DYLIB) $(CMD)

include base.mk
CFLAGS+=-Wno-unused-function
all: $(BINARIES)
clean:
	rm -f tweak.o main.o $(BINARIES)

$(DYLIB): tweak.o
	@echo linking $@...
	@$(CC) -dynamiclib -o $@ $^ $(FRAMEWORKS)

$(CMD): main.o
	@echo linking $@...
	@$(CC) -o $@ $^ -framework QuartzCore

install: $(DYLIB)
ifeq ("i386", "$(shell uname -p)")
	@echo copying to $(IP)...
	@scp $(DYLIB) $(IP):$(MS)/
	@scp $(PLIST) $(IP):$(MS)
	@scp $(CMD) $(IP):.
	@echo ...done.
else
	cp $(DYLIB) $(MS)
	cp $(PLIST) $(MS)
endif

uninstall:
ifeq ("i386", "$(shell uname -p)")
	ssh $(IP) "rm -f $(MS)/$(DYLIB) $(MS)/$(PLIST)"
else
	rm -f $(MS)/$(DYLIB) $(MS)/$(PLIST)
endif

respring:
ifeq ("i386", "$(shell uname -p)")
	ssh $(IP) "killall backboardd"
else
	killall backboardd
endif

tweak.o: tweak.m
main.o: main.c
