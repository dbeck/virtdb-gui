#!/usr/bin/env bash
mkdir ssl
cd ssl

# The following lines are commented, because I don't know any reason to generate any local CA certs.
#echo "\nGenerating local CA"
#openssl genrsa -des3 -out ca.key 1024
#openssl req -new -key ca.key -out ca.csr
#openssl x509 -req -days 365 -in ca.csr -out ca.crt -signkey ca.key

echo "\nGenerating self-signed server certification"
openssl genrsa -des3 -out server.key 1024
openssl req -new -key server.key -out server.csr
cp server.key server.key.orig
openssl rsa -in server.key.orig -out server.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
