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

CWD="$(pwd -P)"
BPNAME="$(git remote get-url origin)" || echo "${CWD}"
BPNAME="$(basename "${BPNAME}")"
BPNAME=${BPNAME//-/_}
BPNAME=${BPNAME//.git/''}

if [ "x${KITCHEN_SUITE_NAME}" == "x" ]; then
  echo "Not running within kitchen updating all test/fixtures."
  #KITCHEN_SUITE_NAME="default"
  FIXTURE_DIRS="$(ls -d ./test/fixtures/*)"
else
  echo "Running within kitchen suite ${KITCHEN_SUITE_NAME}."
  FIXTURE_DIRS="./test/fixtures/${KITCHEN_SUITE_NAME}"
fi

for adir in ${FIXTURE_DIRS} ; do
  echo "Processing fixture ${adir}"

  TFMFILE=${CWD}/${adir}/moduleoutputs.tf

  pushd . > /dev/null

  cd "${CWD}/${adir}"

  # Only select the blueprint name which refers to the module in ../../..
  MODULE_NAMES=$(terraform-config-inspect . --json | jq -r '.module_calls|.[]|select(.source=="../../..")|.name')

  printf "# This file has been created automatically.\n\n" > "${TFMFILE}"

  #for modules in $(terraform-config-inspect . --json | jq -r '.module_calls|keys[]') ; do

  for imodule in ${MODULE_NAMES} ; do
    cat >> "${TFMFILE}" <<EOF
output "module_${BPNAME}" {
  description = "Module outputs created within the test-fixture passing outputs of the module in-test."
  value       = module.${imodule}.*
}
EOF
  terraform fmt "${CWD}/${adir}"
  done

  popd > /dev/null

done
