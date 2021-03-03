#!/usr/bin/env bash
#
# Author: Josef Hartmann
#         josef.hartmann@boehringer-ingelheim.com
#
# Dependencies:
#                - terraform >= 0.12.x
#                - hcl2tojson (Python)
#                - jq
#
# This scripts creates a local2outputs.tf file defined within main.tf (not all tf files).
# The file defines a terraform output locals2outputs that passes module locals definitions as outputs.
#

set -e
set -o pipefail

CWD="$(pwd -P)"
TFLFILE=${CWD}/locals2outputs.tf

MAINJSON=$(mktemp)
hcl2tojson main.tf "${MAINJSON}" > /dev/null
LOCALSHCL=$(jq -r '.locals[0]|keys[] as $k | "\($k) = local.\($k)"' < "${MAINJSON}")

echo "# file created automatically" > "${TFLFILE}"

cat >> "${TFLFILE}" <<EOF

output "locals2outputs" {
  description = "all local definitions to outputs"
  value       = [{
  ${LOCALSHCL}
  }]
}
EOF

terraform fmt "${TFLFILE}"
rm -f "${MAINJSON}"
