# Helix Core Server (p4d) from Perforce's official apt repository.
FROM ubuntu:22.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends wget gnupg ca-certificates \
 && wget -qO - https://package.perforce.com/perforce.pubkey \
      | gpg --dearmor -o /usr/share/keyrings/perforce.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/perforce.gpg] http://package.perforce.com/apt/ubuntu jammy release" \
      > /etc/apt/sources.list.d/perforce.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends helix-p4d helix-cli \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV P4ROOT=/p4/root \
    P4PORT=1666

EXPOSE 1666
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
