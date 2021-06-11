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
require "y2firstboot/clients/user"

describe Y2Firstboot::Clients::User do
  subject(:client) { described_class.new }

  describe "#run" do
    let(:dialog) { instance_double(Yast::InstUserFirstDialog, run: result) }
    let(:result) { :next }

    let(:user)     { Y2Users::User.new(username) }
    let(:username) { "chamaleon" }
    let(:attached) { false }

    let(:system_config)      { Y2Users::Config.new }
    let(:system_config_copy) { Y2Users::Config.new }
    let(:config_manager)     { Y2Users::ConfigManager.instance }

    let(:writer) { instance_double(Y2Users::Linux::Writer, write: []) }

    before do
      allow(Yast::InstUserFirstDialog).to receive(:new).and_return(dialog)

      allow(Y2Users::Linux::Writer).to receive(:new).and_return(writer)

      allow(subject).to receive(:user).and_return(user)
      allow(user).to receive(:attached?).and_return(attached)

      allow(system_config).to receive(:copy).and_return(system_config_copy)
      allow(config_manager).to receive(:system).and_return(system_config)
    end

    it "executes the inst_user_first dialog" do
      expect(Yast::InstUserFirstDialog).to receive(:new).with(system_config_copy, user: user)
      expect(dialog).to receive(:run)

      subject.run
    end

    it "returns the dialog result" do
      expect(subject.run).to eq(result)
    end

    context "when dialog result is :next" do
      it "updates the users target configuration" do
        expect(config_manager).to receive(:target=).with(system_config_copy)

        subject.run
      end

      it "writes the users configuration" do
        expect(Y2Users::Linux::Writer).to receive(:new).with(system_config_copy, system_config)
        expect(writer).to receive(:write)

        subject.run
      end

      context "and user still attached to the config" do
        let(:attached) { true }

        it "saves the username for future reference" do
          expect(described_class).to receive(:username=).with(username)

          subject.run
        end
      end

      context "but user is not attached to the config" do
        let(:attached) { false }

        it "deletes username reference" do
          expect(described_class).to receive(:username=).with(nil)

          subject.run
        end
      end
    end

    context "when dialog result is not :next" do
      let(:result) { :back }

      it "does not modify stored username" do
        expect(described_class).to_not receive(:username=)

        subject.run
      end

      it "does not write the users configuration" do
        expect(Y2Users::Linux::Writer).to_not receive(:new)
        expect(writer).to_not receive(:write)

        subject.run
      end
    end
  end
end
