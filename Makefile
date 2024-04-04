forcetest:
	go clean -testcache
	HISHTORY_TEST=1 go test -cover -p 1 -timeout 30m ./...

test:
	HISHTORY_TEST=1 go test -cover -p 1 -timeout 30m ./...

acttest:
	act push -j test -e .github/push_event.json --reuse --container-architecture linux/amd64

release:
	# Bump the version
	expr `cat VERSION` + 1 > VERSION
	git add VERSION
	git commit -m "Release v0.`cat VERSION`" --no-verify
	git push 
	gh release create v0.`cat VERSION` --generate-notes
	git push && git push --tags

build-static:
	docker build -t gcr.io/dworken-k8s/hishtory-static -f backend/web/caddy/Dockerfile .

build-api:
	docker build -t gcr.io/dworken-k8s/hishtory-api -f backend/server/Dockerfile . 

deploy-static: build-static
	docker push gcr.io/dworken-k8s/hishtory-static

deploy-api: build-api
	docker push gcr.io/dworken-k8s/hishtory-api
	ssh monoserver "cd ~/infra/ && docker compose pull hishtory-api && docker compose up -d --no-deps hishtory-api"

deploy: release deploy-static deploy-api

