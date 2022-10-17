# Spin to Git

This pipeline is used to edit the manifest files with yq to replace the required files and push to the github


## steps to be followed

**1. create a new pipeline with pipeline json**

**2. Create a secret for github**


 -  Github Username and token or SSH key is created in a secret
 
 -  If you specify both token will be considered
 
 -  You any one SSH key or token if you dont want make it empty
 
          kubectl create secret generic git-secret-spingit --from-file=GIT_SSH_KEY=~/.ssh/id_rsa --from-literal=git_user=maheshopsmx --from-literal=git_token="XXX" -n <NAMESPACE>
  
**3. Configmap spin2argo-config for input vaules**

 -  **source** : repository url 
 -  **sourcebranch** : repo branch
 -  **filePath**     : file path (eg. deply/deploy.yaml) 
 -  **value**: change the manifest values, Multiple values will be proivided using pipe | symbol
 
          imagename : .spec.template.spec.containers[0].image = "${parameters["IMAGEID"]}"
          replicas  : .spec.replicas = ${ parameters["replicaCount"]}
          annotation: .metadata.annotations.jiraid = "${ parameters["JIRAID"]}"


  **Multiple values can be defined like this**

      .metadata.annotations.jiraid = "${ parameters["JIRAID"]}"|.spec.replicas = ${ parameters["replicaCount"]}|.spec.template.spec.containers[0].image = "${parameters["IMAGEID"]}"
