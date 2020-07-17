# Copyright (c) [2020] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"

Yast.import "UI"
Yast.import "Arch"
Yast.import "DNS"
Yast.import "Host"
Yast.import "NetworkConfig"
Yast.import "String"
Yast.import "Wizard"
Yast.import "ProductControl"
Yast.import "ProductFeatures"
Yast.import "GetInstArgs"

module Y2Firstboot
  module Clients
    # Client to set the hostname during first boot
    #
    # This is just a renamed version of InstHostnameClient, which was removed from
    # YaST2-Network when the second stage was removed from the installation
    # process
    class Hostname < Yast::Client
      class << self
        # @!method valid_dns_proposal=(value)
        #   @param [Boolean] Whether a valid DNS proposal was done
        attr_writer :valid_dns_proposal

        # Determines whether a valid DNS proposal was done
        #
        # @return [Boolean] Returns true if a DNS proposal was done
        def valid_dns_proposal
          @valid_dns_proposal ||= false
        end

        def run
          new.run
        end
      end

      def initialize
        textdomain "firstboot"
      end

      def run
        Yast.include self, "network/services/dns.rb"

        # only once, do not re-propose if user gets back to this dialog from
        # the previous screen - bnc#438124
        if !self.class.valid_dns_proposal
          Lan.Read(:cache) # handles NetworkConfig too
          propose_hostname if propose_hostname?
        end

        Wizard.SetDesktopIcon("org.opensuse.yast.DNS")
        ret = hostname_dialog

        if ret == :next
          hostname_to_static_ips if wicked?

          # do not let Lan override us, #152218
          self.class.valid_dns_proposal = true

          # In InstHostname writing was delayed to do it with the rest of
          # network configuration in lan_proposal.
          # In FirstbootHostname it's probably safer to do it right away.
          write_config
        end

        ret
      end

    private

      def hostname_dialog
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
            MarginBox(
              1,
              1,
              VBox(
                Left("HOSTNAME"),
                Left("DHCP_HOSTNAME")
              )
            )
          )
        )

        ret = CWM.ShowAndRun(
          "widget_descr"       => @widget_descr_dns,
          "contents"           => contents,
          # dialog caption
          "caption"            => _("Hostname"),
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

      # Convenience method to check whether the current backend in use is
      # wicked or not
      #
      # @return [Boolean]
      def wicked?
        Yast::NetworkService.wicked?
      end

      # Convenience method to generate a default hostname
      def propose_hostname
        Yast::DNS.static = "linux-#{String.Random(4)}"
      end

      # Checks whether a default hostname should be proposed or not
      #
      # @return [Boolean]
      def propose_hostname?
        DNS.static.to_s.empty? || DNS.static == "linux"
      end

      # Convenience method to add the current hostname as an alias of any
      # static ip that does not have one
      #
      # FIXME: is this correct at all? what if there are multiple static ips
      # without aliases.
      def hostname_to_static_ips
        ips = static_ips.select { |ip| Yast::Host.names(ip).empty? }
        ips.each { |i| Yast::Host.Update(DNS.hostname, DNS.hostname, i) }
      end

      # Convenience method to obtain all the configured static ips
      #
      # @return [Array<String>]
      def static_ips
        ips = yast_config&.connections&.map { |c| c.all_ips.map { |i| i.address&.address&.to_s } }
        (ips || []).flatten.compact
      end

      # Convenience method to obtain the current network configuration
      #
      # @return [Y2Network::Config]
      def yast_config
        Yast::Lan.yast_config
      end

      # Convenience method to write the config changes
      def write_config
        Yast::Lan.write_config
      end
    end
  end
end
