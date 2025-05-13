#!/bin/sh

# Read secret string
read_secret()
{
    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT
    # Disable echo.
    stty -echo
    # Read secret.
    read "$@"
    # Enable echo.
    stty echo
    trap - EXIT
    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    echo
}

# Set up directories

CERT_PATH="certs"
mkdir -p $CERT_PATH
rm -f "$CERT_PATH"/*

# ==============================================================================

echo "Generating CA..."

printf "Choose CA Password: "
read_secret ca_password

printf "Enter your County Code (default: DE): "
read country
country=${country:-DE}

printf "Enter the number of years the cert should be valid (default: 10): "
read years
years=${years:-10}
days=$(( years * 365 ))

echo "Certificate will be valid for $days days."

openssl genpkey -quiet -algorithm RSA -out ${CERT_PATH}/ca.key -aes256 -pass pass:$ca_password
openssl req -quiet -x509 -new -nodes -key ${CERT_PATH}/ca.key -sha256 -days $days -out ${CERT_PATH}/ca.crt \
  -passin pass:$ca_password -subj "/C=$country/CN=RootCA"

# ==============================================================================

printf "Enter server name or IP of the MQTT server: "
read server

# Generate server key and certificate signing request (CSR)
openssl genpkey -quiet -algorithm RSA -out ${CERT_PATH}/server.key
openssl req -quiet -new -key ${CERT_PATH}/server.key -out ${CERT_PATH}/server.csr \
  -subj "/C=$country/CN=$server"

# Create server certificate signed by CA
openssl x509 -req -in ${CERT_PATH}/server.csr -CA ${CERT_PATH}/ca.crt -CAkey ${CERT_PATH}/ca.key -CAcreateserial \
  -out ${CERT_PATH}/server.crt -days $days -sha256 -passin pass:$ca_password

# ==============================================================================

printf "Enter client name of your choice (default: alamos): "
read client
client=${client:-alamos}

# Generate client key and certificate signing request (CSR)
openssl genrsa -out ${CERT_PATH}/client.key 2048
openssl req -quiet -new -key ${CERT_PATH}/client.key -out ${CERT_PATH}/client.csr \
  -subj "/C=$country/CN=$client"

# Create client certificate signed by CA
openssl x509 -req -in ${CERT_PATH}/client.csr -CA ${CERT_PATH}/ca.crt -CAkey ${CERT_PATH}/ca.key -CAcreateserial \
  -out ${CERT_PATH}/client.crt -days $days -sha256 -passin pass:$ca_password

# ==============================================================================

echo "Cleaning up..."
# Remove CSRs
rm ${CERT_PATH}/server.csr ${CERT_PATH}/client.csr

echo "CA files and certificate files are in ./${CERT_PATH}"
ls -1 $CERT_PATH
