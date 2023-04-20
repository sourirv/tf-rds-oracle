#! /bin/bash


## Setup env vars for terraform
while IFS= read -r line || [[ -n "$line" ]];
  do
    result=$(echo $line)
    if [[ ! "$line" =~ ^#.*$ ]]
    then
      export TF_VAR_$result
    fi
  done < ${1}