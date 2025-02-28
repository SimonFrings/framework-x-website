build:
	mkdir -p build/src/
	test -d source/ || $(MAKE) pull
	php -r 'file_put_contents("source/mkdocs.yml",preg_replace("/(theme:)(\n +)(?:custom_dir: .*?\n +)?/","$$1$$2custom_dir: overrides/$$2",file_get_contents("source/mkdocs.yml")));'
	mkdir -p source/overrides
	cp overrides/* source/overrides/
	docker run --rm -i -v ${PWD}/source:/docs -u $(shell id -u) squidfunk/mkdocs-material build
	cp -r source/build/docs/ build/
	cp .htaccess index.html build/
	cp src/* build/src/

pull:
	test -d source/ && git -C source/ pull || git clone git@github.com:clue-access/framework-x.git source/

serve: build
	docker run -it --rm -p 8080:80 -v "$$PWD"/build:/usr/local/apache2/htdocs/ httpd:2.4-alpine sh -c \
	  "echo 'LoadModule rewrite_module modules/mod_rewrite.so' >> conf/httpd.conf;sed -i 's/AllowOverride None/AllowOverride All/' conf/httpd.conf;httpd -DFOREGROUND"

served: build
	docker run -d --rm -p 8080:80 -v "$$PWD"/build:/usr/local/apache2/htdocs/ httpd:2.4-alpine sh -c \
	  "echo 'LoadModule rewrite_module modules/mod_rewrite.so' >> conf/httpd.conf;sed -i 's/AllowOverride None/AllowOverride All/' conf/httpd.conf;httpd -DFOREGROUND"
	@sleep 2
	@echo Container running. Use \"docker rm -f {containerId}\" to stop container.

test:
	bash tests/acceptance.sh

deploy:
	git -C build/ init
	git -C build/ checkout live 2>/dev/null || git -C build/ checkout -b live
	git -C build/ add --all
	git -C build/ diff-index HEAD >/dev/null 2>/dev/null || git -C build/ commit -m "Website build"
	git -C build/ remote get-url origin >/dev/null 2>/dev/null || git -C build/ remote add origin $(shell git remote get-url origin)
	git -C build/ push origin live -f

clean:
	rm -rf source/ build/

.PHONY: build pull serve served test deploy clean
