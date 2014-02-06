# gitlab-ci-runner

FROM centos:6.5
MAINTAINER Myles Hathcock "myleshathcock@gmail.com"

# This script will start a runner in a docker container.
#
# First build the container and give a name to the resulting image:
# docker build -t gitlabhq/gitlab-ci-runner github.com/gitlabhq/gitlab-ci-runner
#
# Then set the environment variables and run the gitlab-ci-runner in the container:
# docker run -e CI_SERVER_URL=https://ci.example.com -e REGISTRATION_TOKEN=replaceme -e HOME=/root -e GITLAB_SERVER_FQDN=gitlab.example.com gitlabhq/gitlab-ci-runner
#
# After you start the runner you can send it to the background with ctrl-z
# The new runner should show up in the GitLab CI interface on /runners
#
# You can tart an interactive session to test new commands with:
# docker run -e CI_SERVER_URL=https://ci.example.com -e REGISTRATION_TOKEN=replaceme -e HOME=/root -i -t gitlabhq/gitlab-ci-runner:latest /bin/bash
#
# If you ever want to freshly rebuild the runner please use:
# docker build -no-cache -t gitlabhq/gitlab-ci-runner github.com/gitlabhq/gitlab-ci-runner

# Update your packages and install the ones that are needed to compile Ruby

RUN yum update -y
RUN yum groupinstall "Development Tools"
RUN yum install -y wget curl curl-devel libxml2-devel libxslt-devel readline-devel glibc-devel openssl-devel zlib-devel openssh-server git-core postfix postgresql-devel libicu-devel libqt4-webkit libqt4-devel libsqlite3-devel libmysqlclient-devel

# Download Ruby and compile it
RUN mkdir /tmp/ruby && cd /tmp/ruby && curl --progress http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz | tar xz
RUN cd /tmp/ruby/ruby-1.9.3-p392 && ./configure --disable-install-rdoc && make && make install

# Install mysql server with blank root password
RUN yum install -y -q mysql-server
RUN cd /root && wget http://download.redis.io/redis-stable.tar.gz && tar xvzf redis-stable.tar.gz && cd redis-stable && make

# Set the right locale for Postgres
RUN echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# Install PostgreSQL, after install this should work: psql --host=127.0.0.1 roottestdb
RUN yum install -y postgresql
RUN cat /dev/null > /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "# TYPE DATABASE USER ADDRESS METHOD" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "local  all  all  trust" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "host all all 127.0.0.1/32 trust" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN echo "host all all  ::1/128 trust" >> /etc/postgresql/9.1/main/pg_hba.conf
RUN /etc/init.d/postgresql start && su postgres -c "psql -c \"create user root;\"" && su postgres -c "psql -c \"alter user root createdb;\"" && su postgres -c "psql -c \"create database roottestdb owner root;\""

# Prepare a known host file for non-interactive ssh connections
RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/known_hosts

# Install the runner
RUN git clone https://github.com/darthmuffins/gitlab-ci-runner-centos.git /gitlab-ci-runner-centos

# Install the gems for the runner
RUN cd /gitlab-ci-runner-centos && gem install bundler && bundle install

# When the image is started add the remote server key, unstall the runner and run it
WORKDIR /gitlab-ci-runner-centos
CMD ssh-keyscan -H $GITLAB_SERVER_FQDN >> /root/.ssh/known_hosts && mysqld & /root/redis-stable/src/redis-server & /etc/init.d/postgresql start & bundle exec ./bin/setup_and_run
