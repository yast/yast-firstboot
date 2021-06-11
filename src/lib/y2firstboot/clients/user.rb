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
require "users/dialogs/inst_user_first"

Yast.import "Users"
Yast.import "Progress"

module Y2Firstboot
  module Clients
    # Client to set up the first user during the firstboot mode
    class User < Yast::Client
      class << self
        # @return [String, nil] the username of the created/edited user as a
        # result of the execution of this client, if any. Needed for retrieving
        # the user when going back and forward. See {#user}
        attr_accessor :username
      end

      def run
        result = Yast::InstUserFirstDialog.new(config, user: user).run

        if result == :next
          # Keeps the user name for future reference. See {#user}
          self.class.username = user.attached? ? user.name : nil
          write_config
        end

        result
      end

    private

      # Updates target configuration and writes it to the system
      def write_config
        Y2Users::ConfigManager.instance.target = config

        writer = Y2Users::Linux::Writer.new(
          Y2Users::ConfigManager.instance.target,
          Y2Users::ConfigManager.instance.system(force_read: true)
        )

        writer.write
      end

      # A copy of config holding all the users on the system
      #
      # @return [Y2Users::Config]
      def config
        @config ||= Y2Users::ConfigManager.instance.system(force_read: true).copy
      end

      # The user to be created/edited
      #
      # @return [Y2Users::Userr]
      def user
        @user ||= config.users.by_name(self.class.username) if self.class.username
        @user ||= Y2Users::User.new("")
      end
    end
  end
end
