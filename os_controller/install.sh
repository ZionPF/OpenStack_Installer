apt-get update
apt-get upgrade -y
apt-get install python-software-properties -y
add-apt-repository cloud-archive:havana

apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y

export DEBIAN_FRONTEND=noninteractive

apt-get install -y ntp python-mysqldb mysql-server rabbitmq-server keystone python-novaclient python-neutronclient
python-keystoneclient python-glanceclient python-swiftclient python-cinderclient python-heatclient
python-ceilometerclient glance

mysqladmin -u root password MYSQL_PASS

read -p "in the next file, change the bind-address to the IP of your controller. Enter to continue."

nano /etc/mysql/my.cnf


service mysql restart
mysql_install_db
mysql_secure_installation

rabbitmqctl change_password guest RABBIT_PASS

echo "Installing Keystone"

cp keystone.conf /etc/keystone/keystone.conf

mysql -u root -pMYSQL_PASS 'CREATE DATABASE keystone;'
mysql -u root -pMYSQL_PASS 'GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY
'KEYSTONE_DBPASS';'
mysql -u root -pMYSQL_PASS 'GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';'

keystone-manage db_sync

service keystone restart

export OS_SERVICE_TOKEN=RABBIT_PASS
export OS_SERVICE_TOKEN=http://controller:35357/v2.0

keystone tenant-create --name=admin --description="Admin Tenant"
keystone tenant-create --name=service --description="Service Tenant"
keystone user-create --name=admin --pass=ADMIN_PASS --email=admin@example.com
keystone role-create --name=admin
keystone user-role-add --user=admin --tenant=admin --role=admin

#Add the Keystone User, Tenant etc

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

#Installs Glance

cp glance-api.conf /etc/glance/glance-api.conf
cp glance-registry.conf /etc/glance/glance-registry.conf
cp glance-api-paste.ini /etc/glance/glance-api-paste.ini
cp glance-api-registry.ini /etc/glance/glance-api-registry.ini
rm /var/lib/glance/glance.sqlite

mysql -u root -pMYSQL_PASS 'CREATE DATABASE glance;'
mysql -u root -pMYSQL_PASS 'GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';'
mysql -u root -pMYSQL_PASS 'GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';'

glance-manage db_sync

keystone user-create --name=glance --pass=GLANCE_PASS --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin
keystone service-create --name=glance --type=image --description="Glance Image Service"


# This is where I got to, at the end, should output all the passwords

echo "Your mysql password is: MYSQL_PASS"
echo "Your Rabbit MQ guest password is: RABBIT_PASS"


echo "Your Admin password is: ADMIN_PASS"

'
'
'
'
