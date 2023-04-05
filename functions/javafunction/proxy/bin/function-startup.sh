#!/usr/bin/env bash

set -euo pipefail

additional_java_args=()
if [[ -n "${DEBUG_PORT:-""}" ]]; then
	java_version=$(java -version 2>&1 | grep -i version | awk '{gsub(/"/, "", $3); print $3}')

	if [[ "${java_version}" == 1.8* ]]; then
		additional_java_args+=("-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${DEBUG_PORT}")
	else
		additional_java_args+=("-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:${DEBUG_PORT}")
	fi
fi

exec java "${additional_java_args[@]}" \
	-jar "${JVM_FUNCTION_RUNTIME_JAR_PATH}" serve "${JVM_FUNCTION_BUNDLE_DIR}" -h 0.0.0.0 -p "${PORT:-8080}"