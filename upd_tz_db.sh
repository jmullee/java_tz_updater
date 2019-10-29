#!bash

# this has been tested on debian/ubuntu type host with Java *8*
JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"

# uncompressed download file
TZDBF="tzdb-latest.tar"
# compressed download file
TZDBDL="${TZDBF}.lz"
# download url
URL="https://data.iana.org/time-zones/${TZDBDL}"
# the file theat needs regenerating from download, and replacing
TZDBDATFILE="${JAVA_HOME}/jre/lib/tzdb.dat"

# working directory
DIR="${HOME}/timezone"

function die() {
    echo "error: $@"
    exit 1
    }

## go to working directory
mkdir -p ${DIR}
cd ${DIR} || die "cant use directory ${DIR}"

## check there's a file to update
[ -f "${TZDBDATFILE}" ] || die "file-to-update doesn't exist: ${TZDBDATFILE}"

## if download file doesn't exist, create an old one to be updated
[ -f "${TZDBDL}" ] || {
    touch -d '1999-12-31' "${TZDBDL}"
    }

## get a newer one, if updated
touch -r "${TZDBDL}" .tmp || die "cant create tmpfile .tmp"
echo "update from ${URL}"
wget -N "${URL}"
## check if download has changed
[ "${TZDBDL}" -nt .tmp ] || {
    echo "no newer file to process; OK"
    rm .tmp
    exit 0
    }

## fail with error if there isn't a non-zero-sized download file
find . -maxdepth 1 -type f -name "${TZDBDL}" -not -size 0 || {
    die "failed to download file ${TZDBDL} from url ${URL}"
    }

## if downloaded new :
if [[ "${TZDBDL}" -nt "${TZDBF}" ]] ; then
    echo "decompressing downloaded ${TZDBDL} -> ${TZDBF}"
    # decompress and keep
    lzip -dc "${TZDBDL}" > "${TZDBF}"
fi

## check for downloaded file
[ -f "${TZDBF}" ] || {
    die "error: uncompressed file doesn't exist : ${TZDBF}"
    }

## find the name of unpacked dir
TZDIR=`tar -tf ${TZDBF} | grep -m 1 README | cut -d\/ -f 1`
echo "tarfile contains directory '${TZDIR}'"

## untar
tar -xf "${TZDBF}" || die "couldn't untar ${TZDBF}"
echo "untarred OK .."
[ -d "${TZDIR}" ] || die "can't find expected directory ${TZDIR}"

## go into unpack dir
(
    cd "${TZDIR}" || die "can't cd to directory ${TZDIR}"
    ## build the 'rearguard' tzdb
    [ -f "Makefile" ] || die "error no Makefile in unpacked dir"
    # the makefile assumes we're in a git repo, so oblige ..
    git init
    make rearguard_tarballs 2>&1 > make.log || die "make in unpacked dir failed"
    mv *.tar.gz ../  || die "couldn't move built tarball"
)

RGTZ=`find . -maxdepth 1 -type f -name \*\.tar\.gz -cnewer "${TZDBF}" -printf '%f'`
[ -f "${RGTZ}" ] || die "error no built tarball '${RGTZ}'"
echo "have tarball OK .."

## run the java timzone database updater
sudo ${JAVA_HOME}java -Djava.vendor="Oracle Corporation" \
    -jar "~/tzupdater.jar" -l "file://${PWD}/${RGTZ}" || \
    die "Failed: sudo java -jar ~/tzupdater.jar -l file://${PWD}/${RGTZ}"

#$ ls -lrt ${JAVA_HOME}/jre/lib/tz*
    # -rw-r--r-- 1 root root 107211 Jul 18 18:52 /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/tzdb.dat.tzdata2019a
    # -rw-r--r-- 1 root root 107579 Oct 29 12:23 /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/tzdb.dat
