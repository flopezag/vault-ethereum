#!/bin/bash

OPERATOR_JSON="/home/vault/config/operator.json"
OPERATOR_SECRETS=$(cat $OPERATOR_JSON)
export VAULT_ADDR='https://localhost:9200'

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing..."
    
    # Install jq based on the package manager
    if [ -x "$(command -v apt)" ]; then
        sudo apt update && sudo apt install -y jq
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y jq
    elif [ -x "$(command -v brew)" ]; then
        brew install jq
    else
        echo "Package manager not found. Please install jq manually."
        exit 1
    fi
else
    echo "jq is already installed."
fi

function banner() {
  echo "+----------------------------------------------------------------------------------+"
  printf "| %-80s |\n" "`date`"
  echo "|                                                                                  |"
  printf "| %-80s |\n" "$@"
  echo "+----------------------------------------------------------------------------------+"
}

function authenticate() {
    banner "Authenticating to $VAULT_ADDR as root"
    ROOT=$(echo $OPERATOR_SECRETS | jq -r .root_token)
    export VAULT_TOKEN=$ROOT
}

function unauthenticate() {
    banner "Unsetting VAULT_TOKEN"
    unset VAULT_TOKEN
}

function unseal() {
    banner "Unsealing $VAULT_ADDR..."

    # Wait for vault to become responsive
    while ! vault status > >/dev/null 2>&1; do
        echo "Waiting for vault to start..."
        sleep 5
    done

    # Check if already unsealed
    if vault status | grep q 'Sealed.*false'; then
        echo "Vault slready unsealed"
        return
    fi
    
    # Apply all unseal keys until threshold met
    KEYS=($(echo $OPERATOR_SECRETS | jq -r '.unseal_keys_hex[]'))
    THRESHOLD=$(echo $OPERATOR_SECRETS | jq -r '.secret_threshold')

    for ((i=0; i<$THRESHOLD; i++)); do
        echo "Applying key $(($i+1))/$THRESHOLD"
        vault operator unseal "${KEYS[$i]}" >/dev/null
    done
}

function configure() {
    banner "Installing vault-ethereum plugin at $VAULT_ADDR..."
	SHA256SUMS=`cat /home/vault/plugins/SHA256SUMS | awk '{print $1}'`
	vault write sys/plugins/catalog/secret/vault-ethereum \
		  sha_256="$SHA256SUMS" \
		  command="vault-ethereum --ca-cert=$CA_CERT --client-cert=$TLS_CERT --client-key=$TLS_KEY"

	if [[ $? -eq 2 ]] ; then
	  echo "vault-ethereum couldn't be written to the catalog!"
	  exit 2
	fi

	vault secrets enable -path=vault-ethereum -plugin-name=vault-ethereum plugin
	if [[ $? -eq 2 ]] ; then
	  echo "vault-ethereum couldn't be enabled!"
	  exit 2
	fi
    vault audit enable file file_path=stdout
}

function status() {
    vault status
}

function init() {
    if [ ! -f "$OPERATOR_JSON" ]; then
        banner "Initializing Vault..."
        OPERATOR_SECRETS=$(vault operator init -key-shares=1 -key-threshold=1 -format=json | jq .)
        echo "$OPERATOR_SECRETS" > $OPERATOR_JSON
    else
        OPERATOR_SECRETS=$(cat $OPERATOR_JSON)
    fi
}
sleep 20
if [ -f "$OPERATOR_JSON" ]; then
    unseal
    status
else
    init
    unseal
    authenticate
    configure
    unauthenticate
    status
fi
