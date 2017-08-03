#/bin/ash
stamp=`date +%Y%m%d%H%M`
opkg list-installed | tee opkg.list-installed.$stamp
cat opkg.list-installed.$stamp | sed 's/\ .*//' | \
while read -r pack; do opkg info "$pack" | tee -a opkg.info-installed.$stamp; done

