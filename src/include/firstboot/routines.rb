# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/firstboot/routines.ycp
# Package:	Configuration of Firstboot
# Summary:	Routines
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
#
module Yast
  module FirstbootRoutinesInclude
    def initialize_firstboot_routines(include_target)
      Yast.import "XML"
    end

    # Setup XML for alice
    # @return void
    #
    def XmlSetup
      doc = {}
      Ops.set(doc, "cdataSections", [])
      Ops.set(
        doc,
        "listEntries",
        {
          "workflows"        => "workflow",
          "modules"          => "module",
          "proposal_modules" => "proposal_module",
          "proposals"        => "proposal"
        }
      )

      Ops.set(doc, "rootElement", "productDefines")
      Ops.set(doc, "systemID", "/usr/share/YaST2/control/control.dtd")
      Ops.set(doc, "nameSpace", "http://www.suse.com/1.0/yast2ns")
      Ops.set(doc, "typeNamespace", "http://www.suse.com/1.0/configns")
      XML.xmlCreateDoc(:firstboot, doc)
      nil
    end
  end
end
