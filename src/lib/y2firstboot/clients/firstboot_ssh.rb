# ------------------------------------------------------------------------------
# Copyright (c) 2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

Yast.import "GetInstArgs"

require "fileutils"
require "yast2/systemd/service"

module Y2Firstboot
  module Clients
    # class responsible for recreation of ssh keys during first boot run
    class FirstbootSSH
      def run
        return :auto if Yast::GetInstArgs.going_back

        service = Yast2::Systemd::Service.find("sshd")
        return :next unless service # sshd not installed

        running = service.running?
        service.stop if running
        Dir.glob("/etc/ssh/ssh_host*key*") do |file|
          FileUtils.rm_f(file)
        end
        service.start if running

        :next
      end
    end
  end
end
