test: deps
	@find test -name '*_test.coffee' | xargs -n 1 -t coffee

dev: generate-js
	@coffee -wc --bare -o lib src/

publish: generate-js
	@test `which npm` || echo 'You need npm to do npm publish... makes sense?'
	npm publish
	@remove-js

install: generate-js
	@test `which npm` || echo 'You need npm to do npm install... makes sense?'
	npm install
	@remove-js

generate-js: deps
	@coffee -c --bare -o lib src/

deps:
	@test `which coffee` || echo 'You need to have CoffeeScript in your PATH.\nPlease install it using `brew install coffee-script` or `npm install coffee-script`.'

.PHONY: all
