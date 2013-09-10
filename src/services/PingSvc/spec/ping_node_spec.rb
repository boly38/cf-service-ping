# Copyright (c) 2009-2011 VMware, Inc.
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

require 'ping_service/ping_node'

module VCAP
  module Services
    module Ping
      class Node

      end
    end
  end
end

module VCAP
  module Services
    module Ping
      class PingError
        attr_reader :error_code
      end
    end
  end
end

module VCAP::Services::Ping
  describe "Ping service node" do
    before :all do
      @opts = get_node_test_config
      @opts.freeze
      @logger = @opts[:logger]
      # Setup code must be wrapped in EM.run
      EM.run do
        @node = Node.new(@opts)
        EM.add_timer(1) { EM.stop }
      end
    end

    before :each do
      @default_plan = "free"
      @default_opts = "default"
      @pinger = @node.provision(@default_plan)
      @pinger.should_not == nil
    end

    it "should provison a ping service with correct credential" do
      EM.run do
        @pinger.should be_instance_of Hash
        @pinger["ping_port"].should be 5002
        EM.stop
      end
    end

    it "should create a credential when binding" do
      EM.run do
        binding = @node.bind(@pinger["name"], @default_opts)
        binding["ping_port"].should be 5002
        EM.stop
      end
    end

    it "should supply different credentials when binding evoked with the same input" do
      EM.run do
        binding1 = @node.bind(@pinger["name"], @default_opts)
        binding2 = @node.bind(@pinger["name"], @default_opts)
        binding1.should_not be binding2
        EM.stop
      end
    end

    it "shoulde delete credential after unbinding" do
      EM.run do
        binding = @node.bind(@pinger["name"], @default_opts)
        @node.unbind(binding)
        EM.stop
      end
    end

    after :each do
      name = @pinger["name"]
      @node.unprovision(name)
      @node.unprovision_unwanted()
    end
  end
end
