#!/usr/bin/env rspec

# Copyright (c) [2020] SUSE LLC
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
require "y2firstboot/clients/firstboot_ssh"

describe Y2Firstboot::Clients::FirstbootSSH do
  describe "#run" do
    context "installation going back" do
      before do
        allow(Yast::GetInstArgs).to receive(:going_back).and_return(true)
      end

      it "returns :auto" do
        expect(subject.run).to eq :auto
      end
    end

    context "sshd is not installed" do
      before do
        allow(Yast2::Systemd::Service).to receive(:find).and_return(nil)
      end

      it "return :next" do
        expect(subject.run).to eq :next
      end
    end

    context "sshd is installed" do
      before do
        allow(Yast2::Systemd::Service).to receive(:find).and_return(sshd_service)
      end

      context "sshd is not running" do
        let(:sshd_service) { double(running?: false) }

        it "removes ssh host keys" do
          expect(Dir).to receive(:glob)

          subject.run
        end
      end

      context "sshd is running" do
        let(:sshd_service) { double(running?: true, stop: true, start: true) }

        it "stops sshd" do
          expect(sshd_service).to receive(:stop)

          subject.run
        end

        it "removes ssh host keys" do
          expect(Dir).to receive(:glob)

          subject.run
        end

        it "starts sshd again" do
          expect(sshd_service).to receive(:start)

          subject.run
        end
      end
    end
  end
end
