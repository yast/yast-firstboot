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

# Module : firstboot_license_novell.ycp
# Authors: Ladislav Slezak <lslezak@suse.cz>, Jiri Suchomel <jsuchome@suse.cz>
# Purpose: Display Novell license at the start of firstboot
#
# $Id$
module Yast
  class FirstbootLicenseNovellClient < Client
    def main
      Yast.import "UI"
      textdomain "firstboot"

      Yast.import "Misc"
      Yast.import "GetInstArgs"
      Yast.import "ProductFeatures"

      @result = nil

      @args = GetInstArgs.argmap

      # default directory with Novell license texts
      @default_dir = ProductFeatures.GetStringFeature(
        "globals",
        "base_product_license_directory"
      )

      Ops.set(
        @args,
        "directory",
        Misc.SysconfigRead(
          path(".sysconfig.firstboot.FIRSTBOOT_NOVELL_LICENSE_DIR"),
          @default_dir
        )
      )
      if Ops.get_string(@args, "directory", "") == ""
        Ops.set(@args, "directory", @default_dir)
      end

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

Yast::FirstbootLicenseNovellClient.new.main
