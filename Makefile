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

clean:
	@rebar3 clean

dialyzer:
	@rebar3 dialyzer

.PHONY: build test format doc serve clean dialyzer
