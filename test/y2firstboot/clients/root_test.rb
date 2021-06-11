#!/usr/bin/env rspec
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
require "y2firstboot/clients/root"

describe Y2Firstboot::Clients::Root do
  subject(:client) { described_class.new }

  describe "#run" do
    let(:inst_root_dialog) { instance_double(Yast::InstRootFirstDialog, run: result) }
    let(:writer) { instance_double(Y2Users::Linux::Writer, write: []) }

    let(:target_config)      { Y2Users::Config.new }
    let(:system_config)      { Y2Users::Config.new }
    let(:system_config_copy) { Y2Users::Config.new }
    let(:config_manager)     { Y2Users::ConfigManager.instance }

    before do
      allow(Yast::InstRootFirstDialog).to receive(:new).and_return(inst_root_dialog)

      allow(Y2Users::Linux::Writer).to receive(:new).and_return(writer)

      allow(system_config).to receive(:copy).and_return(system_config_copy)
      allow(config_manager).to receive(:target).and_return(target_config)
      allow(config_manager).to receive(:system).and_return(system_config)
    end

    context "when inst_root_dialog result is :next" do
      let(:result) { :next }

      it "updates users target configuration" do
        expect(config_manager).to receive(:target=).with(system_config_copy)

        subject.run
      end

      it "writes the target users configuration" do
        expect(Y2Users::Linux::Writer).to receive(:new).with(target_config, system_config)
        expect(writer).to receive(:write)

        subject.run
      end
    end

    context "when inst_root_dialog result is not :next" do
      let(:result) { :back }

      it "does not update users target configuration" do
        expect(config_manager).to_not receive(:target=)

        subject.run
      end

      it "does not write users configuration" do
        expect(Y2Users::Linux::Writer).to_not receive(:new)
        expect(writer).to_not receive(:write)

        subject.run
      end
    end
  end
end
