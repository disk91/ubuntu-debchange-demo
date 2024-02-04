This Dockerfile demo how a deb package can be modified to add a message on installation and a new script to be installed.

It generate a binary and test it during the build, it signs the build with a locally generated key and export at the end the 
source package and the generated keys for being published on PPA.

It requires docker 25.0.2+ for getting generated file export. To use that script use the following command:
```
$ sudo docker build --progress=plain 
              --build-arg="DEBFULLNAME=<your name>"
              --build-arg="DEBEMAIL=<your email>"
              --build-arg="GPGPASSPHRASE=<your keyphrase>"
              --output=out -t debpatch .
…
#12 1.681 Unpacking cowsay (3.03+dfsg2-8ppa1) ...
#12 1.702 Setting up libtext-charwidth-perl (0.04-10build3) ...
#12 1.707 Setting up cowsay (3.03+dfsg2-8ppa1) ...
#12 1.712 this is a test from Disk91
#12 1.716 Processing triggers for man-db (2.10.2-1) ...
#12 DONE 1.8s
#13 [build 10/10] RUN dpkg -S testing.sh; testing.sh
#13 0.282 cowsay: /usr/bin/testing.sh
#13 0.284 this is a test from Disk91
#13 DONE 0.3s
#14 [final 1/1] COPY --from=build /tmp/cowsay_*_all.deb /
…
```
Generated files will be in directory _out_
