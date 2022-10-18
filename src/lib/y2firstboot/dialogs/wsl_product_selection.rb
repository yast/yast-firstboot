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

      # Constructor
      #
      # @param products [Array<Hash>] All possible products
      # @param default_product [Hash] Product selected by default
      # @param wsl_gui_pattern [Boolean] Whether WSL GUI pattern is selected by default
      def initialize(products, default_product: nil, wsl_gui_pattern: false)
        textdomain "firstboot"

        super()
        @products = products
        @product = default_product || products.first
        @wsl_gui_pattern = wsl_gui_pattern
      end

      def next_handler
        save
        super
      end

    protected

      def dialog_title
        _("Product Selection")
      end

      def dialog_content
        items = products.map { |p| item_for(p) }

        HSquash(
          VBox(
            RadioButtonGroup(
              Id(:product_selector),
              VBox(
                Left(Label(_("Select the product to use"))),
                *items
              )
            ),
            VSpacing(1),
            Label(_("The WSL GUI pattern provides some needed packages for\n" \
              "a better experience with graphical applications on WSL.")),
            Left(CheckBox(Id(:wsl_gui_pattern), _("Install WSL GUI pattern"), wsl_gui_pattern))
          )
        )
      end

      def help_text
        _("Select the product to use with Windows Subsystem for Linux (WSL). \n\n" \
          "Registering the product might be required in order to configure the selected product. " \
          "Registration is also required to install the WSL GUI pattern.")
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
            product["display_name"],
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

      def save
        @wsl_gui_pattern = Yast::UI.QueryWidget(Id(:wsl_gui_pattern), :Value)

        name, version = Yast::UI.QueryWidget(Id(:product_selector), :Value).split(":")
        @product = products.find { |p| p["name"] == name && p["version"] == version }
      end
    end
  end
end
