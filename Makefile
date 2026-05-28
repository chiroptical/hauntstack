EX_DOC := $(shell which ex_doc)

build:
	@rebar3 compile

test:
	@rebar3 eunit
	@rebar3 ct

format:
	@treefmt

doc:
	@rebar3 ex_doc -e $(EX_DOC)

serve: doc
	@serve doc/

.PHONY: build test format doc serve
