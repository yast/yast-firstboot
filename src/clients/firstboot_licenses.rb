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

# Purpose	: Display 2 license texts (probably from vendor and Novell) during firstboot configuration
#
# $Id$
module Yast
  class FirstbootLicensesClient < Client
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

      @dir1 = Misc.SysconfigRead(
        path(".sysconfig.firstboot.FIRSTBOOT_LICENSE_DIR"),
        "/etc/YaST2"
      )
      @dir2 = Misc.SysconfigRead(
        path(".sysconfig.firstboot.FIRSTBOOT_NOVELL_LICENSE_DIR"),
        @default_dir
      )

      if @dir2 != @dir1
        Ops.set(@args, "directories", [@dir1, @dir2])
      else
        Ops.set(@args, "directories", [@dir1])
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

      UI.CloseDialog if @result == :halt

      deep_copy(@result)
    end
  end
end

Yast::FirstbootLicensesClient.new.main
