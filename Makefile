_TEST_PROJECT = myproject
CURRENT_DIR = $(shell pwd)
OC_CMD = oc

build-native:
	mvn clean package -f quarkus-front/pom.xml -Pnative -Dnative-image.docker-build=true
	cd quarkus-front; docker build -f src/main/docker/Dockerfile.native -t slaskawi/quarkus-front .

push-dockerhub:
	docker push slaskawi/quarkus-front

deploy-keycloak: create-project
	$(OC_CMD) new-app -p NAMESPACE=$(_TEST_PROJECT) -p KEYCLOAK_USER=admin -p KEYCLOAK_PASSWORD=admin -f keycloak-https.json

deploy-front:
	$(OC_CMD) new-app --docker-image=slaskawi/quarkus-front
	$(OC_CMD) import-image quarkus-front --confirm
	$(OC_CMD) expose svc/quarkus-front

deploy-oauth-client:
	$(OC_CMD) create -f oauth-client.json

create-project:
	$(OC_CMD) new-project myproject || true

clean-keycloak:
	$(OC_CMD) delete all -l app=keycloak-https

clean-quarkus-front:
	$(OC_CMD) delete all -l app=quarkus-front

keycloak-logs:
	docker logs -f $(KEYCLOAK_ID)

print-summary:
	@echo "Keycloak: 			http://localhost:8080"
	@echo "Front:			 	http://localhost:8081"
	@echo "Username service: 		http://localhost:8082"
	@echo "CAPS service: 			http://localhost:8083"
	@echo ""
	@echo "Examples:"
	@echo "- export token: export TOKEN="
	@echo "- username uppercase: curl -H \"Authorization: Bearer \$$TOKEN\" http://localhost:8083/caps/test"
	@echo "- credentials grant: curl -s -v --data \"client_id=quarkus-front&username=test&password=test&grant_type=password\" http://localhost:8080/auth/realms/quarkus-quickstart/protocol/openid-connect/token | jq"