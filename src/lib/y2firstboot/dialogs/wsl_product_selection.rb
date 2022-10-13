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
    class WSLProductSelection < ::UI::InstallationDialog
      include Yast::I18n

      attr_reader :product

      attr_reader :wsl_gui_pattern

      def initialize(products, default_product: nil, wsl_gui_pattern: false)
        textdomain "firstboot"

        super()
        @products = products
        @product = default_product || products.first&.fetch("name")
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
            VSpacing(2),
            Left(CheckBox(Id(:wsl_gui_pattern), _("Install WSL GUI pattern"), wsl_gui_pattern))
          )
        )
      end

      # TODO
      def help_text
        _("The WSL GUI pattern installs some needed dependencies for " \
          "a nice out-of-the-box experience with GUI applications on WSL.")
      end

      private

      attr_reader :products

      def item_for(product)
        Left(
          RadioButton(
            Id(product["name"]),
            product["display_name"],
            product["name"] == self.product
          )
        )
      end

      def save
        @wsl_gui_pattern = Yast::UI.QueryWidget(Id(:wsl_gui_pattern), :Value)
        @product = Yast::UI.QueryWidget(Id(:product_selector), :Value)
      end
    end
  end
end
