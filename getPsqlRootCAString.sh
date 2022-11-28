#!/bin/bash
echo "This aims to get the PostgreSQL CA cert as a string suited for Wiki.js deployconfig"
echo "Make sure you use the right context and namespace"

oc get secret pgo-root-cacert -n wikijs -o jsonpath='{.data.root\.crt}' | base64 --decode | sed '/-----BEGIN CERTIFICATE-----/d;/-----END CERTIFICATE-----/d;' | tr -d '\n'
