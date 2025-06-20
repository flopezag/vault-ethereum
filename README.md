# Vault Ethereum Plugin v0.3.0

The first incarnation of the `vault-ethereum` plugin was an exercise in [experimenting with an idea](https://www.hashicorp.com/resources/vault-platform-enterprise-blockchain) and [proving a point](https://immutability.io/). 2 years later, I feel both ends were acheived.

Having had several occasions to take this PoC to production with companies in the financial and blockchain communities [(plug for Immutability, LLC's custom development!)](mailto:jeff@immutability.io) I've decided to release an upgrade that tries to make the development experience better. I've also restricted the surface area of the plugin to a minimum.

Excepting the `convert` API, which I keep for entertainment value.

## Prerequisites

Please ensure jq is installed on your system before running the demo.

## Testing - in one terminal...

```sh

$ cd $GOPATH/src/github.com/immutability-io/vault-ethereum
$ make docker-build
$ make run

```

Then, **open a different terminal**...

```sh

$ cd $GOPATH/src/github.com/immutability-io/vault-ethereum/docker

# Authenticate
$ source ./local-test.sh auth
$ ./demo.sh > README.md

```
> [!NOTE]
>  Authentication is required. If you are not identified as root (or an authorized user), you will receive a "403 permission denied" error.
## View the demo

If everything worked... And you have run the command above, your demo is had by viewing the results: 

```sh
$ cat ./README.md
```

If you encounter the error x509: certificate signed by unknown authority and are unable to unseal HashiCorp Vault, the issue is typically related to Vault not trusting the TLS certificate authority (CA) used for its own certificate. This is common when using self-signed certificates or a private CA.

To resolve this problem, run the following command:

```sh
docker exec -e VAULT_ADDR="https://localhost:9200" \
  -e VAULT_CACERT="/home/vault/config/root.crt" \
  -it docker-vault_server-1 vault operator unseal
```

> [!NOTE]
> You can find the unseal key in at /docker/config.operator.json

If everything didn't work, please create an issue in GitHub explaining the problem.

## What is the API?

The best way to understand the API is to use the `path-help` command. For example:

```sh
$ vault path-help vault-ethereum/accounts/bob/deploy                                                                [±new-version ●]
Request:        accounts/bob/deploy
Matching Route: ^accounts/(?P<name>\w(([\w-.]+)?\w)?)/deploy$

Deploy a smart contract from an account.

## PARAMETERS

    abi (string)

        The contract ABI.

    address (string)

        <no description>

    bin (string)

        The compiled smart contract.

    gas_limit (string)

        The gas limit for the transaction - defaults to 0 meaning estimate.

    name (string)

        <no description>

    version (string)

        The smart contract version.

## DESCRIPTION

Deploy a smart contract to the network.
```
If you like to check the balance on Bob's account use the following command:

```sh
    vault read vault-eth2/accounts/bob/balance
```

Running this command we expect an output that provides the account address for Bob as well as its balance:

```sh
    Key        Value
    ---        -----
    address    0x90259301a101A380F7138B50b6828cfFfd4Cbf60
    balance    999496453868000000000
```

## About the Demo Mnemonic

The demo uses a 12-word [BIP-39 mnemonic](https://iancoleman.io/bip39/) phrase:
```text
  volcano story trust file before member board recycle always draw fiction when
```
This mnemonic is a randomly generated sequence from the official BIP39 word list (2048 words), used to derive the private key for a cryptocurrency wallet. It is included for testing and demonstration, allowing quick setup of a wallet for development and experimentation.

In this repository, the mnemonic deterministically generates the "bob" Ethereum account in the demo script. Using a fixed mnemonic ensures repeatable and predictable account credentials for consistent tests and demonstrations.

> [!Note]
> This mnemonic is for demonstration purposes only and should never be used to secure real assets, as it is publicly visible in the repository

## I still need help
[Please reach out to the original developer](mailto:jeff@immutability.io). 

[Please reach out to me](mailto:asma.taamallah@fiware.org). 

## Tip

Supporting OSS is very hard. 

This is ETH address of the original developer. The private keys are managed by this plugin:

`0x68350c4c58eE921B30A4B1230BF6B14441B46981`



