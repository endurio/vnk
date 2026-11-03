APP      := VNK.app
BUILD    := build
BUNDLE   := $(BUILD)/$(APP)
DEST     := $(HOME)/Library/Input Methods
SWIFTC   := swiftc -swift-version 5
SOURCES  := Sources/TelexEngine.swift Sources/InputController.swift Sources/main.swift

.PHONY: all test install uninstall clean

all: $(BUNDLE)

$(BUNDLE): $(SOURCES) Resources/Info.plist Resources/en.lproj/InfoPlist.strings $(BUILD)/vn.tiff
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	$(SWIFTC) -O $(SOURCES) -o $(BUNDLE)/Contents/MacOS/VNK
	cp Resources/Info.plist $(BUNDLE)/Contents/
	cp -R Resources/en.lproj $(BUNDLE)/Contents/Resources/
	cp $(BUILD)/vn.tiff $(BUNDLE)/Contents/Resources/vn.tiff
	codesign --force --sign - $(BUNDLE)

$(BUILD)/vn.tiff: tools/make-icon.swift
	mkdir -p $(BUILD)
	$(SWIFTC) tools/make-icon.swift -o $(BUILD)/make-icon
	$(BUILD)/make-icon $@

$(BUILD)/register: tools/register.swift
	mkdir -p $(BUILD)
	$(SWIFTC) tools/register.swift -o $@

test:
	mkdir -p $(BUILD)
	$(SWIFTC) Sources/TelexEngine.swift tests/main.swift -o $(BUILD)/test
	$(BUILD)/test

install: $(BUNDLE) $(BUILD)/register
	mkdir -p "$(DEST)"
	-killall VNK 2>/dev/null
	rm -rf "$(DEST)/$(APP)"
	cp -R $(BUNDLE) "$(DEST)/"
	$(BUILD)/register "$(DEST)/$(APP)"

uninstall:
	-killall VNK 2>/dev/null
	rm -rf "$(DEST)/$(APP)"

clean:
	rm -rf $(BUILD)
