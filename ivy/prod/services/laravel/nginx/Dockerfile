FROM nginx:1.15-alpine

COPY ./laravel/Ivy/public /var/www/html/public
COPY ./laravel/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./laravel/nginx/default.conf.template /etc/nginx/conf.d/default.conf.template

ENV PHP_HOST=127.0.0.1

EXPOSE 80

CMD /bin/sh -c 'sed "s/\${PHP_HOST}/${PHP_HOST}/" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g "daemon off;"'
