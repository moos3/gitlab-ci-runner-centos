#!/bin/bash
############################################################

if [[ "$(id -u)" != "0" ]]; then 
	echo "Must be run as root!"
	exit 1
fi

REPO_DIR=$(pwd)

mkdir /tmp/ruby 
cd /tmp/ruby
curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p353.tar.gz | tar xz
cd ruby-2.0.0-p353
./configure --disable-install-rdoc
make
make install

mkdir /tmp/libyaml
cd /tmp/libyaml
curl --progress http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz | tar xz
cd yaml-0.1.4
./configure
make
make install

yum groupinstall "Development Tools"
yum install -y wget curl curl-devel libxml2-devel libxslt-devel readline-devel glibc-devel openssl-devel zlib-devel openssh-server git-core postfix postgresql-devel libicu-devel

gem install bundler
cd $REPO_DIR
bundle install

cp lib/support/init.d/gitlab_ci_runner /etc/init.d/gitlab-ci-runner
chmod +x /etc/init.d/gitlab-ci-runner
chkconfig --level 3 gitlab-ci-runner on

echo "You may now set up the runner:"
echo " bundle exec ./bin/setup"
echo ""
echo "Afterward, start the runner by becoming root and running:"
echo " service gitlab-ci-runner start"
