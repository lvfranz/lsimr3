#!/bin/bash
# Script to build LSIMR3 VIB using VIB Author (can use with lamw/vibauthor Docker Container)

LSIMR3_REPO=https://github.com/lvfranz/lsimr3.git
LSIMR3_REPO_DIR=lsimr3
LSIMR3_TEMP_DIR=/tmp/lsimr3-$$

# Ensure git is installed
git version > /dev/null 2>&1
if [ $? -eq 1 ]; then
	echo "Git not installed, exiting ..."
	exit 1
fi

# Ensure vibauthor is installed
vibauthor --version > /dev/null 2>&1
if [ $? -eq 1 ]; then
	echo "vibauthor not installed, exiting ..."
	exit 1
fi

# Ensure no existing LSIMR3 repo exists
if [ -e ${LSIMR3_REPO_DIR} ]; then
	rm -rf ${LSIMR3_REPO_DIR}
fi

# Clone LSIMR3 repo
git clone ${LSIMR3_REPO}
cd ${LSIMR3_REPO_DIR}
LSIMR3_DATE=$(date --date="$(git log -n1 --format="%cd" --date="iso")" '+%Y-%m-%dT%H:%I:%S')
LSIMR3_COMMIT_HASH=$(git log -n1 --format="%H")
cd /root

### Create ESXi 8.x Compatiable VIB
LSIMR3_VIB_NAME=lsimr3-mod-8x.vib
LSIMR3_OFFLINE_BUNDLE_NAME=lsimr3-mod-offline-bundle-8x.zip

# Setting up VIB spec confs
VIB_DESC_FILE=${LSIMR3_TEMP_DIR}/descriptor.xml
VIB_PAYLOAD_DIR=${LSIMR3_TEMP_DIR}/payloads/payload1

# Create LSIMR3 temp dir
mkdir -p ${LSIMR3_TEMP_DIR}
# Create VIB spec payload directory
mkdir -p ${VIB_PAYLOAD_DIR}


mkdir -p ${VIB_PAYLOAD_DIR}/etc/vmware/default.map.d
mkdir -p ${VIB_PAYLOAD_DIR}/usr/lib/vmware/vmkmod
mkdir -p ${VIB_PAYLOAD_DIR}/usr/share/hwdata/default.pciids.d



# Copy LSIMR3 files to bin/conf directories
cp ${LSIMR3_REPO_DIR}/lsi_mr3.map ${VIB_PAYLOAD_DIR}/etc/vmware/default.map.d
cp ${LSIMR3_REPO_DIR}/lsi_mr3 ${VIB_PAYLOAD_DIR}/usr/lib/vmware/vmkmod
cp ${LSIMR3_REPO_DIR}/lsi_mr3.ids ${VIB_PAYLOAD_DIR}/usr/share/hwdata/default.pciids.d
cp ${LSIMR3_REPO_DIR}/descriptor.xml ${LSIMR3_TEMP_DIR}
cp ${LSIMR3_REPO_DIR}/sig.pkcs7 ${LSIMR3_TEMP_DIR}


# Create tgz with payload
tar czf ${LSIMR3_TEMP_DIR}/payload1 -C ${VIB_PAYLOAD_DIR} opt

# Calculate payload size/hash
PAYLOAD_FILES=$(tar tf ${LSIMR3_TEMP_DIR}/payload1 | grep -v -E '/$' | sed -e 's/^/    <file>/' -e 's/$/<\/file>/')
PAYLOAD_SIZE=$(stat -c %s ${LSIMR3_TEMP_DIR}/payload1)
PAYLOAD_SHA256=$(sha256sum ${LSIMR3_TEMP_DIR}/payload1 | awk '{print $1}')
PAYLOAD_SHA256_ZCAT=$(zcat ${LSIMR3_TEMP_DIR}/payload1 | sha256sum | awk '{print $1}')
PAYLOAD_SHA1_ZCAT=$(zcat ${LSIMR3_TEMP_DIR}/payload1 | sha1sum | awk '{print $1}')



# Create VIB using ar
touch ${LSIMR_TEMP_DIR}/sig.pkcs7
ar r ${LSIMR3_VIB_NAME} ${LSIMR3_TEMP_DIR}/descriptor.xml ${LSIMR3_TEMP_DIR}/sig.pkcs7 ${LSIMR3_TEMP_DIR}/payload1

# Create offline bundle
PYTHONPATH=/opt/vmware/vibtools-6.0.0-847598/bin python -c "import vibauthorImpl; vibauthorImpl.CreateOfflineBundle(\"${LSIMR3_VIB_NAME}\", \"${LSIMR3_OFFLINE_BUNDLE_NAME}\", True)"

# Show details of VIB that was just created
vibauthor -i -v ${LSIMR3_VIB_NAME}

# Remove LSIMR3 temp dir
rm -rf ${LSIMR3_TEMP_DIR}

