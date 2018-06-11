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

# Maintainer:             Jiri Srain <jsrain@suse.cz>
#
# $Id$
module Yast
  class FirstbootClient < Client
    def main
      Yast.import "UI"
      Yast.import "Pkg"
      textdomain "firstboot"

      Yast.import "Directory"
      Yast.import "Mode"
      Yast.import "Stage"
      Yast.import "ProductControl"
      Yast.import "Wizard"
      Yast.import "Report"
      Yast.import "Firstboot"
      Yast.import "Misc"
      Yast.import "PackageCallbacksInit"
      Yast.import "Keyboard"

      Wizard.OpenNextBackStepsDialog

      # Always force the mode (bsc#924278)
      Mode.SetMode("installation")
      ProductControl.AddWizardSteps([{ "stage" => "firstboot", "mode" => "installation" }])

      # Do log Report messages by default (#180862)
      Report.LogMessages(true)
      Report.LogErrors(true)
      Report.LogWarnings(true)

      # Just in case /etc/X11/xorg.conf.d/00-keyboard.conf has not been
      # generated yet (the X server started by YaST-Firstboot doesn't seem to
      # be enough to trigger the systemd mechanism that generates it), let's
      # enforce the keyboard map if we are running in graphic mode (bsc#950335)
      Keyboard.SetX11(Keyboard.current_kbd)

      # initialize package callbacks, since some of the modules run in the
      # firstboot workflow expect them to be initialized (bug #335979)
      PackageCallbacksInit.InitPackageCallbacks

      @ret = ProductControl.Run
      Builtins.y2milestone("ProductControl::Run() returned: %1", @ret)

      Pkg.SourceFinishAll
      Pkg.TargetFinish

      if @ret == :next || @ret == :finish
        @action = Misc.SysconfigRead(
          path(".sysconfig.firstboot.FIRSTBOOT_FINISH_ACTION"),
          ""
        )
        if @action == "reboot"
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat(
              "touch %1/firstboot_reboot_after_finish",
              Directory.vardir
            )
          )
        end
      end

      UI.CloseDialog

      # handle abort
      if @ret == :abort
        # do the same action as if the license has not been accepted
        @action = Misc.SysconfigRead(
          path(".sysconfig.firstboot.LICENSE_REFUSAL_ACTION"),
          "halt"
        )
        Builtins.y2milestone(
          "Firstboot aborted, LICENSE_REFUSAL_ACTION: %1",
          @action
        )

        # The S09-cleanup script is responsible of rebooting or halting the
        # system depending on the existence of the specifig flag files
        if @action == "halt"
          Builtins.y2milestone("Halting the system...")
          SCR.Execute(path(".target.bash"),
               Builtins.sformat(
              "touch %1/firstboot_halt_after_finish",
              Directory.vardir
            )
          )
        elsif @action == "reboot"
          Builtins.y2milestone("Rebooting the system...")
          SCR.Execute(path(".target.bash"),
               Builtins.sformat(
              "touch %1/firstboot_reboot_after_finish",
              Directory.vardir
            )
          )
        elsif @action == "continue"
          Builtins.y2milestone("Finishing Yast...")
        else
          Builtins.y2error("Unknown action: %1", @action)
        end
      end

      @ret
    end
  end
end

Yast::FirstbootClient.new.main
