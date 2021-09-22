#!/usr/bin/env rspec

# Copyright (c) [2018-2021] SUSE LLC
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
    before do
      allow(Yast::InstRootFirstDialog).to receive(:new).and_return(dialog)

      allow_any_instance_of(Y2Users::Linux::Writer).to receive(:write)

      allow(Y2Users::ConfigManager.instance).to receive(:system).and_return(system_config)

      allow(system_config).to receive(:copy).and_return(config)
    end

    let(:system_config) { Y2Users::Config.new.attach(root, user) }

    let(:config) { system_config.copy }

    let(:root) do
      Y2Users::User.create_root.tap do |root|
        root.password = Y2Users::Password.create_encrypted("$xaadfd545dft")
      end
    end

    let(:user) do
      Y2Users::User.new("test").tap do |user|
        user.password = Y2Users::Password.create_encrypted("$xa9545dft")
      end
    end

    let(:dialog) { instance_double(Yast::InstRootFirstDialog, run: dialog_result) }

    let(:dialog_result) { :back }

    context "if the client was forced to be executed" do
      before do
        allow(Yast::GetInstArgs).to receive(:argmap).and_return("force" => true)
      end

      it "opens the dialog for configuring root" do
        expect(dialog).to receive(:run)

        subject.run
      end

      it "sets the plain password to the root user" do
        Y2Firstboot::Clients::User.root_password = "S3cr3T"

        expect(Yast::InstRootFirstDialog).to receive(:new) do |_root|
          expect(config.users.root.password_content).to eq("S3cr3T")
        end.and_return(dialog)

        subject.run
      end
    end

    context "if the client was not forced to be executed" do
      before do
        allow(Yast::GetInstArgs).to receive(:argmap).and_return("force" => false)
      end

      context "and the user password was used for root" do
        before do
          Y2Firstboot::Clients::User.user_password = "S3cr3T"
          Y2Firstboot::Clients::User.root_password = "S3cr3T"
        end

        it "does not open the dialog for configuring root" do
          expect(dialog).to_not receive(:run)

          subject.run
        end

        it "returns :auto" do
          expect(subject.run).to eq(:auto)
        end
      end

      context "and the user password was not used for root" do
        before do
          Y2Firstboot::Clients::User.user_password = "S3cr3T"
          Y2Firstboot::Clients::User.root_password = "root-S3cr3T"
        end

        it "opens the dialog for configuring root" do
          expect(dialog).to receive(:run)

          subject.run
        end

        it "sets the plain password to the root user" do
          expect(Yast::InstRootFirstDialog).to receive(:new) do |_root|
            expect(config.users.root.password_content).to eq("root-S3cr3T")
          end.and_return(dialog)

          subject.run
        end
      end
    end

    context "when the dialog result is :next" do
      let(:dialog_result) { :next }
      let(:commit_config) { Y2Users::CommitConfig.new }
      let(:commit_config_collection) { Y2Users::CommitConfigCollection.new }

      before do
        allow(Y2Users::CommitConfig).to receive(:new).and_return(commit_config)
        allow(Y2Users::CommitConfigCollection).to receive(:new).and_return(commit_config_collection)

        Y2Firstboot::Clients::User.user_password = "S3cr3T"
        Y2Firstboot::Clients::User.root_password = "root-S3cr3T"
      end

      it "prepares commit configuration" do
        expect(commit_config).to receive(:username=).with("root")

        expect(commit_config).to_not receive(:move_home=)
        expect(commit_config).to_not receive(:use_skel=)
        expect(commit_config).to_not receive(:adapt_home_ownership=)

        expect(commit_config_collection).to receive(:add).with(commit_config)

        subject.run
      end

      it "prepares and writes the config to the system" do
        expect(Y2Users::Linux::Writer).to receive(:new)
          .with(config, system_config, commit_config_collection).and_call_original

        subject.run
      end

      it "updates the plain root password for the next run" do
        expect(Yast::InstRootFirstDialog).to receive(:new) do |root|
          root.password = Y2Users::Password.create_plain("root-more-S3cr3T")
        end.and_return(dialog)

        subject.run

        expect(Y2Firstboot::Clients::User.root_password).to eq("root-more-S3cr3T")
      end
    end

    context "when dialog result is not :next" do
      let(:dialog_result) { :back }

      before do
        Y2Firstboot::Clients::User.user_password = "S3cr3T"
        Y2Firstboot::Clients::User.root_password = "root-S3cr3T"
      end

      it "does not write the users configuration" do
        expect(Y2Users::Linux::Writer).to_not receive(:new)

        subject.run
      end

      it "does not update the plain root password for the next run" do
        expect(Yast::InstRootFirstDialog).to receive(:new) do |root|
          root.password = Y2Users::Password.create_plain("root-more-S3cr3T")
        end.and_return(dialog)

        subject.run

        expect(Y2Firstboot::Clients::User.root_password).to eq("root-S3cr3T")
      end
    end
  end
end
