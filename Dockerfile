FROM alpine:latest

RUN apk update && apk add --no-cache bash openssh openssh-client

RUN adduser -D -s /bin/bash ssh && echo "ssh:TestUser123" | chpasswd

RUN mkdir -p /home/ssh/.ssh /var/run/sshd && \
    chmod 700 /home/ssh/.ssh && \
    chown -R ssh:ssh /home/ssh/.ssh

COPY id_rsa /home/ssh/.ssh/id_rsa
RUN chmod 600 /home/ssh/.ssh/id_rsa && \
    chown ssh:ssh /home/ssh/.ssh/id_rsa

RUN echo 'echo "Connecting to jump target..." ' > /home/ssh/.bashrc && \
    echo 'ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa root@192.168.0.34 -p 3050' >> /home/ssh/.bashrc && \
    echo 'exit' >> /home/ssh/.bashrc && \
    # Create .bash_profile to ensure .bashrc is loaded on login
    echo '[[ -f ~/.bashrc ]] && . ~/.bashrc' > /home/ssh/.bash_profile && \
    chown ssh:ssh /home/ssh/.bashrc /home/ssh/.bash_profile

RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "AllowUsers ssh" >> /etc/ssh/sshd_config

RUN truncate -s 0 /etc/motd

RUN ssh-keygen -A

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]

