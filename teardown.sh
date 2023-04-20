#! /bin/bash
#Script to destroy the entire deployment

while getopts c:p:f: flag
do
    # shellcheck disable=SC2220
    case "${flag}" in
        c) conf=${OPTARG};;
        p) vars=${OPTARG};;
        f) annihilate=${OPTARG};;
    esac
done

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

cleanup(){
  (
    cd $deployment
    find ./* -type d -name .terraform -exec rm -rf {} \; 2>/dev/null
    find ./* -type f -name .terraform.lock.hcl -exec rm -f {} \; 2>/dev/null
  )
}

## Setup paths for modules, configuration & profile
#deployment="$(dirname $(dirname $(realpath $0)) )"
#modules="$(dirname $(dirname $(realpath $0)) )/modules"
#config="$(dirname $(dirname $(realpath $0)) )/configuration/${conf}.txt"
#profile="$(dirname $(dirname $(realpath $0)) )/profiles/${vars}.tfvars"

deployment="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
modules="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))/modules"
config="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))/configuration/${conf}.txt"
profile="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))/profiles/${vars}.tfvars"

echo $profile
echo $modules
exit 0

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
        printf "\nTeardown module %s ...\n\n" $result
        module="$modules/$result"
        cd $module
        terraform init -backend-config="bucket=${TF_VAR_bucket_name}" -backend-config="key=tfstate" -backend-config="region=${TF_VAR_region}" >/dev/null
        wkspace="${result}-${TF_VAR_environment}"
        found=$(terraform workspace list | grep "${wkspace}" | wc -l)
        if [[ $found -eq 1 ]]
        then
          terraform workspace select $wkspace >/dev/null
        fi
        terraform destroy -auto-approve
        terraform workspace select default
        if [[ $found -eq 1 ]]
        then
          terraform workspace delete $wkspace >/dev/null
        fi
    )
  done < $config
