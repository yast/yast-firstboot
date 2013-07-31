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
# Module:             firstboot_welcome.ycp
#
# Author:             Ladislav Slezak <lslezak@suse.cz>
#
# Submodules:
#
#
# Purpose:	display a welcome message in running system
#
#
#
# $Id$
module Yast
  class FirstbootWelcomeClient < Client
    def main
      textdomain "firstboot"

      Yast.import "Misc"
      Yast.import "GetInstArgs"
      Yast.import "Directory"


      @result = nil

      @args = GetInstArgs.argmap

      @directory = Misc.SysconfigRead(
        path(".sysconfig.firstboot.FIRSTBOOT_WELCOME_DIR"),
        ""
      )
      if @directory != ""
        # set the prefix to root
        Directory.custom_workflow_dir = "/"
        Ops.set(@args, "directory", @directory)
      end

      @patterns = Misc.SysconfigRead(
        path(".sysconfig.firstboot.FIRSTBOOT_WELCOME_PATTERNS"),
        ""
      )
      if @patterns != ""
        Ops.set(@args, "patterns", Builtins.splitstring(@patterns, ","))
      end

      Builtins.y2milestone("inst_welcome options: %1", @args)

      @result = WFM.CallFunction("inst_welcome", [@args])

      deep_copy(@result)
    end
  end
end

Yast::FirstbootWelcomeClient.new.main
