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
require "y2firstboot/dialogs/wsl_product_selection"

module Y2Firstboot
  module Clients
    class WSLProductSelection < Yast::Client
      class << self
        attr_accessor :product

        attr_accessor :wsl_gui_pattern
      end

      def run
        return :next if products.none?

        dialog = Dialogs::WSLProductSelection.new(products, default_product: default_product)
        result = dialog.run

        if result == :next
          self.class.product = dialog.product
          self.class.wsl_gui_pattern = dialog.wsl_gui_pattern
        end

        result
      end

    private

      def default_product
        products.find { |p| p.id == :sles }
      end

      # FIXME: read products from yaml file
      def products
        [
          FakeProduct.new(:sles, "SUSE Linux Entreprise Server SP4"),
          FakeProduct.new(:sled, "SUSE Linux Entreprise Desktop SP4")
        ]
      end

      FakeProduct = Struct.new(:id, :label)
    end
  end
end
