#!/bin/bash

clear


### Configuration

# Magento
magentoDatabase="db_magento"
magentoDatabaseUser="usr_magento"
magentoDatabasePassword="magento"
magentoAdminPassword="magento"
magentoURL="localhost/"

# Other
mysqlRootPassword=webvuln
apacheDir=/var/www
scriptTmpFolder=~/tmp_webvulnTargets


### Create temporary directory for downloads etc.
mkdir -p $scriptTmpFolder

### Install dependencies
# Install MySQL server and client
type mysql >/dev/null 2>&1 && \
	echo "" \
	echo "MySQL already installed" || \
	echo "" \
	echo "MySQL installing..." \
	echo "" \
	sudo DEBIAN_FRONTEND=noninteractive apt-get -qq --force-yes install mysql-server mysql-client > /dev/null \
	mysqladmin -u root password $mysqlRootPassword

# Install Apache2
echo ""
echo "Installing Apache2 and PHP5..."
sudo DEBIAN_FRONTEND=noninteractive apt-get --force-yes -y install apache2 php5 libapache2-mod-php5 php5-mysql php5-curl php5-gd php-pear php5-imagick php5-memcache php5-ming > /home/user/test123 #dev/null
sudo chown -R $USER:users /var/www 
echo "------restarting Apache2"
sudo /etc/init.d/apache2 restart

# get Magento and sample data
echo ""
echo "Downloading Magento with sample data"
cd $scriptTmpFolder
#wget http://www.magentocommerce.com/downloads/assets/1.7.0.2/magento-1.7.0.2.tar.gz 
#wget http://www.magentocommerce.com/downloads/assets/1.6.1.0/magento-sample-data-1.6.1.0.tar.gz 

echo "--- extracting files..."
#tar zxf magento-1.7.0.2.tar.gz -C $apacheDir > /dev/null
#tar xvfz magento-sample-data-1.6.1.0.tar.gz > /dev/null

echo "--- creating database and user"
SQL1="CREATE DATABASE IF NOT EXISTS $magentoDatabase;"
SQL2="GRANT ALL PRIVILEGES ON "$magentoDatabase".* TO '$magentoDatabaseUser'@'localhost' IDENTIFIED BY '$magentoDatabasePassword';"
SQL3="FLUSH PRIVILEGES;"
mysql -uroot -p$mysqlRootPassword -e "${SQL1}${SQL2}${SQL3}"

echo "--- importing sample data"
cd $scriptTmpFolder/magento-sample-data-1.6.1.0
mysql -h localhost -u$magentoDatabaseUser -p$magentoDatabasePassword $magentoDatabase < magento_sample_data_for_1.6.1.0.sql
mv media/* $apacheDir/magento/media/

echo "--- setting permissions"
cd $apacheDir/magento
chmod 550 mage

echo "--- preparing installation"
./mage mage-setup .
./mage config-set preferred_state stable
./mage install http://connect20.magentocommerce.com/community Mage_All_Latest --force
/usr/local/bin/php -f shell/indexer.php reindexall

echo "--- installing magneto"
php-cli -f install.php -- \
    --license_agreement_accepted "yes" \
    --locale "en_US" \
    --timezone "America/Phoenix" \
    --default_currency "USD" \
    --db_host "localhost" \
    --db_name "$DBNAME" \
    --db_user "$DBUSER" \
    --db_pass "$DBPASS" \
    --url "$URL" \
    --use_rewrites "yes" \
    --use_secure "no" \
    --secure_base_url "" \
    --use_secure_admin "no" \
    --admin_firstname "Store" \
    --admin_lastname "Owner" \
    --admin_email "email@address.com" \
    --admin_username "admin" \
    --admin_password "$ADMIN_PASS"


#cd ~
#mkdir -p Downloads
#cd Downloads

# Use magento downloader to get the latest magento release
#filename=magento-downloader-1.7.0.0.tar.gz
#wget http://www.magentocommerce.com/downloads/assets/1.7.0.0/$filename -o /dev/null

#tar -xvfz $filename -C $apacheDir/$filename
#cd $filename
