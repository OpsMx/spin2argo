#! /bin/bash
validate_clone() {
if [ $? == 0 ]
then
  echo "INFO: Cloning done $SOURCE_REPO"
else
  echo "ERROR: Cloning failed with repo $SOURCE_REPO, Please check credentials and repo access...."
  exit 5
fi
}
tokenclone() {
    clone_result=$(git clone https://$git_user:${git_token}@$1/$2/$3.git /tmp/$5/$3 -b "$4"  2> /dev/null)
    validate_clone
}

sshclone() {
    apk add openssh > /dev/null
    mkdir -p ~/.ssh/
    echo "$GIT_SSH_KEY" | tr -d '\r' > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    clone_result=$(git clone git@$1:$2/$3.git /tmp/$5/$3 -b "$4"  2> /dev/null)
    validate_clone
}

filepromotion() {
  cp -RT /tmp/source/$SOURCE_REPO_PATH/* /tmp/target/$TARGET_REPO_PATH/      
}

gitcommitpush() {
  
  cd /tmp/target/$TARGET_REPO_PATH/
  git config --global user.email "noreply@opsmx.io"
  git config --global user.name "$git_user"
  git commit -am "Autocommit to add ${VALUES[*]}"
  git push
}

##############################
## script starts from here ###
##############################

## source the env

env > /tmp/envSource.txt
source /tmp/envSource.txt 2> /dev/null

## Input variables from the Configmap
cd /tmp/
SOURCE_REPO="$sourceRepo"
SOURCE_BRANCH="$sourceBranch"
SOURCE_DIR="$filePathDir"
TARGET_REPO="$targetRepo"
TARGET_BRANCH="$targetBranch"
VALUES="$value"

SOURCE_REPO_PATH=$(echo $SOURCE_REPO | awk -F// '{print $2}' | awk -F/ '{print $3}' | awk -F. '{print $1}')
SOURCE_ORG=$(echo $SOURCE_REPO | awk -F// '{print $2}' | awk -F/ '{print $2}')
SOURCE_API=$(echo $SOURCE_REPO | awk -F// '{print $2}' | awk -F/ '{print $1}')

TARGET_REPO_PATH=$(echo $TARGET_REPO | awk -F// '{print $2}' | awk -F/ '{print $3}' | awk -F. '{print $1}')
TARGET_ORG=$(echo $TARGET_REPO | awk -F// '{print $2}' | awk -F/ '{print $2}')
TARGET_API=$(echo $TARGET_REPO | awk -F// '{print $2}' | awk -F/ '{print $1}')

if [[ -z "$SOURCE_REPO" || -z "$TARGET_REPO"  ]]; then
  echo "ERROR: Source repo, target repo, path, and values must all be defined."
  exit 1
fi
if [[ -z "$SOURCE_BRANCH" ]]; then
  echo  "ERROR: Not defined the branch, Please specify branch."
  exit 1
fi

if [[ -z "$SOURCE_DIR" ]]; then
  echo  "ERROR: YAML source dir must be specified"
  exit 1
fi
if [[ -z "$VALUES" ]]; then
  echo  "ERROR: Not defined vaules to be replaced in the manifest "
  exit 1
fi

if [[ -z "$GIT_SSH_KEY" && -z "$git_token"  ]]; then
  echo "ERROR: Not defined github authendication token or SSH key ."
  exit 1
elif [[ ! -z "$GIT_SSH_KEY" && ! -z "$git_token"  ]]; then
  echo "INFO: Defined both token and SSH, considering the token to clone ..."
  tokenclone $SOURCE_API $SOURCE_ORG $SOURCE_REPO_PATH $SOURCE_BRANCH "source"
  tokenclone $TARGET_API $TARGET_ORG $TARGET_REPO_PATH $TARGET_BRANCH "target"
else
  if [[ ! -z "$git_token" ]]; then
    echo "INFO: cloning using token..."
    tokenclone $SOURCE_API $SOURCE_ORG $SOURCE_REPO_PATH $SOURCE_BRANCH "source"
    tokenclone $TARGET_API $TARGET_ORG $TARGET_REPO_PATH $TARGET_BRANCH "target"
  fi
  if [[ ! -z "$GIT_SSH_KEY" ]]; then
    echo "INFO: cloning using ssh..."
    sshclone $SOURCE_API $SOURCE_ORG $SOURCE_REPO_PATH $SOURCE_BRANCH "source"
    sshclone $TARGET_API $TARGET_ORG $TARGET_REPO_PATH $TARGET_BRANCH "target"
  fi
fi
cd /tmp/
filepromotion
gitcommitpush
