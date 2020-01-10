# encoding: utf-8

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

#
# Module:             firstboot_ssh.ycp
#
# Author:             Jiri Srain <jsrain@novell.com>
#
# Submodules:
#
#
# Purpose:	recreate SSH keys during firstboot run
#
#
#
# $Id$
module Yast
  class FirstbootSshClient < Client
    def main

      textdomain "firstboot"

      Yast.import "GetInstArgs"

      return :auto if GetInstArgs.going_back

      # TODO: do not use shell script
      SCR.Execute(
        path(".target.bash"),
        "\n" +
          "/usr/bin/systemctl list-units | /usr/bin/grep sshd || exit 0;\n" +
          "\n" +
          "/usr/bin/systemctl status sshd && export SSHD_IS_RUNNING=1;\n" +
          "\n" +
          "[ $SSHD_IS_RUNNING ] && /usr/bin/systemctl stop sshd;\n" +
          "rm -f /etc/ssh/ssh_host*key*;\n" +
          "[ $SSHD_IS_RUNNING ] && /usr/bin/systemctl start sshd;\n"
      )

      :next
    end
  end
end

Yast::FirstbootSshClient.new.main
