cf-service-ping
===============

##Goal of this repository
Aim of this repository is to provide a small simple cloudfoundry service called "ping" :
- describe the minimal requirements to (un)provision a Ping as a Service
- describe ping_node and ping_gateway
- ping_node use warden container


##Service installation

- bosh create release --force
- bosh -n upload release
- update ping.yml (set the last release version)
- bosh deployment ping.yml
- bosh deploy

##Target ping_node vm

Jobs to monitor are defined into <code>/var/vcap/ping_node_ng/monit<code>
- "monit" start "warden" (then "warden" dependencies could be started)
- "monit" start "ping_node"
- "ping_node" start "warden_servic_ctl" then the "ping_node" bin

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

- src/service/PingSvc : cloudfoundry ping service source code : bin, node, gateway, and rspec (tests : to do)
 
- src/services/PingSvc/lib/ping_node.rb

    <code>VCAP::Services::Ping::Node</code> class 
      wich extends <code>VCAP::Services::Base::Node</code> with the following functions : provision, unprovision, bind, unbind, announcement, (actions)_instance

    <code>VCAP::Services::Ping::Node::ProvisionedService</code> class : a provisioned service instance definition
      wich extends <code>VCAP::Services::Base::Warden::Service</code>
      with the following functions : start_script, start_options, finish_start? finish_first_start? ...

- src/ping_src : ping minimal ruby server


### Bosh source

- config
- jobs/* : ping_node_ng, ping_gateway
- packages/* : ping dependencies (referenced by "jobs/X/spec" files)
- packages/ping_node_ng/spec : ping_node_ng package definition giving source files to include into a ping node (ex. src/ping_src)


###Unhandled source

The following files or directories are not maintained into this repository _cf. [cf-services-contrib-release](https://github.com/cloudfoundry/cf-services-contrib-release/)_

- packages : common, libyaml, node,root_lucid64, ruby, ruby_next, sqlite, syslog_aggregator
- src : common, pkg_utils, syslog_aggregator, services_warden

