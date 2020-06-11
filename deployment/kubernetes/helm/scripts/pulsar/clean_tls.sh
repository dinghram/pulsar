#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

set -e

CHART_HOME=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/../.. && pwd)
cd ${CHART_HOME}

namespace=${namespace:-pulsar}
release=${release:-pulsar-dev}
clientComponents=${clientComponents:-"toolset"}
serverComponents=${serverComponents:-"bookie,broker,proxy,recovery,zookeeper"}

usage() {
    cat <<EOF
This script is used to delete tls certs for a given pulsar helm deployment generated by "upload_tls.sh".
Options:
       -h,--help                        prints the usage message
       -n,--namespace                   the k8s namespace to install the pulsar helm chart. Defaut to ${namespace}.
       -k,--release                     the pulsar helm release name. Default to ${release}.
       -c,--client-components           the client components of pulsar cluster. a comma separated list of components. Default to ${clientComponents}.
       -s,--server-components           the server components of pulsar cluster. a comma separated list of components. Default to ${serverComponents}.
Usage:
    $0 --namespace pulsar --release pulsar-dev
EOF
}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--namespace)
    namespace="$2"
    shift
    shift
    ;;
    -k|--release)
    release="$2"
    shift
    shift
    ;;
    -c|--client-components)
    clientComponents="$2"
    shift
    shift
    ;;
    -s|--server-components)
    serverComponents="$2"
    shift
    shift
    ;;
    -h|--help)
    usage
    exit 0
    ;;
    *)
    echo "unknown option: $key"
    usage
    exit 1
    ;;
esac
done

function delete_ca() {
    local tls_ca_secret="${release}-ca-tls"
    kubectl delete secret ${tls_ca_secret} -n ${namespace}
}

function delete_server_cert() {
    local component=$1
    local server_cert_secret="${release}-tls-${component}"

    kubectl delete secret ${server_cert_secret} \
        -n ${namespace}
}

function delete_client_cert() {
    local component=$1
    local client_cert_secret="${release}-tls-${component}"

    kubectl delete secret ${client_cert_secret} \
        -n ${namespace}
}

delete_ca

IFS=', ' read -r -a server_components <<< "$serverComponents"
for component in "${server_components[@]}"
do
    delete_server_cert ${component}
done

IFS=', ' read -r -a client_components <<< "$clientComponents"
for component in "${client_components[@]}"
do
    delete_client_cert ${component}
done