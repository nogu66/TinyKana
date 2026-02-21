APP_NAME = TinyKana
BUNDLE   = $(APP_NAME).app
BIN_DIR  = $(BUNDLE)/Contents/MacOS
RES_DIR  = $(BUNDLE)/Contents/Resources

.PHONY: build run clean

## .app バンドルをビルド
build:
	swift build -c release
	mkdir -p $(BIN_DIR) $(RES_DIR)
	cp .build/release/$(APP_NAME) $(BIN_DIR)/$(APP_NAME)
	cp Info.plist $(BUNDLE)/Contents/Info.plist

## ビルドして即起動
run: build
	open $(BUNDLE)

## 成果物を削除
clean:
	rm -rf .build $(BUNDLE)
