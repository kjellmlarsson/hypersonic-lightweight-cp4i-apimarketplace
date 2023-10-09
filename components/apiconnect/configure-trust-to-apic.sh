#Based on instructions here: https://ibm.github.io/event-automation/eem/integrating-with-apic/configure-eem-for-apic/

# Find API Connects platform api endpoint
apic_platform_uri=$(oc get -n cp4i apiconnectcluster/apic-cluster -o json | jq '.status.endpoints | .[] | select(.name=="platformApi") | .uri')
apic_platform_secretname=$(oc get -n cp4i apiconnectcluster/apic-cluster -o json | jq '.status.endpoints | .[] | select(.name=="platformApi") | .secretName')
echo $apic_platform_uri
echo $apic_platform_secretname


# The certificate that EEM needs to trust is default-ssl in the CP4I namespace

# Create a new secret in the event automation namespace containing the CA from the cp4i namespace
oc get secret -n cp4i default-ssl -o jsonpath="{.data['cert\.crt']}" | base64 -d > /tmp/ca.crt
oc create secret generic apim-cpd -n event-automation --from-file=ca.crt=./tmp/ca.crt

# Patch the event endpoint managment instance to use the just created CA
oc patch EventEndpointManagements my-eem-manager -n event-automation --patch-file ca-patch.yaml --type=merge

# Todo: patch the jwks url 






#openssl s_client -connect cpd-cp4i.apps.ocp-2700015rqr-y4lq.cloud.techzone.ibm.com:443

