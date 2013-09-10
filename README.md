cf-service-ping
===============

##Goal of this repository
Aim of this repository is to provide a small simple cloudfoundry (v2) service called "ping" :
- describe the minimal requirements to (un)provision a Ping as a Service
- describe ping_node and ping_gateway
- ping_node use warden container


Parent repositories : 
- [cloudfoundry/cf-services-release] (https://github.com/cloudfoundry/cf-services-release)
- [cloudfoundry/cf-services-contrib-release] (https://github.com/cloudfoundry/cf-services-contrib-release)

##Ping Service installation

<pre>
 echo "---" > config/dev.yml
 echo "dev_name: cf-service-ping" > config/dev.yml
 bosh create release --force
 bosh -n upload release
</pre>

- copy <code>examples/ping.yml</code> into your bosh workspace and adapt #TOCHANGE lines
- update ping.yml (set the last release version of "cf-service-ping")

<pre>
 bosh deployment ping.yml
 bosh deploy
</pre>

##Target ping_node vm

Jobs to monitor are defined into <code>/var/vcap/ping_node_ng/monit<code>
- <code>monit</code> start "warden" (then "warden" dependencies could be started)
- <code>monit</code> start "ping_node"
- <code>ping_node</code> start "warden_service_ctl" then the "ping_node" bin

##Target ping_node logs

<pre>
  tail -20 /var/vcap/monit/monit.log
  tail -5  /var/vcap/data/sys/log/warden/warden.log
  tail -20 /var/vcap/data/sys/log/warden/warden.stdout.log
  tail -20 /var/vcap/data/sys/log/warden/warden.stderr.log
  tail -20 /var/vcap/data/sys/log/monit/ping_node_ctl.log
  tail -20 /var/vcap/data/sys/log/monit/ping_node_ctl.err.log
  tail -20 /var/vcap/data/sys/log/ping_node/ping_node.stderr.log
  tail -20 /var/vcap/data/sys/log/ping_node/ping_node.log
  tail -20 /var/vcap/data/sys/log/ping_node/ping_node.stdout.log
</pre>

##Target ping_gateway logs

<pre>
   tail -20 /var/vcap/data/sys/log/monit/ping_gateway_ctl.log
   tail -20 /var/vcap/data/sys/log/monit/ping_gateway_ctl.err.log
   tail -20 /var/vcap/data/sys/log/ping_gateway/ping_gateway.stderr.log
   tail -20 /var/vcap/data/sys/log/ping_gateway/ping_gateway.log
</pre>

##Source configuration

### Ping source

- <code>src/service/PingSvc</code> : cloudfoundry ping service source code : bin, node, gateway, and rspec (tests : to do)
 
- <code>src/services/PingSvc/lib/ping_node.rb</code>

    <code>VCAP::Services::Ping::Node</code> class 
      wich extends <code>VCAP::Services::Base::Node</code> with the following functions : provision, unprovision, bind, unbind, announcement, (actions)_instance

    <code>VCAP::Services::Ping::Node::ProvisionedService</code> class : a provisioned service instance definition
      wich extends <code>VCAP::Services::Base::Warden::Service</code>
      with the following functions : start_script, start_options, finish_start? finish_first_start? ...

- <code>src/ping_src</code> : ping minimal ruby server


### Bosh source

- <code>config</code>
- <code>jobs/*</code> : ping_node_ng, ping_gateway
- <code>packages/*</code> : ping dependencies (referenced by "jobs/X/spec" files)
- <code>packages/ping_node_ng/spec</code> : ping_node_ng package definition giving source files to include into a ping node (ex. src/ping_src)


###Unhandled source

The following files or directories have been duplicated from  [cf-services-contrib-release](https://github.com/cloudfoundry/cf-services-contrib-release/) and are not maintained into this repository.
- <code>packages</code> : common, libyaml, node,root_lucid64, ruby, ruby_next, sqlite, syslog_aggregator
- <code>src</code> : common, pkg_utils, syslog_aggregator, services_warden


###Stay to do
- fix tests 
- write a readme on how to execute isolated tests (usin rspec, nats & warden shell)
