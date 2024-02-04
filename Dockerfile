FROM ubuntu:jammy AS build

# We do not want to have prompts
ARG DEBIAN_FRONTEND=noninteractive

# For getting the right author information, overrided from host
ARG DEBFULLNAME="Foo Bar"
ARG DEBEMAIL="foo.bar@acme.com"
ARG GPGPASSPHRASE="passkey"

# Enable source repositories
RUN cp /etc/apt/sources.list /etc/apt/sources.list.old

# Install required tools and sources for cowsay package
RUN sed -e "s/# deb-src/deb-src/" /etc/apt/sources.list.old > /etc/apt/sources.list && \
    apt-get update && apt-get build-dep -y cowsay && \
    apt install -y devscripts dialog apt-utils vim gpg

WORKDIR /tmp
RUN apt-get source cowsay

# Generate, export and display keypair 
RUN bash -c 'echo -e "Key-Type: 1\n\
    Key-Length: 4096\n\
    Subkey-Type: 1a\n\
    Subkey-Length: 4096\n\
    Name-Real: $DEBFULLNAME\n\
    Name-Email: $DEBEMAIL\n\
    Expire-Date: 0\n\
    Passphrase: $GPGPASSPHRASE"'| gpg --gen-key --batch
RUN gpg --export-secret-key --output private-key.gpg --pinentry-mode=loopback --passphrase $GPGPASSPHRASE && \
    gpg --export --output public-key.gpg && \
    gpg --export-ownertrust > ownertrust-key.txt && \
    gpg --armor --export && \
    gpg --armor --export-secret-key --pinentry-mode=loopback --passphrase $GPGPASSPHRASE && \
    gpg --fingerprint

# Modify package to add the new script
RUN cd /tmp/cowsay-* && \
    bash -c 'echo -e "#!/bin/sh\necho \"\\\033[31mthis is a test from Disk91\\\033[0m\" >&2" > testing.sh' && \
    chmod +x testing.sh && \
    bash -c 'echo -e "testing.sh /usr/bin" >> debian/install'

# Modify the post installation phase 
RUN cd /tmp/cowsay-* && \
    bash -c 'echo -e "#!/bin/sh\ntesting.sh" > debian/postinst'

# Create the new package
RUN cd /tmp/cowsay-* && \
    version=`cat debian/changelog | grep cowsay | head -1 | sed -e 's/^.*(\(.*\)).*$/\1/'` && \
    debchange -v ${version}ppa1 "Add a postinstall script for demo" && \
    debchange -r "" && \
    head -10 debian/changelog && \
    echo "disk91 patch exemple" | EDITOR=/bin/true dpkg-source -q --commit && \
    debuild -p"gpg --batch --passphrase $GPGPASSPHRASE --pinentry-mode loopback"

# Demo the package installation 
RUN apt install -y ./cowsay_*_all.deb
RUN dpkg -S testing.sh; testing.sh

# Build source for ppa
RUN rm cowsay_*[!zb]
RUN cd /tmp/cowsay-* && \
    debuild -S -sd -p"gpg --batch --passphrase $GPGPASSPHRASE --pinentry-mode loopback"

# Export the build package to host machine
FROM scratch AS final
COPY --from=build /tmp/cowsay_* /
COPY --from=build /tmp/public-key.gpg /
COPY --from=build /tmp/private-key.gpg /
COPY --from=build /tmp/ownertrust-key.txt /
