# Migration for cfcr to 

### Usage
  prerequest: codefresh-cli, docker + docker login to dest registry  

```
  migrate-from-cfcr.sh <to-registry repo prefix> [ codefresh get images agruments ]
```
  Example:  
  `migrate-from-cfcr.sh gcr.io/codefresh-inc --image-name codefresh/cf-api --limit 10000`

### Features
* Pushed images are recorded in `done/` folder and are not processed on next run
* if space or inodes usage exceeds DU_THRESHOLD it cleans by `docker images prune -a --force $IMAGES_PRUNE_FILTER`

Environments  
```
DOCKER_ROOT=${DOCKER_ROOT:-/var/lib/docker}
DU_THRESHOLD=${DU_THRESHOLD:-95}
IMAGES_PRUNE_FILTER=${IMAGES_PRUNE_FILTER:-"until=20m"}
```

### VM Setup
Start VM with Linux with big disk (at least 200G , depending on your image sizes) for /var/lib/docker  

* install docker https://docs.docker.com/install/linux/docker-ce/ubuntu/ 
* docker login for cfcr - https://codefresh.io/docs/docs/docker-registries/codefresh-registry/#generate-cfcr-login-token 
* docker login to your destination repo
* clone this repo: `git clone git@github.com:codefresh-io/cfcr-migration.git`



