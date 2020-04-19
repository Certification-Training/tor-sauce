#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [[ -d /var/lib/cloud/instance/ ]]; then
  until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
    sleep 1
  done
fi

sudo apt-get update

sudo apt-get --assume-yes install \
  apt-transport-https \
  lynx

repo='https://deb.torproject.org/torproject.org'
tor_list='/etc/apt/sources.list.d/tor.list'

sudo touch $tor_list
echo "deb $repo eoan main" | sudo tee --append $tor_list
echo "deb-src $repo eoan main" | sudo tee --append $tor_list

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

sudo mv --force /tmp/torrc /etc/tor/torrc
sudo service tor restart && sleep 5

onion_address=$(sudo cat /var/lib/tor/hidden_service/hostname)

sudo apt-get --assume-yes install apache2
sudo mkdir --parent /var/www/hidden_service/
sudo mkdir --parent /var/www/clearnet_service/

hidden_index='/var/www/hidden_service/index.html'
clearnet_index='/var/www/clearnet_service/index.html'

sudo touch /var/www/hidden_service/index.html
echo 'Welcome to the dark web' | sudo tee --append $hidden_index
echo 'Welcome to the clearnet' | sudo tee --append $clearnet_index

sudo chown --recursive www-data:www-data /var/www/
sudo chmod --recursive 755 /var/www

echo "ServerName $onion_address" | \
  sudo tee --append /etc/apache2/apache2.conf

sudo mv --force \
  /tmp/hidden_service.conf \
  /etc/apache2/sites-available/

sudo mv --force \
  /tmp/clearnet_service.conf \
  /etc/apache2/sites-available/

sudo sed \
  --in-place "s/ServerName/ServerName $onion_address/" \
  /etc/apache2/sites-available/hidden_service.conf

public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

sudo sed \
  --in-place "s/ServerName/ServerName $public_ip/" \
  /etc/apache2/sites-available/clearnet_service.conf

sudo a2ensite hidden_service
sudo a2ensite clearnet_service

sudo a2dissite 000-default.conf
sudo service apache2 restart