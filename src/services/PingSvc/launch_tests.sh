#!/bin/bash
VAR_VCAP=/var/vcap
BIN_DIR=$VAR_VCAP/store/ping_common/bin
SYSLOG_DIR=$VAR_VCAP/sys/log/monit/
RUBY_VERSION_1_9=`ruby -v|grep 1.9|wc -l`
NATS_LISTEN=`netstat -a|grep -i LISTEN|grep 4222|wc -l`
if [ $RUBY_VERSION_1_9 == "0" ] ; then
  echo "please use ruby version 1.9.x (eg. rvm use 1.9.3)"
  exit 1
fi 
if [ ! -e /tmp/warden.sock ] ; then
  echo "please start warden (eg. ../start-warden.sh)"
  exit 1
fi
if [ $NATS_LISTEN == "0" ] ; then
  echo "starting nats-server"
  exec nats-server &
fi
echo "assert tests dirs"
mkdir -p $VAR_VCAP/packages/ping
mkdir -p $BIN_DIR
mkdir -p $SYSLOG_DIR
echo "launch tests"
rspec spec/node_spec.rb  --format documentation --color

exec pkill -f nats-server
