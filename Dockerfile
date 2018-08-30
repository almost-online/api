FROM python:3.5-alpine
FROM nginx:1.10

RUN apt-get clean && apt-get update && apt-get install -y nano spawn-fcgi fcgiwrap wget curl

RUN sed -i 's/www-data/nginx/g' /etc/init.d/fcgiwrap
RUN chown nginx:nginx /etc/init.d/fcgiwrap
ADD ./vhost.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www

wget -O /tmp/citrusleaf_client_swig_2.1.34.tgz 'https://www.aerospike.com/artifacts/aerospike-client-swig/2.1.34/citrusleaf_client_swig_2.1.34.tgz'
tar zxf /tmp/citrusleaf_client_swig_2.1.34.tgz /tmp/
cd /tmp/citrusleaf_client_swig_2.1.34
apt-get install libgnome2-perl -y

CMD ["/etc/init.d/fcgiwrap start && nginx -g 'daemon off;'", "/usr/bin/asd --foreground --config-file /opt/aerospike/etc/aerospike.conf"]
