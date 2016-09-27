#!/bin/sh
set -eu

out=${PWD}/out

export GOPATH=${PWD}/go
export PATH=${GOPATH}/bin:${PATH}

apk --no-cache --no-progress add zip bash git make

build() {
  mkdir -p ${out}/bin ${out}/tmp

  cd ${GOPATH}/src/github.com/hashicorp/terraform

  version=$(sed -ne 's/^const Version = "\(.*\)"/\1/p' terraform/version.go)-hmrc
  sed -i terraform/version.go -e 's/^(const VersionPrerelease = ).*$/\1"hmrc"/'
  cat <<EOF > ${out}/version
${version}
EOF

  echo "Build terraform ${version}"
  make bin XC_OS="linux darwin" XC_ARCH="amd64"

  cp -r pkg ${out}/pkg
}

dockerfile() {
  echo "Terraform Dockerfile"
  cat <<EOF | tee > ${out}/Dockerfile
FROM alpine:3.4

RUN apk --no-cache --no-progress add git openssh-client

ADD pkg/linux_amd64/terraform /bin/terraform

VOLUME ["/terraform"]

ENTRYPOINT ["/bin/terraform"]

EOF
}

tarball() {
  echo "Creating ${out}/terraform-linux-amd64.tgz"
  tar czf ${out}/terraform-linux-amd64.tgz -C ${out}/pkg/linux_amd64/ terraform
  
  echo "Creating ${out}/terraform-darwin-amd64.tgz"
  tar czf ${out}/terraform-darwin-amd64.tgz -C ${out}/pkg/darwin_amd64/ terraform
}

build
dockerfile
tarball
