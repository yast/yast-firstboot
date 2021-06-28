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

require "y2users/password"
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
        reset_password

        result = Yast::InstUserFirstDialog.new(config, user: user).run

        write_config if result == :next

        # Updates the username reference. See {#user}
        self.class.username = user.attached? ? user.name : nil

        result
      end

    private

      # Wipes encrypted password
      #
      # @note This method can be considered a sort of workaround for supporting
      # as much as possible a "clean" navigation through the Firstboot dialogs
      # when going back and forward (just in case the admin decides to offer
      # such a feature), EVEN THOUGH is not the intended behavior since
      # Firstboot clients perform changes in the running system right away.
      def reset_password
        return unless user.password&.value&.encrypted?

        user.password = Y2Users::Password.create_plain("")
      end

      # Writes config to the system
      def write_config
        writer = Y2Users::Linux::Writer.new(
          config,
          Y2Users::ConfigManager.instance.system
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
      # @return [Y2Users::User]
      def user
        @user ||= config.users.by_name(self.class.username) if self.class.username
        @user ||= Y2Users::User.new("")
      end
    end
  end
end
