#!/usr/bin/env rspec
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

require_relative "../../test_helper"
require "y2firstboot/clients/configuration_management"
require "configuration_management/configurators/salt"

describe Y2Firstboot::Clients::ConfigurationManagement do
  subject(:client) { described_class.new }

  describe "#run" do
    let(:provisioner) do
      instance_double(Yast::ConfigurationManagement::Clients::Provision, run: nil)
    end
    let(:configurator) do
      instance_double(
        Yast::ConfigurationManagement::Configurators::Salt, prepare: true, packages: packages
      )
    end
    let(:packages) { { "install" => ["salt"] } }
    let(:settings) { { "states_roots" => ["/srv/salt"] } }

    before do
      allow(Yast::ProductFeatures).to receive(:GetSection)
        .with("configuration_management")
        .and_return(settings)
      allow(Yast::ConfigurationManagement::Configurators::Base).to receive(:for)
        .and_return(configurator)
      allow(Yast::ConfigurationManagement::Clients::Provision).to receive(:new)
        .and_return(provisioner)
      allow(Yast::PackageSystem).to receive(:CheckAndInstallPackages).and_return(true)
    end

    it "uses the configuration from the control file" do
      expect(Yast::ConfigurationManagement::Configurators::Base).to receive(:for) do |config|
        expect(config.states_roots).to include(Pathname.new("/srv/salt"))
        configurator
      end
      client.run
    end

    it "runs the configuration management system" do
      expect(provisioner).to receive(:run)
      client.run
    end

    it "ensures that needed packages are installed" do
      expect(Yast::PackageSystem).to receive(:CheckAndInstallPackages).with(["salt"])
        .and_return(true)
      client.run
    end

    it "returns :auto" do
      expect(client.run).to eq(:auto)
    end

    context "when type or mode are specified in the configuration" do
      let(:settings) { { "type" => "puppet", "mode" => "client" } }

      it "forces type and mode" do
        expect(Yast::ConfigurationManagement::Configurators::Base).to receive(:for)
          .with(an_object_having_attributes(type: "salt", mode: :masterless))
          .and_return(configurator)
        client.run
      end
    end

    context "when no settings are specified" do
      let(:settings) { {} }

      it "uses the default configuration" do
        expect(Yast::ConfigurationManagement::Configurators::Base).to receive(:for)
          .with(an_object_having_attributes(type: "salt")).and_return(configurator)
        client.run
      end
    end
  end
end
