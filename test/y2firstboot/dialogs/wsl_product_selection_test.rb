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
require "y2firstboot/dialogs/wsl_product_selection"

Yast.import "UI"

describe Y2Firstboot::Dialogs::WSLProductSelection do
  include Yast::UIShortcuts

  def find_widget(regexp, content)
    regexp = regexp.to_s unless regexp.is_a?(Regexp)

    content.nested_find do |element|
      next unless element.is_a?(Yast::Term)

      element.params.any? do |param|
        param.is_a?(Yast::Term) &&
          param.value == :id &&
          regexp.match?(param.params.first.to_s)
      end
    end
  end

  subject do
    described_class.new(products,
      default_product: default_product, wsl_gui_pattern: wsl_gui_pattern)
  end

  let(:products) { [sles, sled] }
  let(:sles) { { "name" => "SLES", "version" => "15.4" } }
  let(:sled) { { "name" => "SLED", "version" => "15.4" } }

  let(:default_product) { sled }
  let(:wsl_gui_pattern) { false }

  describe "#dialog_content" do
    it "shows radio button box for selecting the product" do
      widget = find_widget(:product_selector, subject.send(:dialog_content))

      expect(widget).to_not be_nil
    end

    it "shows a radio button for each product" do
      products.each do |product|
        name = product["name"]
        widget = find_widget(/#{name}/, subject.send(:dialog_content))
        expect(widget).to_not be_nil
      end
    end

    it "shows a check box for selecting the WSL GUI pattern" do
      widget = find_widget(:wsl_gui_pattern, subject.send(:dialog_content))

      expect(widget).to_not be_nil
    end

    it "automatically selects the default product" do
      widget = find_widget(/SLED/, subject.send(:dialog_content))

      expect(widget.params.last).to eq(true)
    end

    context "when WSL GUI pattern is indicated as selected" do
      let(:wsl_gui_pattern) { true }

      it "selects WSL GUI pattern checkbox by default" do
        widget = find_widget(:wsl_gui_pattern, subject.send(:dialog_content))

        expect(widget.params.last).to eq(true)
      end
    end

    context "when WSL GUI pattern is not indicated as selected" do
      let(:wsl_gui_pattern) { false }

      it "does not select WSL GUI pattern checkbox by default" do
        widget = find_widget(:wsl_gui_pattern, subject.send(:dialog_content))

        expect(widget.params.last).to eq(false)
      end
    end
  end

  describe "#next_handler" do
    before do
      allow(Yast::UI).to receive(:QueryWidget).and_call_original
      allow(Yast::UI).to receive(:QueryWidget).with(Id(:wsl_gui_pattern), :Value).and_return(true)
      allow(Yast::UI).to receive(:QueryWidget).with(Id(:product_selector), :Value)
        .and_return("SLES:15.4")
    end

    it "saves whether the WSL GUI pattern checkbox was selected" do
      expect(subject.wsl_gui_pattern).to eq(false)

      subject.next_handler

      expect(subject.wsl_gui_pattern).to eq(true)
    end

    it "saves the selected product" do
      expect(subject.product).to eq(sled)

      subject.next_handler

      expect(subject.product).to eq(sles)
    end
  end
end
