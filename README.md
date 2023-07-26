# dee-hms-deployment

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Status

[![shellcheck](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/shellcheck.yaml/badge.svg)](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/shellcheck.yaml)\
[![spellcheck](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/dee-hms/dee-hms-deployment/actions/workflows/spellcheck.yaml)

## Introduction
Repository to collect Disk Encryption Experience (DEE) Host Management Service (HMS) backend deployment. The current status of this code is beta, as this is intended to show a Proof of Concept about how NBDE works in ConsoleDOT environment.

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
