#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

sudo apt-get update

sudo apt-get --assume-yes install \
  apt-transport-https \
  lynx

repo='https://deb.torproject.org/torproject.org'

sudo echo -e "\ndeb $repo eoan main" >> /etc/apt/sources.list
sudo echo "deb-src $repo eoan main" >> /etc/apt/sources.list

tor_url='https://deb.torproject.org/torproject.org'
gpg_key='A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc'

wget --quiet \
  --output-document - \
  "${tor_url}/$gpg_key" | \
  gpg --import

gpg --export ${gpg_key%.asc} | sudo apt-key add -

sudo apt-get update
sudo apt-get --assume-yes install \
  tor deb.torproject.org-keyring

sudo mv --force /home/vagrant/torrc /etc/tor/torrc
sudo service tor restart && sleep 5

onion_address=$(sudo cat /var/lib/tor/hidden_service/hostname)

sudo apt-get --assume-yes install apache2
sudo mkdir --parent /var/www/hidden_service/
sudo mkdir --parent /var/www/clearnet_service/

sudo echo 'Welcome to the dark web' >> /var/www/hidden_service/index.html
sudo echo 'Welcome to the clearnet' >> /var/www/clearnet_service/index.html

sudo chown --recursive www-data:www-data /var/www/
sudo chmod --recursive 755 /var/www

sudo sed \
  --in-place 's/Listen 80/Listen 127.0.0.1:80/' \
  /etc/apache2/ports.conf

sudo echo "ServerName $onion_address" >> /etc/apache2/apache2.conf

sudo mv --force \
  /home/vagrant/hidden_service.conf \
  /etc/apache2/sites-available/

sudo mv --force \
  /home/vagrant/clearnet_service.conf \
  /etc/apache2/sites-available/

sudo sed \
  --in-place "s/ServerName/ServerName $onion_address/" \
  /etc/apache2/sites-available/hidden_service.conf

sudo a2ensite hidden_service
sudo a2ensite clearnet_service

sudo a2dissite 000-default.conf
sudo service apache2 restart