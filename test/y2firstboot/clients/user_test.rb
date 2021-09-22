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
require "y2firstboot/clients/user"

describe Y2Firstboot::Clients::User do
  subject(:client) { described_class.new }

  describe "#run" do
    before do
      allow(Yast::InstUserFirstDialog).to receive(:new).and_return(dialog)

      allow_any_instance_of(Y2Users::Linux::Writer).to receive(:write)

      allow(Y2Users::ConfigManager.instance).to receive(:system).and_return(system_config)

      allow(system_config).to receive(:copy).and_return(config)
    end

    let(:system_config) { Y2Users::Config.new.attach(root) }

    let(:config) { system_config.copy.attach(user) }

    let(:root) do
      Y2Users::User.create_root.tap do |root|
        root.password = Y2Users::Password.create_encrypted("$xaadfd545dft")
      end
    end

    let(:user) do
      Y2Users::User.new("test").tap do |user|
        user.home = Y2Users::Home.new("/home/test")
        user.password = Y2Users::Password.create_encrypted("$xa9545dft")
      end
    end

    let(:dialog) { instance_double(Yast::InstUserFirstDialog, run: dialog_result) }

    let(:dialog_result) { :back }

    context "if the client is executed for first time" do
      before do
        described_class.username = nil
      end

      it "opens the dialog with a new user" do
        expect(Yast::InstUserFirstDialog).to receive(:new) do |_config, params|
          expect(params[:user].attached?).to eq(false)
        end.and_return(dialog)

        subject.run
      end

      it "returns the dialog result" do
        expect(subject.run).to eq(dialog_result)
      end
    end

    context "if the client was already executed" do
      before do
        described_class.username = "test"
        described_class.user_password = "S3cr3T"
        described_class.root_password = "root-S3cr3T"
      end

      it "opens the dialog with the previously created user" do
        expect(Yast::InstUserFirstDialog).to receive(:new) do |_config, params|
          expect(params[:user].attached?).to eq(true)
          expect(params[:user].name).to eq("test")
        end.and_return(dialog)

        subject.run
      end

      it "sets the saved plain password to the user" do
        expect(Yast::InstUserFirstDialog).to receive(:new) do |_config, params|
          expect(params[:user].password_content).to eq("S3cr3T")
        end.and_return(dialog)

        subject.run
      end

      it "sets the plain password to the root user" do
        expect(Yast::InstUserFirstDialog).to receive(:new) do |config, _params|
          expect(config.users.root.password_content).to eq("root-S3cr3T")
        end.and_return(dialog)

        subject.run
      end

      it "returns the dialog result" do
        expect(subject.run).to eq(dialog_result)
      end
    end

    context "when the dialog result is :next" do
      let(:dialog_result) { :next }

      before do
        described_class.username = "test"
      end

      context "if the user name does not match with the basename of the home directory" do
        before do
          user.home.path = "/home/test"
        end

        it "updates the home directory" do
          expect(Yast::InstUserFirstDialog).to receive(:new) do |_, params|
            user = params[:user]
            user.name = "test2"
          end.and_return(dialog)

          subject.run

          expect(user.home.path).to eq("/home/test2")
        end
      end

      it "writes the config to the system" do
        expect(Y2Users::Linux::Writer).to receive(:new)
          .with(config, system_config).and_call_original

        subject.run
      end

      it "updates the saved user values for the next run" do
        expect(Yast::InstUserFirstDialog).to receive(:new) do |config, params|
          user = params[:user]
          user.name = "test2"
          user.password = Y2Users::Password.create_plain("more-S3cr3T")
          config.users.root.password = Y2Users::Password.create_plain("root-more-S3cr3T")
        end.and_return(dialog)

        subject.run

        expect(described_class.username).to eq("test2")
        expect(described_class.user_password).to eq("more-S3cr3T")
        expect(described_class.root_password).to eq("root-more-S3cr3T")
      end
    end

    context "when dialog result is not :next" do
      let(:dialog_result) { :back }

      before do
        described_class.username = "test"
        described_class.user_password = "S3cr3T"
        described_class.root_password = "root-S3cr3T"
      end

      it "does not write the users configuration" do
        expect(Y2Users::Linux::Writer).to_not receive(:new)

        subject.run
      end

      it "does not update the saved user values for the next run" do
        expect(Yast::InstUserFirstDialog).to receive(:new) do |config, params|
          user = params[:user]
          user.name = "test2"
          user.password = Y2Users::Password.create_plain("more-S3cr3T")
          config.users.root.password = Y2Users::Password.create_plain("more-root-S3cr3T")
        end.and_return(dialog)

        subject.run

        expect(described_class.username).to eq("test")
        expect(described_class.user_password).to eq("S3cr3T")
        expect(described_class.root_password).to eq("root-S3cr3T")
      end
    end
  end
end
