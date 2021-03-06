#!/bin/bash

die(){ echo "$@" 1>&2; exit 1; }

base_url="http://distfiles.gentoo.org/releases/amd64/autobuilds"

latest_stage3=$(curl "${base_url}/latest-stage3-amd64.txt" 2>/dev/null | grep -v '#' | cut -f 1 -d ' ')
stage3=$(basename "${latest_stage3}")

[ ! -f "${stage3}" ] && xz=true || xz=false

if [ -z $(gpg --list-public-keys | grep -o 2D182910) ]; then
	gpg --keyserver keys.gnupg.net --recv-keys 0xBB572E0E2D182910
fi

wget -nc "${base_url}/${latest_stage3}" || die "Could not download stage3"
wget -nc "${base_url}/${latest_stage3}.DIGESTS.asc" || die "Could not download digests"
wget -nc "${base_url}/${latest_stage3}.CONTENTS" || die "Could not download contents"
sha512_digests=$(grep -A1 SHA512 "${stage3}.DIGESTS.asc" | grep -v '^--')
gpg --verify "${stage3}.DIGESTS.asc" || die "Insecure digests"
echo "${sha512_digests}" | sha512sum -c || die "Checksum validation failed"

if [ ${xz} == true ] || [ ! -f stage3-amd64.tar.xz ]; then
	echo "Transforming bz2 tarball to xz (golang bug). This will take some time..."
	bunzip2 -c "${stage3}" | xz -z > stage3-amd64.tar.xz || die "Failed to recompress to xz"
fi
echo "I'm done with the stage3."

echo "Building ngseasy Gentoo docker image now..."
docker build -t compbio/ngseasy-base-gentoo .
