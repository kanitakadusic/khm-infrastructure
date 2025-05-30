#!/bin/bash

echo "Configuring ECS agent"
cat <<'EOF' | sudo tee /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance
EOF

echo "Installing Apache"
sudo yum update -y
sudo yum install -y epel-release
sudo yum install -y httpd mod_ssl mod_proxy mod_proxy_http openssl
sudo yum install -y certbot python3-certbot-apache

sudo mkdir -p /etc/pki/tls/certs
sudo mkdir -p /etc/pki/tls/private

sudo tee /etc/pki/tls/certs/apache-selfsigned.crt > /dev/null <<'EOCERT'
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
EOCERT

sudo tee /etc/pki/tls/private/apache-selfsigned.key > /dev/null <<'EOKEY'
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
EOKEY

PUBLIC_IP=$(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/public-ipv4 || echo "localhost")

sudo tee /etc/httpd/conf.d/redirect.conf > /dev/null <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html"
    Redirect "/" "https://$PUBLIC_IP/"
</VirtualHost>
EOF

sudo tee /etc/httpd/conf.d/ssl.conf > /dev/null <<EOF
Listen 443 https

<VirtualHost _default_:443>
    DocumentRoot "/var/www/html"
    ServerName $PUBLIC_IP

    ErrorLog /var/log/httpd/ssl_error_log
    TransferLog /var/log/httpd/ssl_access_log
    LogLevel warn

    SSLEngine on 
    SSLCertificateFile /etc/pki/tls/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/pki/tls/private/apache-selfsigned.key

    ProxyRequests Off
    ProxyPreserveHost On

    <Location />
        Require all granted
    </Location>

    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/

    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Port "443"
</VirtualHost>
EOF

sudo tee /etc/httpd/conf.modules.d/00-proxy.conf > /dev/null <<EOF
LoadModule proxy_module modules/mod_proxy.so
LoadModule lbmethod_bybusyness_module modules/mod_lbmethod_bybusyness.so
LoadModule lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so
LoadModule lbmethod_bytraffic_module modules/mod_lbmethod_bytraffic.so
LoadModule lbmethod_heartbeat_module modules/mod_lbmethod_heartbeat.so
LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
LoadModule proxy_connect_module modules/mod_proxy_connect.so
LoadModule proxy_express_module modules/mod_proxy_express.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
LoadModule proxy_fdpass_module modules/mod_proxy_fdpass.so
LoadModule proxy_ftp_module modules/mod_proxy_ftp.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_hcheck_module modules/mod_proxy_hcheck.so
LoadModule proxy_scgi_module modules/mod_proxy_scgi.so
LoadModule proxy_uwsgi_module modules/mod_proxy_uwsgi.so
LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule headers_module modules/mod_headers.so
LoadModule ssl_module modules/mod_ssl.so
EOF

systemctl restart httpd
systemctl enable httpd