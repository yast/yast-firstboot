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
require "yast2/execute"
require "y2firstboot/clients/user"
require "etc"
require "y2firstboot/wsl_config"

Yast.import "GetInstArgs"

module Y2Firstboot
  module Clients
    # Client to set up required configuration for WSL
    class WSL < Yast::Client
      def run
        return :back if Yast::GetInstArgs.going_back

        write_wsl_user
        setup_machine_id
        switch_product
        install_patterns

        :next
      end

    private

      # Writes the id of the user created in firstboot (if any) in order to allow to WSL launcher to
      # fetch it.
      #
      # WSL laucher fetches the user id from /run/wsl_firstboot_uid.
      def write_wsl_user
        user = Y2Firstboot::Clients::User.username

        return unless user

        uid = Etc.getpwnam(user).uid
        File.write("/run/wsl_firstboot_uid", uid)
      end

      # Sets up the machine id, if needed
      #
      # The machine id is expected to be generated on first boot, but WSL does not really boot.
      def setup_machine_id
        # systemd-machine-id-setup is smart enough to only populate /etc/machine-id when empty or
        # missing
        Yast::Execute.locally("/usr/bin/systemd-machine-id-setup")
      end

      def switch_product
        return unless Y2Firstboot::WSLConfig.instance.product_switched?

        product = Y2Firstboot::WSLConfig.instance.product
        installed_product = Y2Firstboot::WSLConfig.instance.installed_product

        Yast::Pkg.ResolvableRemove(installed_product, :product) if installed_product
        Yast::Pkg.ResolvableInstall(product, :product)
        # TODO: check if pkg commit is done later or if it is needed here
      end

      def install_patterns
        Y2Firstboot::WSLConfig.instance.patterns.each do |pattern|
          Yast::Pkg.ResolvableInstall(pattern, :pattern)
        end
      end
    end
  end
end
