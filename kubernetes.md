# Prodfiler agent Kubernetes deployment

The agent is deployed as a DaemonSet and requires a `privileged` security context as it needs access to the nodes' kernel features.

## Quick start installation

* Create a namespace to host Prodfiler (and optionally label it), here we use `prodfiler`:
  ```bash
  kubectl create ns prodfiler
  kubectl label ns prodfiler app=pf-host-agent provider=optimyze
  ```

* Add the Helm repository hosting the Optimyze charts, you only need to run this when first installing:
  ```bash
  helm repo add optimyze-prodfiler s3://optimyze-prodfiler-deployment/charts/pf-host-agent
  ```

* Fetch the `projectID` and `secretToken` values visible in the Prodfiler web UI
  when creating a new project.
  The values are defined as environment variables in the "manual deployment" command, 
  they are called `PRODFILER_PROJECT_ID` and `PRODFILER_SECRET_TOKEN` respectively.
  
  Use the values in the following command, replacing the placeholders:

  ```bash
  helm install --namespace=prodfiler pf-host-agent \
  --set "projectID=<projectID>,secretToken=<secretToken>" \
  optimyze-prodfiler/pf-host-agent
  ```

## Customizing values

For more complex deployment you may want to customize Helm values.
You can list the possible values using:

```bash
helm show values optimyze-prodfiler/pf-host-agent
```

The most notable configuration knobs are `nodeSelector` and `tolerations` to deploy Prodfiler Host Agent
only to a subset of nodes in your cluster.
