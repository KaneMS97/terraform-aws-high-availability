#!/bin/bash
apt-get update
apt-get install -y apache2
systemctl enable --now apache2
echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html