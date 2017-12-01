# encoding: utf-8

#***************************************************************************
#
# Copyright (c) 2015 SUSE LLC
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com
#
#**************************************************************************
#
module Yast
  # Client to set the hostname during first boot
  #
  # This is just a renamed version of InstHostnameClient, which was removed from
  # YaST2-Network when the second stage was removed from the installation
  # process
  class FirstbootHostnameClient < Client
    def main
      Yast.import "UI"

      textdomain "network"

      Yast.import "Arch"
      Yast.import "DNS"
      Yast.import "Host"
      Yast.import "NetworkConfig"
      Yast.import "String"
      Yast.import "Wizard"
      Yast.import "ProductControl"
      Yast.import "ProductFeatures"
      Yast.import "GetInstArgs"

      Yast.include self, "network/services/dns.rb"

      # only once, do not re-propose if user gets back to this dialog from
      # the previous screen - bnc#438124
      if !DNS.proposal_valid
        DNS.Read # handles NetworkConfig too
        DNS.ProposeHostname # generate random hostname, if none known so far

        # propose settings
        DNS.dhcp_hostname = !Arch.is_laptop

        # get default value, from control.xml
        DNS.write_hostname = DNS.DefaultWriteHostname
      end

      Wizard.SetDesktopIcon("dns")
      ret = HostnameDialog()

      if ret == :next
        Host.Read
        Host.ResolveHostnameToStaticIPs
        Host.Write

        # do not let Lan override us, #152218
        DNS.proposal_valid = true

        # In InstHostname writing was delayed to do it with the rest of
        # network configuration in lan_proposal.
        # In FirstbootHostname it's probably safer to do it right away.
        DNS.Write
      end

      ret
    end

    def HostnameDialog
      @has_dhcp = true

      @hn_settings = InitSettings()

      functions = {
        "init"  => fun_ref(method(:InitHnWidget), "void (string)"),
        "store" => fun_ref(method(:StoreHnWidget), "void (string, map)"),
        :abort  => fun_ref(method(:ReallyAbortInst), "boolean ()")
      }
      contents = HSquash(
        # Frame label
        Frame(
          _("Hostname and Domain Name"),
          VBox(
            HBox("HOSTNAME", HSpacing(1), "DOMAIN"),
            Left("DHCP_HOSTNAME"),
            Left("WRITE_HOSTNAME")
          )
        )
      )

      ret = CWM.ShowAndRun(
        "widget_descr"       => @widget_descr_dns,
        "contents"           => contents,
        # dialog caption
        "caption"            => _("Hostname and Domain Name"),
        "back_button"        => Label.BackButton,
        "next_button"        => Label.NextButton,
        "fallback_functions" => functions,
        "disable_buttons"    => GetInstArgs.enable_back ? [] : ["back_button"]
      )

        if ret == :next
        # Pre-populate resolv.conf search list with current domain name
        # but only if none exists so far
        current_domain = Ops.get_string(@hn_settings, "DOMAIN", "")

        # Need to modify hn_settings explicitly as SEARCHLIST_S widget
        # does not exist in this dialog, thus StoreHnWidget won't do it
        # #438167
        if DNS.searchlist == [] && current_domain != "site"
          Ops.set(@hn_settings, "SEARCHLIST_S", current_domain)
        end

        StoreSettings(@hn_settings)
      end

      ret
    end
  end
end

Yast::FirstbootHostnameClient.new.main
