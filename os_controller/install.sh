#apt-get update
#apt-get upgrade -y
#apt-get install python-software-properties -y
#add-apt-repository cloud-archive:havana
#
#apt-get update
#apt-get dist-upgrade -y
#apt-get upgrade -y
#
#export DEBIAN_FRONTEND=noninteractive
#
#apt-get install -y ntp python-mysqldb mysql-server rabbitmq-server python-novaclient python-neutronclient
#python-keystoneclient python-glanceclient python-swiftclient python-cinderclient python-heatclient
#python-ceilometerclient 
#
#mysqladmin -u root password MYSQL_PASS
#
#read -p "in the next file, change the bind-address to the IP of your controller. Enter to continue."
#
#nano /etc/mysql/my.cnf
#
#
#service mysql restart
#mysql_install_db
#mysql_secure_installation
#
#rabbitmqctl change_password guest RABBIT_PASS

echo "Installing Keystone"

apt-get install -y keystone
cp keystone/keystone.conf /etc/keystone/keystone.conf

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE keystone;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';"
keystone-manage db_sync

service keystone restart

export OS_SERVICE_TOKEN=ADMIN_TOKEN
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0

keystone tenant-create --name=admin --description="Admin Tenant"
keystone tenant-create --name=service --description="Service Tenant"
keystone user-create --name=admin --pass=ADMIN_PASS --email=admin@example.com
keystone role-create --name=admin
keystone user-role-add --user=admin --tenant=admin --role=admin

keystone service-create --name=keystone --type=identity --description="Keystone Identity Service"

echo "Please paste the service ID above here and press enter:"
read service_id

keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:5000/v2.0 \
      --internalurl=http://controller:5000/v2.0 \
        --adminurl=http://controller:35357/v2.0 

        unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
        export OS_USERNAME=admin
        export OS_PASSWORD=ADMIN_PASS
        export OS_TENANT_NAME=admin
        export OS_AUTH_URL=http://controller:35357/v2.0

echo "verify Keystone:"

source adminrc
keystone user-list

read -p "Keystone working, Enter to continue."




#Installs Glance
echo "Installing Glanceglance"
apt-get install -y glance python-glanceclient
cp glance/glance* /etc/glance
rm /var/lib/glance/glance.sqlite

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE glance;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';"

glance-manage db_sync

keystone user-create --name=glance --pass=GLANCE_PASS --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin
keystone service-create --name=glance --type=image --description="Glance Image Service"


echo "Please paste the service ID above here and press enter:"
read service_id

keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:9292 \
      --internalurl=http://controller:9292 \
        --adminurl=http://controller:9292

service glance-registry restart
service glance-api restart

mkdir ~/images
wget -P ~/images http://cdn.download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img

glance image-create --name="CirrOS 0.3.1" --disk-format=qcow2 \
  --container-format=bare --is-public=true < ~/images/cirros-0.3.1-x86_64-disk.img

glance image-list

read -p "Glance working, Enter to continue."




#Now install nova controller projects

apt-get install nova-novncproxy novnc nova-api \
  nova-ajax-console-proxy nova-cert nova-conductor \
    nova-consoleauth nova-doc nova-scheduler \
      python-novaclient

apt-get install nova-network nova-api-metadata

cp nova/nova.conf /etc/nova/
cp nova/api-paste.ini /etc/nova/

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE nova;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'glance'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'glance'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

nova-manage db sync

keystone user-create --name=nova --pass=NOVA_PASS --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin
keystone service-create --name=nova --type=compute \
  --description="Nova Compute service"
echo "Please paste the service ID above here and press enter:"
read service_id

keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:8774/v2/%\(tenant_id\)s \
      --internalurl=http://controller:8774/v2/%\(tenant_id\)s \
        --adminurl=http://controller:8774/v2/%\(tenant_id\)s

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-network restart

nova network-create vmnet --fixed-range-v4=10.0.0.0/24 \
  --bridge-interface=br100 --multi-host=T

nova image-list

read -p "nova controller working, Enter to continue."

#Dashboard
apt-get install memcached libapache2-mod-wsgi openstack-dashboard
apt-get remove --purge openstack-dashboard-ubuntu-theme
cp openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py

service apache2 restart
service memcached restart



#Block Storage

apt-get install cinder-api cinder-scheduler
cp cinder/cinder.conf /etc/cinder/cinder.conf
cp cinder/api-paste.conf /etc/cinder/api-paste.conf

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE cinder;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'CINDER_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';"

cinder-manage db sync
keystone user-create --name=cinder --pass=CINDER_PASS --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin

keystone service-create --name=cinder --type=volume \
  --description="Cinder Volume Service"
echo "Please paste the service ID above here and press enter:"
read service_id

keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:8776/v1/%\(tenant_id\)s \
      --internalurl=http://controller:8776/v1/%\(tenant_id\)s \
        --adminurl=http://controller:8776/v1/%\(tenant_id\)s

keystone service-create --name=cinderv2 --type=volumev2 \
  --description="Cinder Volume Service V2"
echo "Please paste the service ID above here and press enter:"
read service_id
keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:8776/v2/%\(tenant_id\)s \
      --internalurl=http://controller:8776/v2/%\(tenant_id\)s \
        --adminurl=http://controller:8776/v2/%\(tenant_id\)s

service cinder-scheduler restart
service cinder-api restart





# This is where I got to, at the end, should output all the passwords

echo "Your mysql password is: MYSQL_PASS"
echo "Your Rabbit MQ guest password is: RABBIT_PASS"


echo "Your Admin password is: ADMIN_PASS"





