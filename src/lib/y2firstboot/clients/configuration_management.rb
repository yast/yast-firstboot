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
require "y2configuration_management/clients/provision"
require "y2configuration_management/configurators/base"

Yast.import "ProductFeatures"
Yast.import "PackageSystem"
Yast.import "GetInstArgs"

module Y2Firstboot
  module Clients
    # This client is meant to be used in firstboot
    class ConfigurationManagement
      # Runs the client
      def run
        configurator = Y2ConfigurationManagement::Configurators::Base.for(config)
        result = configurator.prepare(reverse: Yast::GetInstArgs.going_back)
        return result unless result == :finish

        provision ? :next : :abort
      end

    private

      # Runs the provisioner
      #
      # @return [Boolean] true if it ran successfully; false otherwise.
      def provision
        if !Yast::PackageSystem.CheckAndInstallPackages(configurator.packages.fetch("install", []))
          return false
        end

        Y2ConfigurationManagement::Clients::Provision.new.run
      end

      # @return [Hash] Fixed settings (these settings cannot be overriden as this is the only
      #   supported scenario)
      FIXED_SETTINGS = { "type" => "salt", "mode" => "masterless" }.freeze

      # Returns the configuration management configuration
      #
      # It relies in the configuration found in the control file.
      #
      # @return [Y2ConfigurationManagement::Configurations::Base]
      def config
        current_config = Y2ConfigurationManagement::Configurations::Base.current
        return current_config if current_config

        settings = Yast::ProductFeatures.GetSection("configuration_management")
          .merge(FIXED_SETTINGS)
        Y2ConfigurationManagement::Configurations::Base.current =
          Y2ConfigurationManagement::Configurations::Base.import(settings)
      end

      def configurator
        current_configurator = Y2ConfigurationManagement::Configurators::Base.current
        return current_configurator if current_configurator

        Y2ConfigurationManagement::Configurators::Base.current =
          Y2ConfigurationManagement::Configurators::Base.for(config)
      end
    end
  end
end
