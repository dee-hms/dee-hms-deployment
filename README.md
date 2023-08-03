# dee-hms-deployment

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Status

[![shellcheck](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/shellcheck.yaml/badge.svg)](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/shellcheck.yaml)\
[![spellcheck](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/spellcheck.yaml)

## Introduction
Repository to collect Disk Encryption Experience (DEE) Host Management Service (HMS) backend deployment.
The current status of the code is beta, as this is intended to show a Proof of Concept (PoC) about how NBDE works in ConsoleDOT environment.

## Deployment
Content of this repository can be deployed through [bonfire](https://github.com/RedHatInsights/bonfire) and Ephemeral Environments.

In particular, to deploy this application, you can:

1. Create a file under ~/.config/bonfire/config.yaml
2. Include, in previous file, next configuration:
```bash
# Bonfire deployment configuration
apps:
- name: tang
  components:
    - name: service
      host: github
      repo: dee-hms/dee-hms-deployment
      path: deploy/clowdapp.yaml
```
3. Deploy previous configuration with next command:
```bash
bonfire deploy --source=local tang
```

## Tools
Apart from deployment configuration files, this repository holds some useful tools that allow automating some of the tasks required for the PoC

### v3_deployment_config
[v3_deployment_config](https://github.com/dee-hms/dee-hms-deployment/blob/main/tools/v3_deployment/v3_deployment_config.sh) tool allows deploying some of the
required information to tang-proxy / socat-tang-filter tools. It parses a CSV file, and configures:

* tang proxy database
* socat tang filter configuration file

Usage of the tool is as follows:

```bash
$ ./tools/v3_deployment/v3_deployment_config.sh -h

./tools/v3_deployment/v3_deployment_config.sh -c <configFile> -d <dbHost:dbUser:dbPassword> [-t tangPodname (will be guessed if not provided)] [-k k8sClient (oc by default)] [-h] [-v]
```
Mandatory parameters are:\
-c `configFile`: CSV configuration file. An example is shown [here](https://github.com/dee-hms/dee-hms-deployment/blob/main/tools/v3_deployment/v3_deployment_config.csv)\
-d `databaseInfo`: This parameter will hold the database configuration (host, user, password). An example: localhost:root:redhat123

Optional parameters are:\
-t `tangPodname`: The name of the Tang pod where to configure. If not provided, this script will try to guess it, searching for pods starting with `tang-backend` prefix\
-k `k8sClient`: This parameter allows providing the K8S/OpenShift client to use. If not provided, this script will use `oc` by default\
-v: To execute in verbose mode\
-h: To show command help

An example on how to execute the tool could be next:
```bash
$ ./tools/v3_deployment/v3_deployment_config.sh -c ./tools/v3_deployment/v3_deployment_config.csv -d localhost:root:user
```

An example on how to execute the tool in verbose mode could be next:
```bash
$ ./tools/v3_deployment/v3_deployment_config.sh -c ./tools/v3_deployment/v3_deployment_config.csv -d localhost:root:user -v
---------------------------------------------------------
configuration_file:[./tools/v3_deployment/v3_deployment_config.csv]
dbhost_user_password:[localhost:root:redhat123]
dbhost:localhost
dbuser:root
dbpassword:redhat123
tang_podname:
---------------------------------------------------------
```
