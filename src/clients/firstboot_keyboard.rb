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

# File		: firstboot_keyboard.ycp
# Author	: Jiri Suchomel <jsuchome@suse.cz>
# Purpose	: Firstboot configuratiuon of keyboard
#
# $Id$
module Yast
  class FirstbootKeyboardClient < Client
    def main
      Yast.import "UI"
      textdomain "country"

      Yast.import "Arch"
      Yast.import "GetInstArgs"
      Yast.import "Directory"
      Yast.import "Keyboard"
      Yast.import "Firstboot"

      Yast.include self, "keyboard/dialogs.rb"

      @ret = :auto
      return deep_copy(@ret) if Arch.s390

      Keyboard.Read

      @ret = KeyboardDialog(GetInstArgs.argmap)

      Keyboard.Save if @ret == :next

      deep_copy(@ret)
    end
  end
end

Yast::FirstbootKeyboardClient.new.main
