#!/bin/sh
set -eu

version=${version:-hmrc-dev}
out=${PWD}/out

export GOPATH=${PWD}/go
export PATH=${GOPATH}/bin:${PATH}

build() {
  mkdir -p ${out}/bin ${out}/tmp
  
  cd ${GOPATH}/src/github.com/hashicorp/terraform
  
  echo "Build Terraform"
  make bin XC_OS="linux" XC_ARCH="amd64"
  
  cp -r pkg ${out}/pkg
}

dockerfile() {
  echo "Terraform version ${version}"
  cat <<EOF > ${out}/tag
${version}
EOF
  
  echo "Terraform Dockerfile"
  cat <<EOF | tee > ${out}/Dockerfile
FROM alpine:3.4

RUN apk --no-cache add git zip

ADD pkg/linux_amd64/terraform /bin/terraform

VOLUME ["/terraform"]

ENTRYPOINT ["/bin/terraform"]

EOF
}

build
dockerfile
