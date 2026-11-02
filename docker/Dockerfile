FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server \
        vsftpd \
        nginx-light \
        python3 \
        openssl \
        zip \
        sudo \
        supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd /var/log/supervisor /var/run/vsftpd/empty

# Low-privilege account the player ultimately lands on via SSH.
RUN useradd -m -s /bin/bash jmiller

# nginx site root and vsftpd anonymous FTP root
RUN mkdir -p /var/www/html/files /srv/ftp && \
    chown -R www-data:www-data /var/www/html

COPY docker/web/ /var/www/html/
COPY docker/ftp/ /srv/ftp/

# vsftpd refuses to chroot anonymous users into a writable root; the root
# dir itself must not be writable by anyone. Content inside stays readable.
RUN chown root:root /srv/ftp && chmod 755 /srv/ftp
COPY docker/generate_flags.py /opt/generate_flags.py
COPY docker/entrypoint.sh /opt/entrypoint.sh
COPY docker/supervisord.conf /etc/supervisor/conf.d/ctf.conf
COPY docker/nginx-default.conf /etc/nginx/sites-available/default
COPY docker/vsftpd.conf /etc/vsftpd.conf

RUN chmod +x /opt/entrypoint.sh

EXPOSE 22 21 80 20000-20010

ENTRYPOINT ["/opt/entrypoint.sh"]
