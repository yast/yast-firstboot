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
  class WSLConfig
    include Singleton

    attr_accessor :product

    attr_accessor :patterns

    def initialize
      @patterns = []
    end

    def product_switched?
      return false unless installed_product && product

      installed_product != product
    end

    def installed_product
      @installed_product ||= find_installed_product&.name
    end

    private

    def find_installed_product
      init_package_system

      Y2Packager::Resolvable.find(kind: :product, status: :installed, category: "base").first
    end

    def init_package_system
      Yast.import "PackageSystem"

      Yast::PackageSystem.EnsureTargetInit
      Yast::PackageSystem.EnsureSourceInit
    end
  end
end
