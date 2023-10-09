# Run all test files
.PHONY: test
test:
	nvim --headless --noplugin -u ./scripts/mini_test_init.lua -c "lua MiniTest.run()"

# Format code
.PHONY: format
format:
	stylua .
	alejandra .
