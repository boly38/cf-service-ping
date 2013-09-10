require 'ping_service/common'

class VCAP::Services::Ping::Provisioner < VCAP::Services::Base::Provisioner

  include VCAP::Services::Ping::Common

end
