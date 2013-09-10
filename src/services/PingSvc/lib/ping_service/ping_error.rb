module VCAP
  module Services
    module Ping
      class PingError < VCAP::Services::Base::Error::ServiceError
        PING_SAVE_INSTANCE_FAILED        = [32100, HTTP_INTERNAL, "Could not save instance: %s"]
        PING_DESTORY_INSTANCE_FAILED     = [32101, HTTP_INTERNAL, "Could not destroy instance: %s"]
        PING_FIND_INSTANCE_FAILED        = [32102, HTTP_NOT_FOUND, "Could not find instance: %s"]
        PING_START_INSTANCE_FAILED       = [32103, HTTP_INTERNAL, "Could not start instance: %s"]
        PING_STOP_INSTANCE_FAILED        = [32104, HTTP_INTERNAL, "Could not stop instance: %s"]
        PING_INVALID_PLAN                = [32105, HTTP_INTERNAL, "Invalid plan: %s"]
        PING_CLEANUP_INSTANCE_FAILED     = [32106, HTTP_INTERNAL, "Could not cleanup instance, the reasons: %s"]
      end
    end
  end
end
