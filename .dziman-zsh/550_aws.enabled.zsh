#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# AWS related functions
################################################################################

calculate-s3-bucket-size() {
  # TODO Add checks for AWS CLI, gnumfmt presence?
  aws s3api list-object-versions --bucket $1 --query 'Versions[*].[Size,Size]' --output text  | awk '{s+=$1} END {printf "%.0f\n", s}' | gnumfmt --to=iec-i --suffix=B --padding=7
}
