#!/bin/bash

# Based on instructions here: https://ibm.github.io/event-automation/eem/integrating-with-apic/configure-eem-for-apic/
# Find the certificates that APIC needs to trust EEM
eem_cluster_ca=$(oc get secret -n event-automation my-eem-manager-ibm-eem-manager -o jsonpath="{.data['ca\.crt']}" | base64 -d | jq -sR .)
eem_certificate=$(oc get secret -n event-automation my-eem-manager-ibm-eem-manager -o jsonpath="{.data['tls\.crt']}" | base64 -d)
eem_private_key=$(oc get secret -n event-automation my-eem-manager-ibm-eem-manager -o jsonpath="{.data['tls\.key']}" | base64 -d)

# Create an input file with the CA for the APIC CLI to use 
truststore_json_payload='{"title":"eem-truststore","name":"eem-truststore","summary":"EEM Truststore","truststore":'${eem_cluster_ca}'}'
echo $truststore_json_payload > /tmp/truststore.json

# Create an input file with private key and cert for the APIC CLI to use
# Concatenate the certificate and private key
cert_and_key=$eem_certificate$eem_private_key
cert_and_key_json=$(echo "$cert_and_key" | jq -sR .)

keystore_json_payload='{"title":"eem-keystore","name":"eem-keystore","summary":"eem-keystore","keystore":'${cert_and_key_json}'}'
echo "$keystore_json_payload" > /tmp/keystore.json

#Find the api connect platform api endpoint
platform_api_endpoint=$(oc get -n cp4i apiconnectcluster/apic-cluster -o json | jq -r '.status.endpoints | .[] | select(.name=="platformApi") | .uri')
echo 'Platform API endpoint is' $platform_api_endpoint

#APIC CLI needs the trailing /api removed
platform_api_endpoint=$(echo $platform_api_endpoint | sed 's/.\{4\}$//')
echo 'Platform API endpoint corrected for CLI is' $platform_api_endpoint

apic client-creds:clear
apic client-creds:set /Users/kjelllarsson/Downloads/credentials.json
apic login --server $platform_api_endpoint --sso

# Remove any previous output from the keystore:get and truststore:get commands.
rm -f /tmp/eem-truststore.json
rm -f /tmp/eem-keystore.json

# Create truststore
apic truststores:create --org admin --server $platform_api_endpoint --format json /tmp/truststore.json
apic truststores:get --org admin --server $platform_api_endpoint --format json eem-truststore --fields "name,url" --output /tmp

# Create keystore
apic keystores:create --org admin --server $platform_api_endpoint --format json /tmp/keystore.json
apic keystores:get --org admin --server $platform_api_endpoint --format json eem-keystore --fields "name,url" --output /tmp

truststore_url=$(cat /tmp/eem-truststore.json | jq ' .url ')
keystore_url=$(cat /tmp/eem-keystore.json | jq ' .url ')

echo $truststore_url
echo $keystore_url