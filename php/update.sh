#!/usr/bin/env bash

set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"

versions=( '5.6' '7.0' '7.1' )
versions=( "${versions[@]%/}" )

generated_warning() {
	cat <<-EOH
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
		#
		# PLEASE DO NOT EDIT IT DIRECTLY.
		#
	EOH
}

base="Dockerfile-php.template"
travisEnv=
for version in "${versions[@]}"; do
    dockerfiles=()

    if [ "${version}" == "5.6" ]; then
        APCU_VERSION="4.0.11"
        REDIS_VERSION="2.2.8"
    else
        APCU_VERSION="5.1.8"
        REDIS_VERSION="3.1.1"
    fi

    for target in \
        fpm cli \
    ; do
        [ -d "${version}/${target}" ] || mkdir -p ${version}/${target}
        INHERIT_VERSION=${version}-${target}
        echo "Generating ${version}/${target}/Dockerfile from ${base} + ${target}-Dockerfile-block-*"
        awk '
            $1 == "##</autogenerated>##" { ia = 0 }
            !ia { print }
            $1 == "##<autogenerated>##" { ia = 1; ab++; ac = 0 }
            ia { ac++ }
            ia && ac == 1 { system("cat '${target}'-Dockerfile-block-" ab) }
        ' "${base}" > "${version}/${target}/Dockerfile"
        cp -v composer.sh "${version}/${target}/"
        cp -v "${target}-docker-app-start.sh" "${version}/${target}/docker-app-start.sh"
        cp -v "${target}-php.ini" "${version}/${target}/php.ini"
        if [ ${target} == 'fpm' ]; then
            cp -v fpm-www.conf "${version}/${target}/www.conf"
        fi
        (
            set -x
            sed -ri \
                -e 's!%%REDIS_VERSION%%!'"${REDIS_VERSION}"'!' \
                -e 's!%%APCU_VERSION%%!'"${APCU_VERSION}"'!' \
                -e 's!%%INHERIT_VERSION%%!'"${INHERIT_VERSION}"'!' \
                "${version}/${target}/Dockerfile"
        )
    done
done
