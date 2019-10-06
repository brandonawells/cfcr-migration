# Migration for cfcr to 

### Usage
  prerequest: codefresh-cli, docker + docker login to dest registry  

```
  migrate-from-cfcr.sh <to-registry repo prefix> [ codefresh get images agruments ]
```
  Example:  
  `migrate-from-cfcr.sh gcr.io/codefresh-inc --image-name codefresh/cf-api --limit 10000`

