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
require "y2firstboot/config"
require "y2firstboot/dialogs/wsl_product_selection"
require "registration/yaml_products_reader"

module Y2Firstboot
  module Clients
    class WSLProductSelection < Yast::Client
      def run
        return :next if products.none?

        dialog = Dialogs::WSLProductSelection.new(products,
          default_product: product,
          wsl_gui_pattern: wsl_gui_pattern?)

        result = dialog.run

        if result == :next
          self.product = dialog.product
          self.wsl_gui_pattern = dialog.wsl_gui_pattern
        end

        result
      end

    private

      def product
        Config.instance.product || default_product
      end

      def product=(value)
        Config.instance.product = value
      end

      def wsl_gui_pattern?
        Config.instance.patterns.include?("wsl_gui")
      end

      def wsl_gui_pattern=(value)
        if value
          Config.instance.patterns.push("wsl_gui").uniq!
        else
          Config.instance.patterns.delete("wsl_gui")
        end
      end

      def default_product
        return nil if products.none?

        default = products.find { |p| p["default"] } || products.first
        default["name"]
      end

      def products
        @products ||= Registration::YamlProductsReader.new.read
      end
    end
  end
end
