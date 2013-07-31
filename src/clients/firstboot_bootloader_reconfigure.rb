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
module Yast
  class FirstbootBootloaderReconfigureClient < Client
    def main
      Yast.import "Arch"
      Yast.import "BootCommon"
      Yast.import "Bootloader"
      Yast.import "GetInstArgs"
      Yast.import "Kernel"
      Yast.import "Mode"


      return :auto if GetInstArgs.going_back

      Bootloader.Reset
      if Arch.i386 || Arch.x86_64
        SetVGAKernelParam()
        Builtins.y2milestone("Setting VGA parameter to %1", Kernel.GetVgaType)
      end

      # pretend installation
      @mode = Mode.mode
      Mode.SetMode("installation")

      Bootloader.Propose
      Mode.SetMode(@mode)

      if Arch.i386 || Arch.x86_64
        BootCommon.selected_location = "mbr"
        BootCommon.loader_device = BootCommon.GetBootloaderDevice
        BootCommon.location_changed = true
        BootCommon.changed = true
      end
      Builtins.y2milestone("Loader type: %1", Bootloader.getLoaderType)
      Builtins.y2milestone("Summary: %1", Bootloader.Summary)
      Bootloader.Write

      :next
    end

    def SetVGAKernelParam
      cmldline = Convert.to_string(
        WFM.Read(path(".local.string"), "/proc/cmdline")
      )

      if cmldline == nil
        Builtins.y2error("No cmdline!")
        return
      end

      cmdline_args = Builtins.splitstring(cmldline, " \t\n")

      just_parsing = ""

      Builtins.foreach(cmdline_args) do |cmdline_arg|
        if Builtins.regexpmatch(cmdline_arg, "[vV][gG][aA]=.*")
          just_parsing = cmdline_arg
          cmdline_arg = Builtins.regexpsub(
            cmdline_arg,
            "[vV][gG][aA]=(.*)",
            "\\1"
          )

          if cmdline_arg == nil || cmdline_arg == ""
            Builtins.y2error("Incorrect vga param %1", just_parsing)
            raise Break
          else
            Builtins.y2milestone("Adjusting Kernel cmdline vga=%1", cmdline_arg)
            Kernel.SetVgaType(cmdline_arg)
            raise Break
          end
        end
      end

      nil
    end
  end
end

Yast::FirstbootBootloaderReconfigureClient.new.main
