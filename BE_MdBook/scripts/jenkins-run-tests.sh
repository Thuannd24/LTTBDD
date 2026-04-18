#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="${ROOT_DIR}/services"

if ! command -v mvn >/dev/null 2>&1; then
  echo "ERROR: 'mvn' is not available in PATH."
  echo "Install Maven on the Jenkins agent or configure a Jenkins Maven tool."
  exit 1
fi

if [[ ! -d "${SERVICES_DIR}" ]]; then
  echo "ERROR: services directory not found at ${SERVICES_DIR}"
  exit 1
fi

mapfile -t pom_files < <(find "${SERVICES_DIR}" -mindepth 2 -maxdepth 2 -name pom.xml | sort)

if [[ ${#pom_files[@]} -eq 0 ]]; then
  echo "ERROR: no Maven services found under ${SERVICES_DIR}"
  exit 1
fi

echo "Discovered ${#pom_files[@]} Maven service(s)."

for pom_file in "${pom_files[@]}"; do
  service_dir="$(dirname "${pom_file}")"
  service_name="$(basename "${service_dir}")"

  echo ""
  echo "=================================================="
  echo "Running tests for ${service_name}"
  echo "=================================================="

  (
    cd "${service_dir}"
    mvn -B -ntp clean test
  )
done

echo ""
echo "All Maven service tests completed successfully."
