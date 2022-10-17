# Spin to Argo

ArgoCD allows for syncing YAML artifiacts in a git with the cluster. However, the support for updating the YAML from other build and release processes is minimal. These include, for example, updating the image, adding/updating annotations such as git-SHA or JIRA ticket number and so on. In addition, promotion of applications from one environment to the other, e.g from dev to staging to production. While it is possible to copy files, raise PRs, etc, integrating with organizational release processes such as JIRA based approval, Management approval based on test-results, etc. are rather difficult, if not impossible to achieve.

ISD, that is based on Open Source Spinnaker, allows for parameter processing and substitution, using if-then-else logic based on parameters and so on.

Here we demonstrate a simple pipeline that leverages ISD capabilites to update a YAML based on pipeline parameters. As part of the update, approvals, adding annotations, changing other parameters such as relicas and application promotion can all be achieved in a unified manner that is auditable, includes Metrics+Logs based varification and so on.

This is a demo pipeline to show the following use-cases:
1. Substitute values in a YAML
2. TODO: Promote a YAML from one repo to another (e.g. from test to prod)
3. TODO: Process all files in a directory (i.e. an application) e.g. add a JIRA-ticket number to ALL YAML annotations
4. TODO: Process and promote an application or multiple applications
5. TODO: Reference pipeline that processes and promotes using Approval Stage, JIRA integration and Verification Stage

This pipeline edits a manifest files using the "yq" command on the required files and push to the github

## steps to be followed

**1. create a new pipeline with pipeline json**
In ISD, go to sampleapp, new pipeline, edit as json, copy paste the spin2argo.json file, save

**2. Create a secret for github**
 -  Github Username and token or SSH key is required for updading the git reposotory. A kubernetes secret needs to be created
 -  To use SSH key, issue the following command with these replaced: USERNAME, NAMESPACE, PRIVATE_KEY_FILE 
    -  `kubectl create secret generic git-secret-spingit --from-literal=git_user=USERNAME  -n NAMESPACE --from-file=GIT_SSH_KEY=PRIVATE_KEY_FILE `
 -  To use git token (not recommended). issue the following command with these replaced: USERNAME, NAMESPACE, TOKEN 
    -  `kubectl create secret generic git-secret-spingit --from-literal=git_user=USERNAME -n NAMESPACE --from-literal=git_token="TOKEN" `
  
**3. Configmap spin2argo-config for input vaules**
To specifiy which file(s) to modify, we use a kubernetes configMap that specifies the source and target repos, the file to be modified and the elements (yaml-paths of elements) to be modified. A sample configMap file is provided. In this repo 
 -  **source** : repository url e.g. https://github.com/OpsMx/demo-spin2argo.git
 -  **sourcebranch** : repo branch e.g. main
 -  **filePath**     : file path e.g. sample-deploy.yaml 
 -  **value**: This represents the elements (yaml-paths) and their values that need to be updated. Sample file spin2argo-config.yaml gives an example 
   - Other examples are:   
          imagename : .spec.template.spec.containers[0].image = "${parameters["IMAGEID"]}"
          replicas  : .spec.replicas = ${ parameters["replicaCount"]}
          annotation: .metadata.annotations.jiraid = "${ parameters["JIRAID"]}"
   - The "parameters" expression is explained in detail [here](https://spinnaker.io/docs/guides/user/pipeline/expressions/)

  **Multiple values can be defined with pipe character seperator**

      .metadata.annotations.jiraid = "${ parameters["JIRAID"]}"|.spec.replicas = ${ parameters["replicaCount"]}|.spec.template.spec.containers[0].image = "${parameters["IMAGEID"]}"
      
      
