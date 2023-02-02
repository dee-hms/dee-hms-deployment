# dee-hms-deployment
Repository to collect Disk Encryption Experience (DEE) Host Management Service (HMS) backend deployment. The current status of this code is beta, as this is intended to show a Proof of Concept about how NBDE works in ConsoleDOT environment

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
