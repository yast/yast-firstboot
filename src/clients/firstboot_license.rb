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

# Module	: Firstboot configuration
# File		: firstboot_license_novell.ycp
# Author	: Ladislav Slezak <lslezak@suse.cz>,
# Purpose	: Display vendor license during firstboot configuration
#
# $Id$
module Yast
  class FirstbootLicenseClient < Client
    def main
      Yast.import "UI"
      textdomain "firstboot"

      Yast.import "Misc"
      Yast.import "GetInstArgs"


      @result = nil

      @args = GetInstArgs.argmap
      Ops.set(
        @args,
        "directory",
        Misc.SysconfigRead(
          path(".sysconfig.firstboot.FIRSTBOOT_LICENSE_DIR"),
          "/etc/YaST2"
        )
      )
      Ops.set(
        @args,
        "action",
        Misc.SysconfigRead(
          path(".sysconfig.firstboot.LICENSE_REFUSAL_ACTION"),
          "abort"
        )
      )

      Builtins.y2milestone("inst_license options: %1", @args)

      @result = WFM.CallFunction("inst_license", [@args])

      if @result == :halt
        UI.CloseDialog
        Builtins.y2milestone("Halting the system...")
        SCR.Execute(path(".target.bash"), "/sbin/halt")
      end

      deep_copy(@result)
    end
  end
end

Yast::FirstbootLicenseClient.new.main
