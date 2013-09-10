# Copyright (c) 2009-2011 VMware, Inc.
# This code is based on Redis as a Service.

PWD = File.dirname(__FILE__)

$:.unshift File.join(PWD, '..')
$:.unshift File.join(PWD, '..', 'lib')

require "rubygems"
require "rspec"
require 'bundler/setup'
require "vcap_services_base"
require "socket"
require "timeout"
require "erb"
require "fileutils"

def get_connect_info(p_service)
  hostname = "#{p_service.ip}:#{VCAP::Services::Ping::Node::ProvisionedService::SERVICE_PORT}"
  username = p_service.user
  password = p_service.password

  return [hostname, username, password]
end

def parse_property(hash, key, type, options = {})
  obj = hash[key]
  if obj.nil?
    raise "Missing required option: #{key}" unless options[:optional]
    nil
  elsif type == Range
    raise "Invalid Range object: #{obj}" unless obj.kind_of?(Hash)
    first, last = obj["first"], obj["last"]
    raise "Invalid Range object: #{obj}" unless first.kind_of?(Integer) and last.kind_of?(Integer)
    Range.new(first, last)
  else
    raise "Invalid #{type} object: #{obj}" unless obj.kind_of?(type)
    obj
  end
end

def config_base_dir()
  File.join(PWD, "../config/")
end

def get_node_config()
  config_file = File.join(config_base_dir, "ping_node.yml")
  config = YAML.load_file(config_file)
  ping_conf_template = File.join(PWD, "../resources/ping.conf.erb")

  options = {
    # micellaneous configs
    :logger     => Logger.new(parse_property(config, "log_file", String, :optional => true) || STDOUT, "daily"),
    :plan       => parse_property(config, "plan", String),
    :capacity   => parse_property(config, "capacity", Integer),
    :node_id    => parse_property(config, "node_id", String),
    :port_range => parse_property(config, "port_range", Range),
    :mbus       => parse_property(config, "mbus", String),

    # parse ping wardenized-service control related config
    :service_bin_dir    => parse_property(config, "service_bin_dir", Hash),
    :service_common_dir => parse_property(config, "service_common_dir", String),

    #hardcode unit test related directories to /tmp dir
    :base_dir   => "/tmp/ping/instances",
    :service_log_dir => "/tmp/ping/ping_log",
    :max_clients => parse_property(config, "max_clients", Integer),
    :ping_memory => parse_property(config, "ping_memory", Integer),
    :local_db => 'sqlite3:/tmp/ping/ping_node.db',
    :local_db_file => "/tmp/ping/ping_node.db",
    :supported_versions => parse_property(config, "supported_versions", Array, :optional => true) || ["1.4"],
    :default_version => parse_property(config, "default_version", String, :optional => true) || "1.4"
  }
  options[:logger].level = Logger::DEBUG
  options
end
