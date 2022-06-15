FROM nginx

ARG UID=1001
ARG GID=1001
ARG USER=app
RUN useradd ${USER} \
&& usermod -u $UID ${USER} \
&& groupmod -g $GID ${USER} \
&& mkdir -p /app \
&& chown -R ${USER}:${USER} /app

USER ${USER}

COPY --chown=$USER:$USER nginx.conf /etc/nginx/nginx.conf
COPY --chown=$USER:$USER index.html /app

WORKDIR /app

EXPOSE 8000

