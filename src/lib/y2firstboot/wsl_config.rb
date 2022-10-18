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

require "singleton"
require "y2packager/resolvable"

module Y2Firstboot
  # Configuration for WSL firstboot
  class WSLConfig
    include Singleton

    # Product to use with WSL
    #
    # @return [Hash, nil]
    attr_accessor :product

    # Patterns to install as part of the WSL configuration
    #
    # @return [Array<String>]
    attr_accessor :patterns

    def initialize
      @patterns = []
    end

    # Whether the selected product is not the installed product
    #
    # @return [Boolean]
    def product_switched?
      return false unless installed_product && product

      installed_product.name != product["name"] ||
        installed_product.version != product["version"]
    end

    # Current installed product
    #
    # @return [Y2Packager::Resolvable, nil]
    def installed_product
      @installed_product ||= find_installed_product
    end

  private

    # Finds the currently installed product
    #
    # @return [Y2Packager::Resolvable, nil]
    def find_installed_product
      init_package_system
      Y2Packager::Resolvable.find(kind: :product, status: :installed, category: "base").first
    end

    # Initializes the package system
    def init_package_system
      Yast.import "PackageSystem"

      Yast::PackageSystem.EnsureTargetInit
      Yast::PackageSystem.EnsureSourceInit
    end
  end
end
