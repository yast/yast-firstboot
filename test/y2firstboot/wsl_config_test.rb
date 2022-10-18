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

require_relative "../test_helper"
require "y2firstboot/wsl_config"

Yast.import "PackageSystem"

describe Y2Firstboot::WSLConfig do
  subject { described_class.instance }

  before do
    allow(Yast::PackageSystem).to receive(:EnsureTargetInit)
    allow(Yast::PackageSystem).to receive(:EnsureSourceInit)

    allow(Y2Packager::Resolvable)
      .to receive(:find).with(a_hash_including(kind: :product)).and_return([installed_product])
  end

  after do
    subject.instance_variable_set(:@installed_product, nil)
  end

  let(:installed_product) { nil }

  describe "#product_switched?" do
    before do
      subject.product = product
    end

    context "when there is an installed product" do
      let(:installed_product) { double(Y2Packager::Resolvable, name: "SLES", version: "15.4") }

      context "and there is no selected product" do
        let(:product) { nil }

        it "returns false" do
          expect(subject.product_switched?).to eq(false)
        end
      end

      context "and the selected product is the installed product" do
        let(:product) { { "name" => "SLES", "version" => "15.4" } }

        it "returns false" do
          expect(subject.product_switched?).to eq(false)
        end
      end

      context "and the selected product is the installed product with different version" do
        let(:product) { { "name" => "SLES", "version" => "15.3" } }

        it "returns true" do
          expect(subject.product_switched?).to eq(true)
        end
      end

      context "and the selected product is not the installed product" do
        let(:product) { { "name" => "SLED", "version" => "15.4" } }

        it "returns true" do
          expect(subject.product_switched?).to eq(true)
        end
      end
    end

    context "when there is no installed product" do
      let(:installed_product) { nil }

      let(:product) { "SLES" }

      it "returns false" do
        expect(subject.product_switched?).to eq(false)
      end
    end
  end

  describe "#installed_product" do
    context "when there is an installed product" do
      let(:installed_product) { double(Y2Packager::Resolvable, name: "SLES") }

      it "returns the installed product" do
        expect(subject.installed_product.name).to eq("SLES")
      end
    end

    context "when there is no installed product" do
      let(:installed_product) { nil }

      it "returns nil" do
        expect(subject.installed_product).to be_nil
      end
    end
  end
end
