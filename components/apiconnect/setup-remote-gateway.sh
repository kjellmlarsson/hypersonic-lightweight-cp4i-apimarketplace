#Based on instructions here: https://ibm.github.io/event-automation/eem/integrating-with-apic/configure-eem-for-apic/

# Find the certificates that APIC needs to trust EEM

oc get secret -n event-automation my-eem-manager-ibm-eem-manager -o jsonpath="{.data['ca\.crt']}" | base64 -d > /tmp/cluster-ca.pem
oc get secret -n event-automation my-eem-manager-ibm-eem-manager -o jsonpath="{.data['tls\.crt']}" | base64 -d > /tmp/manager-client.pem
oc get secret -n event-automation my-eem-manager-ibm-eem-manager -o jsonpath="{.data['tls\.key']}" | base64 -d > /tmp/manager-client-key.pem

