#!/bin/bash

install_dir=$(dirname "$0")
. ${install_dir}/metallb.config
yaml_dir="${install_dir}/yaml"

function init() {
    echo "---Initialize MetalLB Installation environment---"
    if [[ -z ${registry} ]]; then
        registry=""
    else
        registry=${registry}
    fi

    if [[ -z ${metallb_version} ]]; then
        metallb_version=v0.9.3
    else
        metallb_version=${metallb_version}
    fi

    if [[ -z ${metallb_namespace} ]]; then
        metallb_namespace=metallb-system
    else
        metallb_namespace=${metallb_namespace}
    fi

    if [[ -z ${metallb_address_pool} ]]; then
        metallb_address_pool=""
    else
        metallb_address_pool=${metallb_address_pool}
    fi

    # Change metallb image version
    sed -i 's|v0.9.3|'${metallb_version}'|g' ${yaml_dir}/metallb.yaml

    # Change metallb namespace
    sed -i 's|metallb-system|'${metallb_namespace}'|g' ${yaml_dir}/metallb_namespace.yaml
    sed -i 's|metallb-system|'${metallb_namespace}'|g' ${yaml_dir}/metallb.yaml

    # Set registry address when exists
    if [[ ! -z ${registry} ]]; then
        sed -i 's/metallb\/speaker/'${registry}'\/metallb\/speaker/g' ${yaml_dir}/metallb.yaml
        sed -i 's/metallb\/controller/'${registry}'\/metallb\/controller/g' ${yaml_dir}/metallb.yaml 
    fi

    echo "---MetalLB Installation initialization complete---"
}

function install() {
    echo "---Installing MetalLB---"

    kubectl apply -f ${yaml_dir}/metallb_namespace.yaml
    kubectl create secret generic -n ${metallb_namespace} memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    kubectl apply -f ${yaml_dir}/metallb.yaml

    echo "---MetalLB installation complete---"
}

function uninstall() {
    echo "---Uninstalling CNI---"

    kubectl delete -f ${yaml_dir}/metallb.yaml
    kubectl delete secret -n ${metallb_namespace} memberlist 
    kubectl delete -f ${yaml_dir}/metallb_namespace.yaml

    echo "---CNI uninstallation complete---"
}

function main() {
    case "${1:-}" in
    install)
        init
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        set +x
        echo "service list:" >&2
        echo "  $0 install" >&2
        echo "  $0 uninstall" >&2
        ;;
    esac
}

main $1