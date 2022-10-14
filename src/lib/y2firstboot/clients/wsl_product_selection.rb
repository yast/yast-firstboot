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
require "y2firstboot/wsl_config"
require "y2firstboot/dialogs/wsl_product_selection"
require "registration/yaml_products_reader"
require "registration/storage"

module Y2Firstboot
  module Clients
    class WSLProductSelection < Yast::Client
      def run
        return :next if products.none?

        dialog = Dialogs::WSLProductSelection.new(products,
          default_product: product,
          wsl_gui_pattern: wsl_gui_pattern?)

        result = dialog.run

        save(product: dialog.product, wsl_gui_pattern: dialog.wsl_gui_pattern) if result == :next

        result
      end

    private

      def save(product:, wsl_gui_pattern:)
        self.product = product
        self.wsl_gui_pattern = wsl_gui_pattern
        update_registration
      end

      def product
        WSLConfig.instance.product || default_product
      end

      def product=(value)
        WSLConfig.instance.product = value
      end

      def wsl_gui_pattern?
        WSLConfig.instance.patterns.include?("wsl_gui")
      end

      def wsl_gui_pattern=(value)
        if value
          WSLConfig.instance.patterns.push("wsl_gui").uniq!
        else
          WSLConfig.instance.patterns.delete("wsl_gui")
        end
      end

      def update_registration
        force_registration = WSLConfig.instance.product_switched? || wsl_gui_pattern?
        yaml_product = products.find { |p| p["name"] == WSLConfig.instance.product }

        Registration::Storage::InstallationOptions.instance.force_registration = force_registration
        Registration::Storage::InstallationOptions.instance.yaml_product = yaml_product
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
