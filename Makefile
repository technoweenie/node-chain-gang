test: coffee-dep
	@find test -name '*_test.coffee' | xargs -n 1 -t coffee

dev: generate-js
	@coffee -wc --bare -o lib src/

VERSION = $(shell cat package.json | grep '"version"' | sed 's/.*"version":.*"\(.*\)"/\1/')
publish: npm-dep generate-js
	git commit --allow-empty -a -m "release $(VERSION)"
	git tag v$(VERSION)
	git push origin master
	git push origin v$(VERSION)
	npm publish
	@make remove-js

install: npm-dep generate-js
	npm install
	@make remove-js

generate-js: coffee-dep
	@coffee -c --bare -o lib src/

remove-js:
	@rm -fr lib/

npm-dep:
	@test `which npm` || echo 'You need npm to do npm install... makes sense?'

coffee-dep:
	@test `which coffee` || echo 'You need to have CoffeeScript in your PATH.\nPlease install it using `brew install coffee-script` or `npm install coffee-script`.'

.PHONY: all
