# encoding: utf-8

# Copyright (c) [2019] SUSE LLC
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

Yast.import "UI"
Yast.import "Misc"
Yast.import "GetInstArgs"

module Y2Firstboot
  module Clients
    # Client that allows to display license texts during the firstboot
    # configuration.
    #
    # NOTE: for backward compatibility, it can display the Novell licenses if a
    # valid path is given through FIRSTBOOT_NOVELL_LICENCE_DIR
    class Licenses < Yast::Client
      def initialize
        textdomain "firstboot"

        @args = GetInstArgs.argmap
      end

      def run
        result = WFM.CallFunction("inst_license", inst_license_args)

        UI.CloseDialog if result == :halt

        result
      end

    private

      attr_accessor :args

      # Build, log, and returns args to be used for calling InstLicense client
      #
      # @return [Array]
      def inst_license_args
        args["action"] = refusal_action
        args["directories"] = directories

        Builtins.y2milestone("inst_license options: %1", args)

        [args]
      end

      # Action to perform if the user's refusal to accept the license agreement
      #
      # @return [String]
      def refusal_action
        Misc.SysconfigRead(path(".sysconfig.firstboot.LICENSE_REFUSAL_ACTION"), "abort")
      end

      # Directories in which look for the license agreement texts
      #
      # NOTE: if that result in an empty list, {Yast::InstLicenseClient} will do an extra attemp to
      # look for the license agreement in the path given as "base_product_license_directory" global
      # param through the control file.
      #
      # @return [Array<String>] license agreement paths
      def directories
        return module_license_directories if module_license_directories.any?

        sysconfig_license_directories
      end

      # Directories defined by the module arguments
      #
      # NOTE: right now license module can only define a directory path, but it could be extended to
      # support more than one (e.g., by a "directories" list).
      #
      # @return [Array<String>] license agreement paths
      def module_license_directories
        directories = [
          args["directory"]
        ]

        directories.map(&:to_s).reject(&:empty?)
      end

      # Directories defined in the sysconfig firstboot file
      #
      # @return [Array<String>] license agreement paths
      def sysconfig_license_directories
        directories = [
          Misc.SysconfigRead(path(".sysconfig.firstboot.FIRSTBOOT_LICENSE_DIR"), ""),
          Misc.SysconfigRead(path(".sysconfig.firstboot.FIRSTBOOT_NOVELL_LICENSE_DIR"), "")
        ]

        directories.uniq.reject(&:empty?)
      end
    end
  end
end
