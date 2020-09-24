#!/bin/bash

set -Eeo pipefail

CERTIFICATES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PKI_DIR="${CERTIFICATES_DIR}/CA"
generated_certs_dir="${CERTIFICATES_DIR}/site-certs/"
AWS_REGION=${AWS_REGION:-eu-west-2}
ENVIRONMENT=${ENVIRONMENT:-dev}

function fetch_secret {
  secret_id=$1
  >&2 echo "Fetching secret from AWS at $secret_id"
  aws ssm get-parameter --with-decryption --region $AWS_REGION --name $secret_id | jq -r ".Parameter.Value"
}

function prepare_certs {
  keys_file_name="$1"
  # If you intend to secure the URL https://www.yourdomain.com, then your CSR’s common name must be www.yourdomain.com
  common_name="$2"
  # ip1="10.4.0.5"
  organization_name='NHS Digital'
  fqdn=$common_name

  if [[ -z "$keys_file_name" ]]; then
    echo "Keys filename missing"
    exit 1
  fi
  if [[ -z "$common_name" ]]; then
    echo "domain name missing"
    exit 1
  fi

  if [[ -z ${CA_PASSWORD} ]]; then
    export CA_PASSWORD=$(fetch_secret "/repo/${ENVIRONMENT}/prm-deductions-support-infra/user-input/ca-password")
  fi
  if [[  ! -f ${PKI_DIR}/certs/ca.crt ]]; then
    mkdir -p ${PKI_DIR}/certs
    fetch_secret "/repo/${ENVIRONMENT}/prm-deductions-support-infra/user-input/ca-crt" > "${PKI_DIR}/certs/ca.crt"
  fi
  if [[ ! -f ${PKI_DIR}/private/ca.key ]]; then
    mkdir -p ${PKI_DIR}/private
    fetch_secret "/repo/${ENVIRONMENT}/prm-deductions-support-infra/user-input/ca-key" > "${PKI_DIR}/private/ca.key"
  fi
  if [[  -f "${generated_certs_dir}/${keys_file_name}.key" ]]; then
    echo "${generated_certs_dir}/${keys_file_name}.key already exist"
    return 0
  fi
  echo "Preparing certificates for: ${keys_file_name} on ${fqdn}, common_name: ${common_name}, organization_name: ${organization_name}"

  # 1. Create a config file for generating a Certificate Signing Request (CSR).
  cat <<EOF >${CERTIFICATES_DIR}/csr.conf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
CN = ${common_name}
O = ${organization_name}
# Organization Unit Name, let's use it as commentary
OU = Deductions Team

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${fqdn}

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

  # 2. Create a private key (${keys_file_name}.key) and then generate a certificate request (${keys_file_name}.csr) from it:
  # (steps 3. and 5. from: https://kubernetes.io/docs/concepts/cluster-administration/certificates/)
  # https://www.openssl.org/docs/manmaster/man1/req.html
  openssl genrsa -out ${keys_file_name}.key 2048
  openssl req -new -key ${keys_file_name}.key -out ${keys_file_name}.csr -config ${CERTIFICATES_DIR}/csr.conf
  # the same but with 1 line:
  # openssl req -newkey rsa:4096 -keyout ${keys_file_name}.key -out ${keys_file_name}.csr
  # 3. Generate the server certificate (${keys_file_name}.crt) using the ca.key, ca.crt and ${keys_file_name}.csr:
  openssl x509 -req -in ${keys_file_name}.csr -CA ${PKI_DIR}/certs/ca.crt -CAkey ${PKI_DIR}/private/ca.key \
    -CAcreateserial -out ${keys_file_name}.crt -days 365 \
    -extensions v3_ext -extfile ${CERTIFICATES_DIR}/csr.conf -passin pass:${CA_PASSWORD}

  mkdir -p ${generated_certs_dir}
  cp ${PKI_DIR}/certs/ca.crt ${generated_certs_dir}/
  # see https://www.vaultproject.io/docs/configuration/listener/tcp.html#tls_cert_file
  cat ${keys_file_name}.crt ${PKI_DIR}/certs/ca.crt > ${generated_certs_dir}/${keys_file_name}-combined.crt
  mv ${keys_file_name}.crt ${generated_certs_dir}/
  mv ${keys_file_name}.key ${generated_certs_dir}/
  rm ${keys_file_name}.csr
  chmod 660 "${generated_certs_dir}/"*
  chmod 755 "${generated_certs_dir}"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--file)
    BASE_FILE_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    -e|--environment)
    ENVIRONMENT="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "Base key file name  = ${BASE_FILE_NAME}"
echo "Domain          = ${DOMAIN}"

prepare_certs "${BASE_FILE_NAME}" "${DOMAIN}"
