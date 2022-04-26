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

# File:	clients/firstboot.ycp
# Package:	Configuration of Firstboot
# Summary:	Main file
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
#
# Main file for firstboot configuration. Uses all other files.

#**
# <h3>Configuration of firstboot</h3>

require "yast2/popup"

module Yast
  class FirstbootConfigClient < Client
    def main
      Yast.import "UI"
      textdomain "firstboot"
      Yast.import "ProductControl"
      Yast.import "Firstboot"
      Yast.import "Wizard"
      Yast.import "XML"

      Yast.include self, "firstboot/routines.rb"


      XmlSetup()

      # TRANSLATORS: label (used in a table)
      @empty_label = _("Empty")
      # TRANSLATORS: label (used in a table)
      @enabled = _("Enabled")
      # TRANSLATORS: label (used in a table)
      @disabled = _("Disabled")

      @modules = ProductControl.getModules("normal", "firstboot", :all)
      @items = []
      # TODO: add a nice help text here...
      @help = ""

      Wizard.CreateDialog
      # TRANSLATORS: dialog caption
      @caption = _("First Boot Configuration")

      # TRANSLATORS: button label
      @upButtonLabel = _("&Up")
      # TRANSLATORS: button label
      @downButtonLabel = _("D&own")
      # TRANSLATORS: button label
      @enableButtonLabel = _("Enab&le or Disable")

      @contents = Top(
        VBox(
          Table(
            Id(:table),
            Opt(:keepSorting),
            Header(
              # TRANSLATORS: table header
              _("Step"),
              # TRANSLATORS: table header
              _("Label"),
              # TRANSLATORS: table header
              _("Module Name"),
              # TRANSLATORS: table header
              _("Status")
            ),
            @items
          ),
          VBox(
            HBox(
              PushButton(Id(:up), Opt(:hstretch), @upButtonLabel),
              PushButton(Id(:down), Opt(:hstretch), @downButtonLabel)
            ),
            PushButton(Id(:enable), Opt(:hstretch, :key_F6), @enableButtonLabel)
          )
        )
      )


      Wizard.SetContents(@caption, @contents, @help, true, true)
      Wizard.HideBackButton
      Wizard.HideAbortButton
      fillTable


      @ret = nil
      @current = -1
      while true
        if Ops.greater_or_equal(@current, 0)
          UI.ChangeWidget(Id(:table), :CurrentItem, @current)
        end
        @ret = UI.UserInput
        @current = Convert.to_integer(UI.QueryWidget(Id(:table), :CurrentItem))
        @w = Ops.get(@modules, @current, {})

        if @ret == :abort
          break
        elsif @ret == :enable
          @state = Ops.get_boolean(@w, "enabled", true)
          @state = !@state
          @newstate = @state ? @enabled : @disabled
          UI.ChangeWidget(Id(:table), term(:Item, @current, 3), @newstate)
          Ops.set(@w, "enabled", @state)
          Ops.set(@modules, @current, @w)
        elsif @ret == :up
          if Ops.greater_than(@current, 0)
            @tmpState = Ops.get(@modules, @current, {})
            Ops.set(
              @modules,
              @current,
              Ops.get(@modules, Ops.subtract(@current, 1), {})
            )
            Ops.set(@modules, Ops.subtract(@current, 1), @tmpState)
            @current = Ops.subtract(@current, 1)
          end
          fillTable
        elsif @ret == :down
          if Ops.less_than(@current, Ops.subtract(Builtins.size(@modules), 1))
            @tmpState = Ops.get(@modules, @current, {})
            Ops.set(
              @modules,
              @current,
              Ops.get(@modules, Ops.add(@current, 1), {})
            )
            Ops.set(@modules, Ops.add(@current, 1), @tmpState)
            @current = Ops.add(@current, 1)
          end
          fillTable
        elsif @ret == :next
          # Test Saving
          @all = deep_copy(ProductControl.productControl)
          @orig_workflow = ProductControl.getCompleteWorkflow(
            "normal",
            "firstboot"
          )
          Ops.set(@orig_workflow, "modules", @modules)
          Ops.set(@all, ["workflows", 0], @orig_workflow)
          begin
            XML.YCPToXMLFile(:firstboot, @all, "/tmp/firstboot.xml")
            break
          rescue XMLSerializationError => e
            # TRANSLATORS: error message
            Yast2::Popup.show(_("Failed to create configuration file."),
              headline: :error, details: e.message)
          end
        end
      end
      Wizard.CloseDialog

      deep_copy(@ret)
    end

    def fillTable
      i = 0
      workflow_modules = Builtins.maplist(@modules) do |m|
        item = Item(
          Id(i),
          i,
          Ops.get_string(m, "label", @empty_label),
          Ops.get_string(m, "name", @empty_label),
          Ops.get_boolean(m, "enabled", true) ? @enabled : @disabled
        )
        i = Ops.add(i, 1)
        deep_copy(item)
      end
      UI.ChangeWidget(Id(:table), :Items, workflow_modules)

      nil
    end
  end
end

Yast::FirstbootConfigClient.new.main
