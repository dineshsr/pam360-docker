FROM ubuntu:latest

 

RUN        apt-get update

RUN        apt-get install -y unzip

COPY       ManageEngine_PMP_64bit.bin .

COPY       inst.txt .

RUN        ./ManageEngine_PMP_64bit.bin -i silent -f inst.txt

 

RUN        cd /opt/PMP/bin; /bin/bash ./pmp.sh install

ENTRYPOINT ["/etc/init.d/pmp-service", "console"]

 

EXPOSE 72