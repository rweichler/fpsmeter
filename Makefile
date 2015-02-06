DYLIB=FPSMeter.dylib
PLIST=FPSMeter.plist
MS=/Library/MobileSubstrate/DynamicLibraries

IP=5s

FRAMEWORKS=include/libsubstrate.dylib -framework IOMobileFramebuffer -framework Foundation -framework CoreGraphics -framework CoreSurface -framework CoreText -framework IOSurface

include base.mk
CFLAGS+=-Wno-unused-function
all: $(DYLIB)
clean:
	rm -f tweak.o $(DYLIB)

$(DYLIB): tweak.o
	@echo linking $@...
	@$(CC) -dynamiclib -o $@ $^ $(FRAMEWORKS)

install: $(DYLIB)
ifeq ("i386", "$(shell uname -p)")
	@echo copying to $(IP)...
	@scp $(DYLIB) $(IP):$(MS)/
	@scp $(PLIST) $(IP):$(MS)
	@echo ...done.
	ssh $(IP) "killall backboardd"
else
	cp $(DYLIB) $(MS)
	cp $(PLIST) $(MS)
	killall backboardd
endif

uninstall:
ifeq ("i386", "$(shell uname -p)")
	ssh $(IP) "rm -f $(MS)/$(DYLIB) $(MS)/$(PLIST) && killall backboardd"
else
	rm -f $(MS)/$(DYLIB) $(MS)/$(PLIST)
	killall backboardd
endif

tweak.o: tweak.m
