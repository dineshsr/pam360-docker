FROM ubuntu:latest
ENV user pamuser
ENV password Test@123
EXPOSE 3456/tcp 8282/tcp 22/tcp 23/tcp 389/tcp 636/tcp 25/tcp 1443/tcp 1521/tcp 5000/tcp 135/tcp 139/tcp 445/tcp 6622/tcp 8283/tcp
RUN useradd -m -d /home/${user} ${user} && chown -R ${user} /home/${user}
RUN apt-get -y update && apt-get install iputils-ping sudo nano unzip -y
RUN usermod -aG sudo ${user}
COPY file/ManageEngine_PAM360_64bit.bin /home/${user}/
COPY file/install.txt /home/${user}/
RUN chmod 755 /home/${user}/ManageEngine_PAM360_64bit.bin
RUN echo "${user}:${password}" | chpasswd
USER ${user}
WORKDIR /home/${user}
RUN ./ManageEngine_PAM360_64bit.bin -i silent -f install.txt
RUN rm ./ManageEngine_PAM360_64bit.bin
RUN rm ./install.txt
WORKDIR /home/${user}
CMD tail -f /dev/null