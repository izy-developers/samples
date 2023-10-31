FROM umputun/nginx-le:latest

ARG RAILS_ENV=production

RUN apk add curl

# Copy nginx congig
ADD conf/nginx.conf /etc/nginx/nginx.conf

# Copy service config
ADD etc/${RAILS_ENV}.nginx.conf /etc/nginx/conf.d/${RAILS_ENV}.conf
