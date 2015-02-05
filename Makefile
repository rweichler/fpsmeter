DYLIB=FPSMeter.dylib
PLIST=FPSMeter.plist
MS=/Library/MobileSubstrate/DynamicLibraries

FRAMEWORKS=/usr/lib/libsubstrate.dylib -framework IOMobileFramebuffer -framework Foundation -framework CoreGraphics -framework CoreSurface -framework CoreText

include base.mk
all: $(DYLIB)
clean:
	rm -f tweak.o $(DYLIB)

$(DYLIB): tweak.o
	@echo linking $@...
	@$(CC) -dynamiclib -o $@ $^ $(FRAMEWORKS) -undefined suppress -flat_namespace

install: $(DYLIB)
	cp $(DYLIB) $(MS)
	cp $(PLIST) $(MS)
	killall backboardd

uninstall:
	rm -f $(MS)/$(DYLIB) $(MS)/$(PLIST)
	killall backboardd

tweak.o: tweak.m
