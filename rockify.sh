#!/bin/bash
#
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/octomagon/rockify/main/rockify.sh)"

# Bail if not root
if [[ $EUID -ne 0 ]]; then echo "You must be root."; exit 1; fi

echo "This is dangerous! This script may break your OS."
read -p "Are you sure you wish to continue? (y,n): "
if [ "$REPLY" != "y" ]; then
   echo "You have chosen... wisely."
   exit
fi

ERR="/tmp/centos2rocky.err"
REPO_URL="https://dl.rockylinux.org/pub/rocky/8/BaseOS/x86_64/os/Packages/"

echo -n "Getting current Rocky version... "
ROCKY_RPMS=(`curl -s ${REPO_URL} | grep -e rocky-gpg-keys -e rocky-release -e rocky-repos | sed 's/.*>\(.*\)<.*/\1/g'`)

if [ "${#ROCKY_RPMS[@]}" -ne 3 ]; then
  echo "Couldn't get RPMs from Rocky."
  exit 1
fi

ROCKY_RPMS_TMP=`printf "/tmp/%s " ${ROCKY_RPMS[@]}`
echo "Done."

ROCKY_URLS=`printf "${REPO_URL}%s " ${ROCKY_RPMS[@]}`

echo -n "Installing wget, if needed... "
which wget &> /dev/null || dnf install wget -y 2> $ERR 1> /dev/null || { echo "Couldn't install wget." ; exit 1; }
echo "Done."

echo -n "Downloading Rocky RPMs... "
wget -P /tmp ${ROCKY_URLS} 2> $ERR 1> /dev/null || { echo 'Failed to download Rocky RPMs.' ; exit 1; }
echo "Done."

echo -n "Clearing dnf cache... "
rm -rf /var/cache/{yum,dnf} 2> $ERR 1> /dev/null || { echo 'Failed to delete dnf cache.' ; exit 1; }
echo "Done."

echo -n "Removing CentOS RPMs... "
rpm -e --nodeps centos-linux-repos centos-gpg-keys centos-linux-release 2> $ERR 1> /dev/null || { echo 'Failed to download Rocky RPMs.' ; exit 1; }
echo "Done."

echo -n "Installing Rocky RPMs... "
rpm -ihv ${ROCKY_RPMS_TMP} 2> $ERR 1> /dev/null || { echo 'Failed to install Rocky RPMs.' ; exit 1; }
echo "Done."

echo "Syncing distro... "
dnf distro-sync -y || { echo 'Failed to sync Rocky distro.' ; exit 1; }
echo -ne "\nNOTE: Out of an abundance of caution, only the minmal CentOS\n"
echo -ne "packages have been replaced.  Some packages may still be installed.\n"
echo -ne "Also, the old CentOS kernels will still show up in the grub menu.\n"
echo -ne "You may try to remove them manually, if you like.\n\n"
echo -ne "Finished! Converted to Rocky Linux!\n\n"

