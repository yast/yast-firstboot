#!/usr/bin/env rspec

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

require_relative "../../test_helper"
require "y2firstboot/clients/wsl"
require "y2firstboot/wsl_config"

describe Y2Firstboot::Clients::WSL do
  subject(:client) { described_class.new }

  describe "#run" do
    before do
      allow(Yast::GetInstArgs).to receive(:going_back).and_return(going_back)

      allow(Y2Firstboot::Clients::User).to receive(:username).and_return(username)

      allow(Etc).to receive(:getpwnam).with(username).and_return(user)

      allow(File).to receive(:write)

      allow(Yast::Execute).to receive(:locally)

      allow(Y2Firstboot::WSLConfig.instance)
        .to receive(:installed_product).and_return(installed_product)

      allow(Y2Firstboot::WSLConfig.instance)
        .to receive(:product).and_return(product)

      allow(Yast::Pkg).to receive(:ResolvableRemove)
      allow(Yast::Pkg).to receive(:ResolvableInstall)
    end

    let(:going_back) { nil }

    let(:username) { nil }

    let(:user) { nil }

    let(:installed_product) { nil }

    let(:product) { nil }

    context "when going back from another client" do
      let(:going_back) { true }

      it "does nothing" do
        expect(File).to_not receive(:write).with(/wsl_firstboot_uid/, anything)
        expect(Yast::Execute).to_not receive(:locally).with(/systemd-machine-id-setup/)

        subject.run
      end

      it "returns :back" do
        expect(subject.run).to eq(:back)
      end
    end

    context "when not going back from another client" do
      let(:going_back) { false }

      it "sets up the machine id" do
        expect(Yast::Execute).to receive(:locally).with(/systemd-machine-id-setup/)

        subject.run
      end

      context "when a user was created in firstboot" do
        let(:username) { "test" }

        let(:user) { Struct.new(:uid).new(1001) }

        it "writes the user uid to /run/wsl_firstboot_uid" do
          expect(File).to receive(:write).with("/run/wsl_firstboot_uid", 1001)

          subject.run
        end
      end

      context "when a user was not created in firstboot" do
        let(:username) { nil }

        it "does not write to /run/wsl_firstboot_uid" do
          expect(File).to_not receive(:write).with("/run/wsl_firstboot_uid", anything)

          subject.run
        end
      end

      context "when the product was switched" do
        let(:installed_product) { double(Y2Packager::Resolvable, name: "SLES", version: "15.4") }
        let(:product) { { "name" => "SLED", "version" => "15.4" } }

        it "removes the installed product" do
          expect(Yast::Pkg).to receive(:ResolvableRemove).with("SLES", :product)

          subject.run
        end

        it "installs the selected product" do
          expect(Yast::Pkg).to receive(:ResolvableInstall).with("SLED", :product)

          subject.run
        end
      end

      context "when the product was not switched" do
        let(:installed_product) { double(Y2Packager::Resolvable, name: "SLES", version: "15.4") }
        let(:product) { { "name" => "SLES", "version" => "15.4" } }

        it "does remove the installed product" do
          expect(Yast::Pkg).to_not receive(:ResolvableRemove).with("SLES", :product)

          subject.run
        end

        it "does not install another product" do
          expect(Yast::Pkg).to_not receive(:ResolvableInstall).with(anything, :product)

          subject.run
        end
      end

      context "when there are selected patterns" do
        before do
          Y2Firstboot::WSLConfig.instance.patterns = ["wsl_gui", "test"]
        end

        it "installs the selected patterns" do
          expect(Yast::Pkg).to receive(:ResolvableInstall).with("wsl_gui", :pattern)
          expect(Yast::Pkg).to receive(:ResolvableInstall).with("test", :pattern)

          subject.run
        end
      end
    end
  end
end
