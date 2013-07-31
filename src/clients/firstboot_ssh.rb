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

      SCR.Execute(
        path(".target.bash"),
        "\n" +
          "test -x /etc/init.d/sshd || exit 0;\n" +
          "\n" +
          "/etc/init.d/sshd status && export SSHD_IS_RUNNING=1;\n" +
          "\n" +
          "[ $SSHD_IS_RUNNING ] && /etc/init.d/sshd stop;\n" +
          "rm -f /etc/ssh/ssh_host*key*;\n" +
          "[ $SSHD_IS_RUNNING ] && /etc/init.d/sshd start;\n"
      )

      :next
    end
  end
end

Yast::FirstbootSshClient.new.main
