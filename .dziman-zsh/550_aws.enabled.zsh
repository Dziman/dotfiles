#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# AWS related functions
################################################################################

profiles_file=~/.aws/profiles

function calculate-s3-bucket-size() {
    if command-exists aws; then
	if command-exists gnumfmt; then
	    aws s3api list-object-versions --bucket $1 --query 'Versions[*].[Size,Size]' --output text  | awk '{s+=$1} END {printf "%.0f\n", s}' | gnumfmt --to=iec-i --suffix=B --padding=7
	else
	    echo "gnumfmt is not found"
	fi
    else
	echo "AWS CLI is not found"
    fi
}

function aws-assume-role() {
    local account_id=$1
    local role_to_assume=$2

    local role_arn="arn:aws:iam::${account_id}:role/${role_to_assume}"

    aws_credentials=$(aws sts assume-role --role-arn $role_arn --role-session-name "AssumedFromShell")

    export AWS_ACCESS_KEY_ID=$(echo $aws_credentials | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $aws_credentials | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $aws_credentials | jq -r '.Credentials.SessionToken')
    export AWS_ASSUMED_ROLE=$role_to_assume
}

function aws-unassume-role() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_ASSUMED_ROLE
}

# TODO Reduce code duplication
function aws-switch-role() {
    if [ ! -f  $profiles_file ]; then
        echo "Profiles file '$profiles_file' doesn't exist"
        return 1
    fi

    local profiles=($(cat $profiles_file 2>/dev/null | jq -r '.profiles | keys[]' 2>/dev/null))

    local profile=$AWS_PROFILE

    if [ -z "$profile" ]; then
        echo "No current AWS profile selected"
        return 1
    fi

    if ! (($profiles[(Ie)$profile])); then
        echo "Profile '$profile' not defined in $profiles_file"
        return 2
    fi

    local roles=($(cat $profiles_file 2>/dev/null | jq -r ".profiles.\"$profile\".roles | .[]" 2>/dev/null))
    local account_id=($(cat $profiles_file 2>/dev/null | jq -r ".profiles.\"$profile\".\"account-id\"" 2>/dev/null))    

    local role=$1

    if [ -z $role ]; then
    if [[ -o interactive ]]; then
        # TODO If only one role in`roles` then just use it without prompt
        role=$(printf "%s\n" "${roles[@]}" | fzf)
        if [ -z $role ]; then
            echo "Role wasn't selected"
            return 3
        fi
    else
        echo "No role provided"
        return 4
    fi
    fi

    # Validate if role exists
    if (($roles[(Ie)$role])); then
        aws-assume-role $account_id $role
    else
        echo "Role '$role' not defined in $profiles_file"
        return 5
    fi

}

function aws-switch-profile() {
    if [ ! -f  $profiles_file ]; then
        echo "Profiles file '$profiles_file' doesn't exist"
        return 1
    fi

    local profiles=($(cat $profiles_file 2>/dev/null | jq -r '.profiles | keys[]' 2>/dev/null))

    local profile=$1

    if [ -z "$profile" ]; then # no profile provided
        if [[ -o interactive ]]; then
            profile=$(printf "%s\n" "${profiles[@]}" | fzf)
            if [ -z "$profile" ]; then
                echo "Profile wasn't selected"
                return 2
            fi
        else
            # TODO Add 'default profile' concept?
            echo "No profile provided"
            return 3
        fi
    fi

    # Validate if profile exists
    if (($profiles[(Ie)$profile])); then
        export AWS_PROFILE=$profile
    else
        echo "Profile '$profile' not defined in $profiles_file"
        return 4
    fi

}
