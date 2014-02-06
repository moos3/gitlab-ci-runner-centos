# CentOS 6.5 Runner for Gitlab-CI

Forked from the official runner repository for Debian/Ubuntu systems, this one is tweaked to work with CentOS 6.5.

# Quickstart

We require:

* ruby 2.0.0
* libyaml (requires build)
* a bunch of CentOS libraries

By default, all of this is handled in the ```install.sh``` file, which will run as root.

__EXAMINE THAT FILE. IF YOU DONT LIKE HOW ITS DONE THERE, CHERRY-PICK THE PIECES YOU WANT. YOU HAVE BEEN WARNED.__

After the script runs, it will output the next steps to take to finish the installation.
