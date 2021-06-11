#!/usr/bin/env ruby
#
# encoding: utf-8

# Copyright (c) [2016] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "y2users/linux/writer"
require "y2users/config_manager"
require "y2users/clients/inst_root_first"

module Y2Firstboot
  module Clients
    # Client for setting the root password
    class Root < Y2Users::Clients::InstRootFirst
    private

      # Updates the target configuration and writes it to the system
      #
      # @see Y2Users::Clients::InstRootFirst#update_target_config
      def update_target_config
        super

        writer = Y2Users::Linux::Writer.new(
          Y2Users::ConfigManager.instance.target,
          Y2Users::ConfigManager.instance.system(force_read: true)
        )
        writer.write
      end

      # System config, which contains all the current users on the system
      #
      # @return [Y2Users::Config]
      def config
        @config ||= Y2Users::ConfigManager.instance.system(force_read: true).copy
      end
    end
  end
end
