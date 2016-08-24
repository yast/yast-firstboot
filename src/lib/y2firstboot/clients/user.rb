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

require "users/dialogs/inst_user_first"
Yast.import "Users"
Yast.import "UsersSimple"
Yast.import "Progress"

module Y2Firstboot
  module Clients
    class User < Yast::Client

      def initialize
        Yast.include self, "users/routines.rb"
      end

      def run
        dialog = Yast::InstUserFirstDialog.new
        dialog_result = dialog.run
        if dialog_result == :next && dialog.action == :new_user
          # Change root password if needed
          Yast::UsersSimple.Write
          # Create user
          if setup_all_users
            # Do not mess with the progress indicator
            orig = Yast::Progress.set(false)
            Yast::Users.Write
            Yast::Progress.set(orig)
          end
        end
        dialog_result
      end
    end
  end
end
