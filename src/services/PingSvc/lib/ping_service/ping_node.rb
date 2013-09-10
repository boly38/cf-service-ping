# Copyright (c) 2009-2011 VMware, Inc.
# This code is based on Redis as a Service.

require "erb"
require "fileutils"
require "logger"

require 'socket'

require "uuidtools"
require "thread"
require "curb"

require "nats/client"
require "warden/client"
require 'vcap/common'
require 'vcap/component'

require "ping_service/common"
require "ping_service/ping_error"

module VCAP
  module Services
    module Ping
      class Node < VCAP::Services::Base::Node
        class ProvisionedService < VCAP::Services::Base::Warden::Service
        end
      end
    end
  end
end

class VCAP::Services::Ping::Node
  include VCAP::Services::Ping
  include VCAP::Services::Ping::Common
  include VCAP::Services::Base::Utils
  include VCAP::Services::Base::Warden::NodeUtils

  def initialize(options)
    super(options)

    ProvisionedService.init(options)

    @base_dir = options[:base_dir]

    init_ports(options[:port_range])
    @service_start_timeout = options[:service_start_timeout] || 3

    @default_version = "1.0"
    @supported_versions = ["1.0"]
  end

  def migrate_saved_instances_on_startup
    @logger.info("Migrating saved instance on startup")
    ProvisionedService.all.each do |p_service|
      if p_service.version.to_s.empty?
        p_service.version = @default_version
        @logger.warn("Unable to set version for: #{p_service.inspect}") unless p_service.save
      end
    end
  end

  def pre_send_announcement
    @logger.info("pre_send_annoucement")
    migrate_saved_instances_on_startup
    start_provisioned_instances
    warden_node_init(@options)
  end

  def service_instances
    ProvisionedService.all
  end

  def start_provisioned_instances
    @logger.info("starting provisioned instances")
    start_all_instances
    @capacity_lock.synchronize{ @capacity -= ProvisionedService.all.size }
  end

  def shutdown
    super
    @logger.info("Shutting down instances..")
    stop_all_instances
    true
  end

  def announcement
    @capacity_lock.synchronize do
      { :available_capacity => @capacity, :capacity_unit => capacity_unit }
    end
  end

  def provision(plan, credentials = nil, version=nil)
    @logger.info("Provision request: plan=#{plan}, version=#{version}")
    raise ServiceError.new(ServiceError::UNSUPPORTED_VERSION, version) unless @supported_versions.include?(version)

    credentials = {} if credentials.nil?
    provision_options = {}
    provision_options["version"]  = version
    provision_options["name"]     = credentials["name"]     || UUIDTools::UUID.random_create.to_s
    provision_options["port"]     = new_port(credentials["port"] || nil)

    p_service = create_provisioned_instance(provision_options)

    @logger.info("Starting: #{p_service.inspect}")
    p_service.run

    response = get_credentials(p_service)
    @logger.debug("Provision response: #{response}")
    response
  rescue => e
     @logger.error("Error provisioning instance: #{e}")
     @logger.error("Stack trace: "+e.backtrace.join("\n"));

     p_service.delete unless p_service.nil?
     raise PingError.new(PingError::PING_START_INSTANCE_FAILED, e)
  end

  def create_provisioned_instance(provision_options)
    ProvisionedService.create(provision_options)
  end

  def unprovision(name, bindings = [])
    p_service = ProvisionedService.get(name)
    raise ServiceError.new(ServiceError::NOT_FOUND, name) if p_service.nil?
    port = p_service.port
    raise "Could not cleanup instance #{name}" unless p_service.delete
    free_port(port);

    @sasl_admin.delete_user(p_service.user) if @sasl_enabled

    @logger.info("Successfully fulfilled unprovision request: #{name}.")
    true
  end

  def bind(name, bind_opts = nil, credential = nil)
    p_service = ProvisionedService.get(name)
    raise ServiceError.new(ServiceError::NOT_FOUND, name) if p_service.nil?

    # Ping has no user level security, just return provisioned credentials.
    get_credentials(p_service)
  end

  def unbind(credentials)
    # Ping has no user level security, so has no operation for unbinding.
    {}
  end

  def restore(instance_id, backup_dir)
    # No restore command for ping
    {}
  end


  def get_credentials(p_service)
    host_ip = get_host
    credentials = {
      "name"     => p_service.name,
      "hostname" => host_ip,
      "host"     => host_ip,
      "port"     => p_service.port,
      "ping_url" => "http://#{host_ip}:#{p_service.port}/"
    }
  end

  def varz_details
    varz = super
    varz[:provisioned_instances_num] = 0
    varz[:max_instances_num] = @options[:capacity] / capacity_unit

    varz[:provisioned_instances] = ProvisionedService.all.map do |p_service|
      stat = {}
      stat['name']    = p_service.name
      stat['version'] = p_service.version
      stat['port']    = p_service.port

      varz[:provisioned_instances_num] += 1

      stat
    end
    varz
  rescue => e
    @logger.warn("Error while getting varz details: #{e}")
    {}
  end
end

class VCAP::Services::Ping::Node::ProvisionedService
  include DataMapper::Resource
  include VCAP::Services::Ping

  property :name,       String,      :key => true
  property :port,       Integer,     :unique => true
  property :version,    String,      :required => false

  property :container,  String
  property :ip,         String

  private_class_method :new

  SERVICE_PORT = 27017

  class << self
    def init(args)
      super(args)
      @@ping_timeout     = args[:ping_timeout] || 2
    end

    def create(args)
      logger.info "create service instance"
      raise "Parameter missing" unless args['port']
      p_service           = new
      p_service.name      = args['name']
      p_service.port      = args['port']
      p_service.version   = args['version']

      p_service.prepare_filesystem(1)
      p_service
    end
  end


  def bin_dir
    self.class.bin_dir["ping"]
  end

  def start_script
    cmd_components = [
      "#{service_script}",
      "start",
      "#{base_dir}",
      "#{log_dir}",
      "#{common_dir}",
      "#{bin_dir}",
      "#{SERVICE_PORT}"
    ]
    logger.info(cmd_components.join(" "))
    cmd_components.join(" ")
  end

  def start_options
    options = super
    options[:start_script] = {:script => start_script, :use_spawn => true}
    options[:service_port] = SERVICE_PORT
    options
  end

end
