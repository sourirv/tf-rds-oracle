#! /bin/bash
#Script to provision AWS RDS for Oracle.
#Provisions a MultiAZ RDS and optionally provisions a read replica in an AZ different from the primary and secondary AZ of the MultiAZ RDS.
#Requires:- terraform (v1.0.4)
#Requires: aws-cli, jq
#Requires aws access_key, secret and region to be set (For example via:- aws configure ...)

abort(){
  echo $1 && exit 1
}

abort_or_continue() {
  if [[ $1 -ne 0 ]];
  then
    echo "Bailing out ..."
    exit 1
  fi
}

log() {
    timestamp=`date +"%F %T"`
    echo -e "${timestamp} : $@";
}

prep_workspace(){
  found=$(terraform workspace list | grep "${1}" | wc -l)
  if [[ $found -eq 0 ]]
  then
    echo "Creating new workspace"
    terraform workspace new $1 >/dev/null
  else
    echo "Selecting existing workspace"
    terraform workspace select $1 >/dev/null
  fi
}

cleanup(){
  (
    cd $deployment
    find ./* -type d -name .terraform -exec rm -rf {} \; 2>/dev/null
    find ./* -type f -name .terraform.lock.hcl -exec rm -f {} \; 2>/dev/null
  )
}

while getopts c:p: flag
do
    # shellcheck disable=SC2220
    case "${flag}" in
        c) conf=${OPTARG};;
        p) vars=${OPTARG};;
    esac
done

## Setup paths for modules, configuration & profile
#deployment="$(dirname $(dirname $(realpath $0)) )"
#modules="$(dirname $(dirname $(realpath $0)) )/modules"
#config="$(dirname $(dirname $(realpath $0)) )/configuration/${conf}.txt"
#profile="$(dirname $(dirname $(realpath $0)) )/profiles/${vars}.tfvars"

#echo $(dirname "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")


deployment="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
modules="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))/modules"
config="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))/configuration/${conf}.txt"
profile="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))/profiles/${vars}.tfvars"

## Setup env vars for terraform
chmod +x ./setup_env_vars.sh
source ./setup_env_vars.sh $profile


cleanup

## Setup modules
while IFS= read -r line || [[ -n "$line" ]];
  do
    result=$(echo $line)
    if [ -z "$result" ];
    then
      continue
    fi
    (
        printf "\nDeploying module %s ...\n\n" $result
        module="$modules/$result"
        cd $module
        echo "Bucket name is: + ${TF_VAR_bucket_name}"
        echo "Region is: + ${TF_VAR_region}"
        terraform init -backend-config="bucket=${TF_VAR_bucket_name}" -backend-config="key=tfstate" -backend-config="region=${TF_VAR_region}" >/dev/null
        wkspace="${result}-${TF_VAR_environment}"

        echo "Workspace is:  + ${wkspace}"
        prep_workspace $wkspace
        terraform plan -out "${result}.plan"
        if [[ $? -ne 0 ]];
        then
          echo "$result plan failed."
          exit 1
        else
          terraform apply "${result}.plan"
          if [[ $? -ne 0 ]];
          then
            echo "$result deployment failed."
            exit 1
          fi
          rm "${result}.plan"
          echo "$result deployment completed."
        fi
    )
    abort_or_continue $?

    let "minutes=$SECONDS/60"
    echo "Time taken for $result deployment was $minutes: minutes"
  done < $config

