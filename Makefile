
VERSION = $(TRAVIS_BUILD_ID)
ME = $(USER)
HOST = bioatlas.se
TS := $(shell date '+%Y_%m_%d_%H_%M')

URL_NAMEIDX = https://s3.amazonaws.com/ala-nameindexes/20140610
URL_COL = $(URL_NAMEIDX)/col_namematching.tgz
URL_ALA = $(URL_NAMEIDX)/namematching.tgz
URL_MRG = $(URL_NAMEIDX)/merge_namematching.tgz
URL_SDS = http://biocache.ala.org.au/archives/layers/sds-layers.tgz
URL_COLLECTORY = https://github.com/bioatlas/ala-collectory/releases/download/1.4.5/ala-collectory-1.4.5.war
URL_NAMESDIST = http://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/ala-name-matching/2.3.1/ala-name-matching-2.3.1-distribution.zip
URL_BIOCACHE_SERVICE = http://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/biocache-service/1.9/biocache-service-1.9.war
URL_BIOCACHE_HUB = https://github.com/bioatlas/ala-hub/releases/download/2.3/ala-hub-2.3.war
URL_BIOCACHE_CLI = http://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/biocache-store/1.8.0/biocache-store-1.8.0-distribution.zip
URL_LOGGER_SERVICE = http://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/logger-service/2.3.5/logger-service-2.3.5.war
URL_IMAGE_SERVICE = https://github.com/bioatlas/image-service/releases/download/v0.7.2/ala-images.war
URL_API = https://github.com/bioatlas/webapi/releases/download/v0.2/webapi-1.1-SNAPSHOT.war
URL_DASHBOARD = http://nexus.ala.org.au/service/local/repositories/releases/content/au/org/ala/dashboard/1.0/dashboard-1.0.war
URL_GBIF_BACKBONE = http://rs.gbif.org/datasets/backbone/2017-02-13/backbone.zip
URL_BIOATLAS_WORDPRESS_THEME = https://github.com/bioatlas/bioatlas-wordpress-theme/archive/master.zip

all: init build up
.PHONY: all

init:
	@echo "Caching files required for the build..."

	@curl --progress -L -s -o wait-for-it.sh \
		https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
		chmod +x wait-for-it.sh

	@test -f cassandra/wait-for-it.sh || \
		cp wait-for-it.sh cassandra/

	@test -f collectory/collectory.war || \
		wget -q --show-progress -O collectory/collectory.war $(URL_COLLECTORY)

	@test -f nameindex/namematching.tgz || \
		curl --progress -o nameindex/namematching.tgz $(URL_COL)

	@test -f nameindex/nameindexer.zip || \
		curl --progress -o nameindex/nameindexer.zip $(URL_NAMESDIST)

	@test -f nameindex/dwca-col.zip || \
		curl --progress -o nameindex/dwca-col.zip $(URL_NAMEIDX)/dwca-col.zip

	@test -f nameindex/dwca-col-mammals.zip || \
		curl --progress -o nameindex/dwca-col-mammals.zip $(URL_NAMEIDX)/dwca-col-mammals.zip

	@test -f nameindex/IRMNG_DWC_HOMONYMS.zip || \
		curl --progress -o nameindex/IRMNG_DWC_HOMONYMS.zip $(URL_NAMEIDX)/IRMNG_DWC_HOMONYMS.zip

	@test -f nameindex/col_vernacular.txt.zip || \
		curl --progress -o nameindex/col_vernacular.txt.zip $(URL_NAMEIDX)/col_vernacular.txt.zip

	#@test -f nameindex/backbone.zip || \
	#	curl --progress -o nameindex/backbone.zip $(URL_GBIF_BACKBONE)

	@test -f biocachebackend/biocache-properties-files/sds-layers.tgz || \
		curl --progress --create-dirs -o biocachebackend/biocache-properties-files/sds-layers.tgz $(URL_SDS)

	@test -f biocacheservice/biocache-service.war || \
		curl --progress -o biocacheservice/biocache-service.war $(URL_BIOCACHE_SERVICE)

	@test -f biocachehub/generic-hub.war || \
		wget -q --show-progress -O biocachehub/generic-hub.war $(URL_BIOCACHE_HUB)

	@test -f biocachebackend/biocache.zip || \
		curl --progress -o biocachebackend/biocache.zip $(URL_BIOCACHE_CLI)

	@test -f loggerservice/logger-service.war || \
		curl --progress -o loggerservice/logger-service.war $(URL_LOGGER_SERVICE)

	@test -f imageservice/images.war || \
		wget -q --show-progress -O imageservice/images.war $(URL_IMAGE_SERVICE)

	@test -f api/api.war || \
		wget -q --show-progress -O api/api.war $(URL_API)

	@test -f dashboard/dashboard.war || \
		curl --progress -o dashboard/dashboard.war $(URL_DASHBOARD)

theme-dl:
	@echo "Downloading bioatlas wordpress theme..."
	@test -f wordpress/themes/atlas/master.zip || \
		mkdir -p wordpress/themes/atlas && \
		wget -q --show-progress -O wordpress/themes/atlas/master.zip $(URL_BIOATLAS_WORDPRESS_THEME) && \
		unzip -q -o wordpress/themes/atlas/master.zip -d wordpress/themes/atlas/

secrets:
	#echo "# Make this unique, and don't share it with anybody.\n# This value was autogenerated." > $@
	#rm -f secrets env/{.envapi,.envcollectory,.envimage,.envlogger}
	printf "export SECRET_MYSQL_ROOT_PASSWORD=%b\n" \
		$$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50) >> $@
	printf "export SECRET_MYSQL_PASSWORD=%b\n" \
		$$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50) >> $@
	printf "export SECRET_POSTGRES_PASSWORD=%b\n" \
		$$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50) >> $@
	printf "export SECRET_MIRROREUM_PASSWORD=%b\n" \
		$$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50) >> $@
	printf "export SECRET_UPTIME_PASSWORD=%b\n" \
		$$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50) >> $@

dotfiles: secrets
	bash -c ". secrets && envsubst < env/envapi.template > env/.envapi"
	bash -c ". secrets && envsubst < env/envcollectory.template > env/.envcollectory"
	bash -c ". secrets && envsubst < env/envimage.template > env/.envimage"
	bash -c ". secrets && envsubst < env/envlogger.template > env/.envlogger"
	bash -c ". secrets && envsubst < env/envmirroreum.template > env/.envmirroreum"
	bash -c ". secrets && envsubst < env/envuptime.template > env/.envuptime"
	bash -c ". secrets && envsubst < env/envwordpress.template > env/.envwordpress"
	rm -f secrets

htpasswd:
	#bash -c "htpasswd -bn admin passw0rd12 > env/.htpasswd"
	bash -c "htpasswd -n admin > env/.htpasswd"

build:
	@echo "Building images..."
	@docker build -t bioatlas/ala-solrindex:v0.1 solr4
	@docker build -t bioatlas/ala-biocachebackend:v0.1 biocachebackend
	@docker build -t bioatlas/ala-nameindex:v0.1 nameindex
	@docker build -t bioatlas/ala-nginx:v0.1 nginx
	@docker build -t bioatlas/ala-biocachehub:v0.1 biocachehub
	@docker build -t bioatlas/ala-collectory:v0.1 collectory
	@docker build -t bioatlas/ala-biocacheservice:v0.1 biocacheservice
	@docker build -t bioatlas/ala-cassandra:v0.1 cassandra
	@docker build -t bioatlas/ala-mongo:v0.1 mongo
	@docker build -t bioatlas/ala-loggerservice:v0.1 loggerservice
	@docker build -t bioatlas/ala-imageservice:v0.1 imageservice
	@docker build -t bioatlas/ala-imagestore:v0.1 imagestore
	@docker build -t bioatlas/ala-api:v0.1 api
	@docker build -t bioatlas/ala-dashboard:v0.1 dashboard

up:
	@echo "Starting services..."
	@docker-compose up -d

up-dev:
	@echo "Starting services in development mode..."
	@docker-compose -f docker-compose-dev.yml up -d

test:
	@echo "run cd ghost && rm -rf content && make content first to populate front page with content"
	@echo "Opening up front page... use the bigmac/hamburger menu at the front page to get the toolbar for testing all services.."
	./wait-for-it.sh bioatlas.se:80 -q -- xdg-open http://bioatlas.se/ &

test-solr:
	@curl -L -s bioatlas.se/solr/admin/cores?status > solr.xml && \
		firefox solr.xml

test-cas:
	@echo "Listing keyspaces in cassandra:"
	@docker exec -it cassandradb sh -c \
		'echo "DESC KEYSPACES;" | cqlsh'

test-uptime:
	#TODO: update to use dotfiles
	#@curl -L admin:password@uptime.bioatlas.se
	#@xdg-open http://admin:password@uptime.bioatlas.se

stop:
	@echo "Stopping services..."
	@docker-compose stop

push:
	@docker push bioatlas/ala-solrindex:v0.1
	@docker push bioatlas/ala-biocachebackend:v0.1
	@docker push bioatlas/ala-nameindex:v0.1
	@docker push bioatlas/ala-nginx:v0.1
	@docker push bioatlas/ala-biocachehub:v0.1
	@docker push bioatlas/ala-collectory:v0.1
	@docker push bioatlas/ala-biocacheservice:v0.1
	@docker push bioatlas/ala-cassandra:v0.1
	@docker push bioatlas/ala-mongo:v0.1
	@docker push bioatlas/ala-loggerservice:v0.1
	@docker push bioatlas/ala-imageservice:v0.1
	@docker push bioatlas/ala-imagestore:v0.1
	@docker push bioatlas/ala-api:v0.1
	@docker push bioatlas/ala-dashboard:v0.1

release: build push
