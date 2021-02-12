#!/usr/bin/env bash
#
# Author: Josef Hartmann
#         josef.hartmann@boehringer-ingelheim.com
#
# This script creates terraform output for fixtures passing the outputs of the module using a pre-defined output naming convention.
#
# This script can be used within Makefile and/or pre-commit hooks or kitchen.yml lifecycle environments.
#

set -e
set -o pipefail

if [ "x${KITCHEN_SUITE_NAME}" == "x" ]; then
  echo "Not running within kitchen using default."
  KITCHEN_SUITE_NAME="default"
fi

CWD="$(pwd -P)"
TFMFILE=${CWD}/test/fixtures/${KITCHEN_SUITE_NAME}/moduleoutputs.tf

BPNAME=$( echo "${CWD}" | sed 's/.*\/\(blue.*\)/\1/g' | sed 's/-/_/g' )

pushd . > /dev/null

cd "${CWD}"/test/fixtures/${KITCHEN_SUITE_NAME}

# Only select the blueprint name which refers to the module in ../../..
MODULE_NAMES=$(terraform-config-inspect . --json| jq -r '.module_calls|.[]|select(.source=="../../..")|.name')

echo "# file created automatically" > "${TFMFILE}"

#for modules in $(terraform-config-inspect . --json| jq -r '.module_calls|keys[]') ; do
for imodule in ${MODULE_NAMES} ; do
  cat >> "${TFMFILE}" <<EOF
output "module_${BPNAME}" {
  description = "Module outputs created within the test-fixture passing outputs of the module in-test."
  value       = module.${imodule}.*
}
EOF
done

popd > /dev/null
