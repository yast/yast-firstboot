# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
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
require "configuration_management/clients/provision"
require "configuration_management/configurators/base"

Yast.import "ProductFeatures"
Yast.import "PackageSystem"

module Y2Firstboot
  module Clients
    # This client is meant to be used in firstboot
    class ConfigurationManagement
      # Runs the client
      def run
        configurator = Yast::ConfigurationManagement::Configurators::Base.for(config)
        return :abort unless configurator.prepare
        if !Yast::PackageSystem.CheckAndInstallPackages(configurator.packages.fetch("install", []))
          return :abort
        end
        Yast::ConfigurationManagement::Clients::Provision.new.run
        :auto
      end

    private

      # @return [Hash] Fixed settings (these settings cannot be overriden as this is the only
      #   supported scenario)
      FIXED_SETTINGS = { "type" => "salt", "mode" => "masterless" }.freeze

      # Returns the configuration management configuration
      #
      # It relies in the configuration found in the control file.
      #
      # @return [Yast::ConfigurationManagement::Configurations::Base]
      def config
        settings = Yast::ProductFeatures.GetSection("configuration_management")
                                        .merge(FIXED_SETTINGS)
        Yast::ConfigurationManagement::Configurations::Base.import(settings)
      end
    end
  end
end
