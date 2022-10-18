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

module Y2Firstboot
  module Clients
    # Client for selecting the product to use with WSL (jsc#PED-1380)
    #
    # It also allows to indicate whether to install WSL GUI pattern (jsc#PM-3439).
    class WSLProductSelection < Yast::Client
      # Runs the client
      #
      # @throw [RuntimeError] see {#require_registration}.
      #
      # @return [Symbol]
      def run
        require_registration

        return :next if products.none?

        dialog = Dialogs::WSLProductSelection.new(products,
          default_product: product,
          wsl_gui_pattern: wsl_gui_pattern?)

        result = dialog.run

        save(product: dialog.product, wsl_gui_pattern: dialog.wsl_gui_pattern) if result == :next

        result
      end

    private

      WSL_GUI_PATTERN = "wsl_gui".freeze
      private_constant :WSL_GUI_PATTERN

      # Saves changes
      #
      # @param product [Hash] Selected product
      # @param wsl_gui_pattern [Boolean] Whether to install WSL GUI pattern
      def save(product:, wsl_gui_pattern:)
        self.product = product
        self.wsl_gui_pattern = wsl_gui_pattern
        update_registration
      end

      # Product to use
      #
      # @see {ẂSLConfig}
      #
      # @return [Hash]
      def product
        WSLConfig.instance.product || default_product
      end

      # Sets the product to use
      #
      # @see {ẂSLConfig}
      #
      # @param value [Hash] A product
      def product=(value)
        WSLConfig.instance.product = value
      end

      # Whether the WSL GUI pattern should be installed
      #
      # @see {ẂSLConfig}
      #
      # @return [Boolean]
      def wsl_gui_pattern?
        WSLConfig.instance.patterns.include?(WSL_GUI_PATTERN)
      end

      # Sets whether to install the WSL GUI pattern
      #
      # @param value [Boolean]
      def wsl_gui_pattern=(value)
        if value
          WSLConfig.instance.patterns.push(WSL_GUI_PATTERN).uniq!
        else
          WSLConfig.instance.patterns.delete(WSL_GUI_PATTERN)
        end
      end

      # Updates values stored in registration
      #
      # Those values indicates to registration what product was selected and whether the product
      # has to be registered.
      #
      # @see {Registration::Storage::InstallationOptions}
      def update_registration
        yaml_product = WSLConfig.instance.product
        force_registration = WSLConfig.instance.product_switched? || wsl_gui_pattern?

        Registration::Storage::InstallationOptions.instance.yaml_product = yaml_product
        Registration::Storage::InstallationOptions.instance.force_registration = force_registration
      end

      # Name of the default product to use from YAML file
      #
      # @return [String]
      def default_product
        return nil if products.none?

        products.find { |p| p["default"] } || products.first
      end

      # All products from YAML file
      #
      # @return [Array<Hash>]
      def products
        @products ||= Registration::YamlProductsReader.new("/tmp/products.yml").read
      end

      # Tries to require yast2-registration files
      #
      # @note yast2-registration might not be available for some products (e.g., openSUSE).
      #
      # @throw [RuntimeError] if yast2-registration files cannot be loaded
      def require_registration
        require "registration/yaml_products_reader"
        require "registration/storage"
      rescue LoadError
        raise "yast2-registration >= 4.4.23 required"
      end
    end
  end
end
