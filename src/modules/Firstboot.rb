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

# File:	modules/Firstboot.ycp
# Package:	Configuration of firstboot
# Summary:	Firstboot settings, input and output functions
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
#
# Representation of the configuration of firstboot.
# Input and output routines.
require "yast"

module Yast
  class FirstbootClass < Module
    def main
      textdomain "firstboot"

      Yast.import "NetworkInterfaces"
      Yast.import "Progress"
      Yast.import "Internet"
      Yast.import "Misc"
      Yast.import "Mode"
      Yast.import "Directory"
      Yast.import "ProductControl"
      Yast.import "Summary"



      @script_dir = ""

      @language_changed = false

      # definition of firstboot sequence (and the default path)
      @firstboot_control_file = "/etc/YaST2/firstboot.xml"

      # file triggering start of firstboot sequence
      @reconfig_file = "/var/lib/YaST2/reconfig_system"

      @default_wm = ""

      @installed_desktops = []

      # for autoinstallation: should the firstboot be enbaled?
      @firstboot_enabled = false

      # if some settings were modified (currently for autoyast only)
      @modified = false
      Firstboot()
    end

    def Firstboot
      if Mode.config || Mode.auto
        Builtins.y2milestone(
          "no firstboot initialization in mode %1",
          Mode.mode
        )
        return
      end
      @default_wm = Misc.SysconfigRead(
        path(".sysconfig.windowmanager.DEFAULT_WM"),
        "kde"
      )
      Progress.off
      NetworkInterfaces.Read
      Progress.on
      Internet.do_you = true

      control_file = Misc.SysconfigRead(
        path(".sysconfig.firstboot.FIRSTBOOT_CONTROL_FILE"),
        ""
      )
      @firstboot_control_file = control_file if control_file != ""

      ProductControl.custom_control_file = @firstboot_control_file

      if !ProductControl.Init
        Builtins.y2error(
          "control file %1 not found",
          ProductControl.custom_control_file
        )
      end

      nil
    end


    # Execute custom scripts
    # @return boolean
    def ExecuteScripts
      @script_dir = Misc.SysconfigRead(
        path(".sysconfig.firstboot.SCRIPT_DIR"),
        "/usr/share/firstboot/scripts"
      )

      if @script_dir != ""
        scripts = Builtins.sort(
          Convert.convert(
            SCR.Read(path(".target.dir"), @script_dir),
            :from => "any",
            :to   => "list <string>"
          )
        )
        Builtins.foreach(scripts) do |script|
          ret = Convert.to_map(
            SCR.Execute(
              path(".target.bash_output"),
              Ops.add(
                Ops.add(Ops.add(@script_dir, "/"), script),
                " >> /var/log/YaST2/firstboot.log"
              )
            )
          )
          if Ops.get_integer(ret, "exit", -1) != 0
            Builtins.y2error("script failed: %1", ret)
          end
        end
      else
        Builtins.y2error("Script dir empty or not configured")
      end
      true
    end

    # Import firstboot settigs defined by autoyast
    def Import(settings)
      settings = deep_copy(settings)
      ena = Ops.get_boolean(settings, "firstboot_enabled", @firstboot_enabled)
      if ena != @firstboot_enabled
        @firstboot_enabled = ena
        @modified = true
      end
      @modified
    end

    # Export firstboot settigs defined by autoyast
    def Export
      { "firstboot_enabled" => @firstboot_enabled }
    end
    # Summary()
    # returns html formated configuration summary
    # @return summary
    def Summary
      summary =
        # TRANSLATORS: summary item
        Summary.AddHeader("", _("Firstboot configuration disabled"))
      if @firstboot_enabled
        # TRANSLATORS: summary item
        summary = Summary.AddHeader("", _("Firstboot configuration enabled"))
      end
      summary
    end


    # Write firstboot settings
    def Write
      if @firstboot_enabled
        Builtins.y2milestone("enabling firstboot...")
        SCR.Execute(
          path(".target.bash"),
          Ops.add("/bin/touch ", @reconfig_file)
        )
      end

      nil
    end

    publish :variable => :language_changed, :type => "boolean"
    publish :variable => :firstboot_control_file, :type => "string"
    publish :variable => :reconfig_file, :type => "string"
    publish :variable => :default_wm, :type => "string"
    publish :variable => :installed_desktops, :type => "list <string>"
    publish :variable => :firstboot_enabled, :type => "boolean"
    publish :variable => :modified, :type => "boolean"
    publish :function => :Firstboot, :type => "void ()"
    publish :function => :ExecuteScripts, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "string ()"
    publish :function => :Write, :type => "boolean ()"
  end

  Firstboot = FirstbootClass.new
  Firstboot.main
end
