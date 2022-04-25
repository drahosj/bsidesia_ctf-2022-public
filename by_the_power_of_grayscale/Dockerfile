FROM nginx
COPY src/html.tgz /usr/share/nginx/
RUN tar -xaf /usr/share/nginx/html.tgz -C /usr/share/nginx/
COPY src/default.conf /etc/nginx/conf.d/default.conf
COPY src/launch.sh /usr/share/nginx/
EXPOSE 80
ENTRYPOINT /usr/share/nginx/launch.sh
