#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# AWS related functions
################################################################################

calculate-s3-bucket-size() {
    # TODO Add checks for AWS CLI, gnumfmt presence?
    aws s3api list-object-versions --bucket $1 --query 'Versions[*].[Size,Size]' --output text  | awk '{s+=$1} END {printf "%.0f\n", s}' | gnumfmt --to=iec-i --suffix=B --padding=7
}

function assume-role-export-creds() {
    local role_arn=${1:-arn:aws:iam::731001202766:role/RootAdminIAMRole}

    aws_credentials=$(aws sts assume-role --role-arn $role_arn --role-session-name "AssumedFromShell")

    export AWS_ACCESS_KEY_ID=$(echo $aws_credentials|jq '.Credentials.AccessKeyId'|tr -d '"')
    export AWS_SECRET_ACCESS_KEY=$(echo $aws_credentials|jq '.Credentials.SecretAccessKey'|tr -d '"')
    export AWS_SESSION_TOKEN=$(echo $aws_credentials|jq '.Credentials.SessionToken'|tr -d '"')
}
