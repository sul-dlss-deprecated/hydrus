## Ubuntu Packages

If installing on Ubuntu, start with the following:

```bash
sudo apt-get install mysql-server curl wget gawk g++ libreadline6-dev zlib1g-dev libssl-dev libyaml-dev \
  libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison libffi-dev build-essential \
  libxml2 libxml2-dev libxslt libxslt-dev

# install Oracle java
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer

# Then after rvm install of ruby:
gem update debugger-ruby_core_source
```
