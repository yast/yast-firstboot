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
    let(:password) { nil }
    let(:attached) { false }

    let(:system_config)      { Y2Users::Config.new }
    let(:system_config_copy) { Y2Users::Config.new }
    let(:config_manager)     { Y2Users::ConfigManager.instance }

    let(:writer) { instance_double(Y2Users::Linux::Writer, write: []) }

    before do
      user.password = password
      system_config_copy.attach([user])

      allow(Yast::InstUserFirstDialog).to receive(:new).and_return(dialog)

      allow(Y2Users::Linux::Writer).to receive(:new).and_return(writer)

      allow(subject).to receive(:user).and_return(user)
      allow(user).to receive(:attached?).and_return(attached)

      allow(system_config).to receive(:copy).and_return(system_config_copy)
      allow(config_manager).to receive(:system).and_return(system_config)
    end

    context "when user has an encrypted password" do
      let(:password) { Y2Users::Password.create_encrypted("s3cr3t") }

      it "resets the user password" do
        expect(user.password.value).to be_encrypted

        subject.run

        expect(user.password.value).to_not be_encrypted
        expect(user.password_content).to be_empty
      end
    end

    context "when user has a plain password" do
      let(:password) { Y2Users::Password.create_plain("s3cr3t") }

      it "does not reset the user password" do
        expect(user.password_content).to eq("s3cr3t")

        subject.run

        expect(user.password_content).to eq("s3cr3t")
      end
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
      it "writes the users configuration" do
        expect(Y2Users::Linux::Writer).to receive(:new).with(system_config_copy, system_config)
        expect(writer).to receive(:write)

        subject.run
      end
    end

    context "when dialog result is not :next" do
      let(:result) { :back }

      it "does not write the users configuration" do
        expect(Y2Users::Linux::Writer).to_not receive(:new)
        expect(writer).to_not receive(:write)

        subject.run
      end
    end

    context "if user is attached" do
      let(:attached) { true }

      it "saves the username for future reference" do
        expect(described_class).to receive(:username=).with(username)

        subject.run
      end
    end

    context "if user is not attached" do
      let(:attached) { false }

      it "deletes username reference" do
        expect(described_class).to receive(:username=).with(nil)

        subject.run
      end
    end
  end
end
