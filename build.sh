#!/bin/sh
set -eu

version=${version:-0.7.2-hmrc}
out=${PWD}/out

export GOPATH=${PWD}/go
export PATH=${GOPATH}/bin:${PATH}

apk --no-cache add zip bash git make

build() {
  mkdir -p ${out}/bin ${out}/tmp

  cd ${GOPATH}/src/github.com/hashicorp/terraform

  echo "Build Terraform"
  make bin XC_OS="linux" XC_ARCH="amd64"

  cp -r pkg ${out}/pkg
}

dockerfile() {
  echo "Terraform version ${version}"
  cat <<EOF > ${out}/version
${version}
EOF

  echo "Terraform Dockerfile"
  cat <<EOF | tee > ${out}/Dockerfile
FROM alpine:3.4

RUN apk --no-cache add git

ADD pkg/linux_amd64/terraform /bin/terraform

VOLUME ["/terraform"]

ENTRYPOINT ["/bin/terraform"]

EOF
}

tarball() {
  echo "Creating ${out}/terraform-linux-amd64.tgz"
  tar czf ${out}/terraform-linux-amd64.tgz -C ${out}/pkg/linux_amd64/
}

build
dockerfile
tarball
