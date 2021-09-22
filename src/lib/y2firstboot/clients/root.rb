# Copyright (c) [2016-2021] SUSE LLC
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

require "yast"
require "y2users/password"
require "y2users/linux/writer"
require "y2users/config_manager"
require "y2users/commit_config_collection"
require "y2users/commit_config"
require "users/dialogs/inst_root_first"
require "y2firstboot/clients/user"

Yast.import "GetInstArgs"

module Y2Firstboot
  module Clients
    # Client for setting the root password
    class Root < Yast::Client
      def run
        return :auto unless run?

        load_password

        result = Yast::InstRootFirstDialog.new(root_user).run

        if result == :next
          write_config
          save_password
        end

        result
      end

    private

      # Whether to run the client
      #
      # Note that this client should be automatically skipped when root was configured to use the
      # same password as a user.
      #
      # @return [Boolean]
      def run?
        force? || !root_password_from_user?
      end

      # Whether the client is configured to always run it
      #
      # @return [Boolean]
      def force?
        Yast::GetInstArgs.argmap.fetch("force", false)
      end

      # Whether the user password was used for root
      #
      # @see Y2Firstboot::Clients::User
      #
      # @return [Boolean]
      def root_password_from_user?
        Y2Firstboot::Clients::User.user_password == Y2Firstboot::Clients::User.root_password
      end

      # Writes the config to the system
      def write_config
        writer = Y2Users::Linux::Writer.new(
          config,
          Y2Users::ConfigManager.instance.system,
          Y2Users::CommitConfigCollection.new.tap { |collection| collection.add(commit_config) }
        )
        writer.write
      end

      # Loads the saved plain password of the root user
      #
      # This is needed for supporting a "clean" navigation through the Firstboot dialogs when going
      # back and forward. See also {#save_password}.
      def load_password
        value = Y2Firstboot::Clients::User.root_password || ""
        root_user.password = Y2Users::Password.create_plain(value)
      end

      # Saves the given root password
      def save_password
        Y2Firstboot::Clients::User.root_password = root_user.password_content
      end

      # Build and return a {Y2Users::CommitConfig} for #root_user
      #
      # @return [Y2Users::CommitConfig]
      def commit_config
        Y2Users::CommitConfig.new.tap do |config|
          config.username = root_user.name
        end
      end

      # The root user
      #
      # @return [Y2Users::User]
      def root_user
        @root_user ||= config.users.root
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
