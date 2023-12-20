# Copyright (c) [2022] SUSE LLC
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
require "ui/installation_dialog"
require "y2firstboot/wsl_config"

Yast.import "UI"

module Y2Firstboot
  module Dialogs
    # Dialog for selecting the product to use with WSL
    class WSLProductSelection < ::UI::InstallationDialog
      include Yast::I18n

      # Selected product
      #
      # @return [Hash]
      attr_reader :product

      # Whether the WSL GUI pattern was selected
      #
      # @return [Boolean]
      attr_reader :wsl_gui_pattern

      # Whether the WSL systemd pattern was selected
      #
      # @return [Boolean]
      attr_reader :wsl_systemd_pattern

      # Constructor
      #
      # @param products [Array<Hash>] All possible products
      # @param default_product [Hash] Product selected by default
      # @param wsl_gui_pattern [Boolean] Whether WSL GUI pattern is selected by default
      # @param wsl_systemd_pattern [Boolean] Whether WSL systemd pattern is selected by default
      def initialize(products, default_product: nil, wsl_gui_pattern: false,
        wsl_systemd_pattern: false)
        textdomain "firstboot"

        super()
        @products = products
        @product = default_product || products.first
        @wsl_gui_pattern = wsl_gui_pattern
        @wsl_systemd_pattern = wsl_systemd_pattern
      end

      def next_handler
        save
        super
      end

    protected

      def dialog_title
        # TRANSLATORS: dialog title
        _("Product Selection")
      end

      def dialog_content
        items = products.map { |p| item_for(p) }

        HSquash(
          VBox(
            RadioButtonGroup(
              Id(:product_selector),
              VBox(
                # TRANSLATORS: dialog heading
                Left(Heading(_("Select the product to use"))),
                VSpacing(1),
                *items
              )
            ),
            VSpacing(2),
            # TRANSLATORS:
            Left(Label(_("The WSL GUI pattern provides some needed packages for\n" \
              "a better experience with graphical applications in WSL."))),
            VSpacing(1),
            # TRANSLATORS: check box label
            Left(CheckBox(Id(:wsl_gui_pattern),
              _("Install WSL GUI pattern (requires registration)"),
              wsl_gui_pattern)),
            VSpacing(2),
            # TRANSLATORS:
            Left(Label(_("The WSL systemd pattern provides wsl.conf adjustment\n" \
              "and init symlink for systemd enablement in WSL."))),
            VSpacing(1),
            # TRANSLATORS: check box label
            Left(CheckBox(Id(:wsl_systemd_pattern),
              _("Install WSL systemd pattern (requires registration)"),
              wsl_systemd_pattern))
          )
        )
      end

      def help_text
        # TRANSLATORS: help text (1/3)
        _("<p>Select the product to use with Windows Subsystem for Linux (WSL). " \
          "Some products might require registration.</p>") +
          # TRANSLATORS: help text (2/3)
          _("<p>For smoother experience with graphical programs in WSL " \
              "the WSL GUI pattern provides recommended config, tools and libraries. " \
              "In that case the system needs to be registered as well.</p>") +
          # TRANSLATORS: help text (3/3)
          _("<p>For enablement of systemd in WSL the WSL systemd pattern provides wsl.conf " \
              "and /sbin/init adjustments. " \
              "In that case the system needs to be registered as well. " \
              "Also be aware that systemd enablement is in effect only after relaunch.</p>")
      end

    private

      # All possible products to select
      #
      # @return [Array<Hash>]
      attr_reader :products

      # Radio button for selecting a product
      #
      # @param product [Hash]
      def item_for(product)
        Left(
          RadioButton(
            Id(item_id(product)),
            product_label(product),
            item_id(product) == item_id(self.product)
          )
        )
      end

      # Id for the radio button
      #
      # @param product [Hash]
      # @return [String]
      def item_id(product)
        "#{product["name"]}:#{product["version"]}"
      end

      def product_label(product)
        label = product["display_name"]

        installed_product = WSLConfig.instance.installed_product
        if installed_product.name != product["name"] ||
            installed_product.version_version != product["version"]

          # TRANSLATORS: suffix displayed for the products which require registration,
          # %s is a product name like "SUSE Linux Enterprise Server 15 SP4"
          label = _("%s (requires registration)") % label
        end

        label
      end

      def save
        @wsl_gui_pattern = Yast::UI.QueryWidget(Id(:wsl_gui_pattern), :Value)
        @wsl_systemd_pattern = Yast::UI.QueryWidget(Id(:wsl_systemd_pattern), :Value)

        selected_id = Yast::UI.QueryWidget(Id(:product_selector), :Value)
        @product = products.find { |p| item_id(p) == selected_id }
      end
    end
  end
end
