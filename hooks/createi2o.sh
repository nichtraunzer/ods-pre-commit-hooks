#!/usr/bin/env bash
#
# Author: Josef Hartmann
#         josef.hartmann@boehringer-ingelheim.com
#
# Dependencies:
#                - terraform >= 0.12.x
#                - terraform-docs
#                - jq
#
# This scripts creates a inputs2outputs.tf file.
# The file defines a terraform output inputs2outputs that passes module inputs (variables) as outputs.
#


set -e
set -o pipefail

indenttfo() { sed 's/^/          /'; }

CWD="$(pwd -P)"
TFHFILE=${CWD}/inputs2outputs.tf

if [ -f "${TFHFILE}" ] ; then
    rm -f "${TFHFILE}"
fi

TFDOCSHCL=$(terraform-docs tfvars json "${CWD}" | jq -r 'with_entries(select(.key | contains("password") or contains("secret") or contains("access_key") | not)) | keys[] as $k | "\($k) = var.\($k)"' | indenttfo )

cat > "${TFHFILE}" <<EOF
# This file has been created automatically.
# terraform variables are passed to outputs.
# Following variable names are skipped: '.*[password|secret].*'.

output "inputs2outputs" {
  description = "all inputs passed to outputs"
  value = [{
${TFDOCSHCL}
  }]
  sensitive = true
}
EOF
terraform fmt "${CWD}"
