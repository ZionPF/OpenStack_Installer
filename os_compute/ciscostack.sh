apt-get update
apt-get upgrade -y
apt-get install python-software-properties -y
add-apt-repository cloud-archive:havana

apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y

apt-get install cinder-volume lvm2 python-mysqldb nova-compute-kvm python-guestfs nova-network -y
chmod 0644 /boot/vmlinuz*



rm /var/lib/nova.sqlite
umount /dev/sdb
pvcreate /dev/sdb -ff
vgcreate cinder-volumes /dev/sdb

cp nova-api-paste.ini /etc/nova/api-paste.ini
cp nova.conf /etc/nova/.
cp lvm.conf /etc/lvm/.
cp cinder-api-paste.ini /etc/cinder/api-paste.ini
cp cinder.conf /etc/cinder/.

service nova-compute restart
service nova-network restart
service cinder-volume restart
service tgt restart
