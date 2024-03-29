# Copyright (c) [2016-2023] SUSE LLC
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
require "y2users/user_commit_config"
require "y2users/commit_config"
require "users/dialogs/inst_user_first"
require "pathname"

module Y2Firstboot
  module Clients
    # Client to set up the user during the firstboot mode
    class User < Yast::Client
      class << self
        # The username of the created/edited user, if any.
        #
        # Needed for retrieving the user when going back and forward.
        #
        # @see #user
        #
        # @return [String, nil]
        attr_accessor :username

        # Plain password of the user, if any.
        #
        # Needed for retrieving the plain version of the password when going back and forward. Note
        # that the user is committed to the system right away in this step, so when going back the
        # password of the user would be already encrypted. The plain version of the password is
        # needed in order to fill the password field with the current value, and also to determine
        # whether that same password was used for root, see Yast::InstUserFirstDialog.
        #
        # @return [String, nil]
        attr_accessor :user_password

        # Plain password of the root user, if any.
        #
        # @see #user_password
        #
        # @return [String, nil]
        attr_accessor :root_password
      end

      def run
        load_values

        result = Yast::InstUserFirstDialog.new(config, user: user).run

        if result == :next
          write_config
          save_values
        end

        result
      end

    private

      # Writes config to the system
      def write_config
        writer = Y2Users::Linux::Writer.new(
          config,
          Y2Users::ConfigManager.instance.system,
          commit_config
        )

        writer.write
      end

      # Loads previously saved values
      #
      # This is needed for supporting a "clean" navigation through the Firstboot dialogs when going
      # back and forward. See also {#save_values}.
      def load_values
        load_user_password
        load_root_password
      end

      # Loads the saved plain password of the user
      def load_user_password
        user.password = Y2Users::Password.create_plain(self.class.user_password || "")
      end

      # Loads the saved plain password of the root user
      def load_root_password
        return unless self.class.root_password

        root_user.password = Y2Users::Password.create_plain(self.class.root_password)
      end

      # Saves the given values
      #
      # @see #load_values
      def save_values
        save_username
        save_user_password
        save_root_password
      end

      # Saves the given username
      def save_username
        self.class.username = user.attached? ? user.name : nil
      end

      # Saves the given user password, if needed
      def save_user_password
        self.class.user_password = user.attached? ? user.password_content : nil
      end

      # Saves the given root password, if needed
      def save_root_password
        return if root_user.password&.value&.encrypted?

        self.class.root_password = root_user&.password_content
      end

      # The user to be created/edited
      #
      # @return [Y2Users::User]
      def user
        @user ||= config.users.by_name(self.class.username) if self.class.username
        @user ||= Y2Users::User.new("")
      end

      # The root user
      #
      # @return [Y2Users::User]
      def root_user
        @root_user ||= config.users.root
      end

      # Builds the commit config to use when writing users
      #
      # @return [Y2Users::CommitConfig]
      def commit_config
        Y2Users::CommitConfig.new.tap do |commit_config|
          # Configure the actions to perform when committing a user.
          #
          #   - If the user is being created, its home should content the skel files
          #   (#home_without_skel).
          #   - In case of editing a user and its home path has changed (i.e., because the user
          #   name was modified), then the current home content should be moved to the new path
          #   (#move_home option). Additionally, if the new home path already exists, then the user
          #   should be set as owner of the existing directory (#adapt_home_ownership option).
          #   - When deleting the user (i.e., when going back to skip the user creation after
          #   creating it), its home must be removed too (#remove_home).
          user_config = Y2Users::UserCommitConfig.new.tap do |config|
            config.username = user.name
            config.home_without_skel = false
            config.move_home = true
            config.adapt_home_ownership = true
            # WARNING: this can lead to a undesired situation if using firstboot in an already
            # initialized system with the user home previously created. However, this is quite
            # unexpected scenario for this client and firstboot module in general.
            config.remove_home = true
          end

          commit_config.user_configs.add(user_config)
        end
      end

      # A copy of config holding all the users on the system
      #
      # @return [Y2Users::Config]
      def config
        @config ||= Y2Users::ConfigManager.instance.system(force_read: true).copy
      end
    end
  end
end
