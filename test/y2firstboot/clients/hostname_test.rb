#!/usr/bin/env rspec
# frozen_string_literal: true

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
require "y2firstboot/clients/hostname"
require "y2network/hostname"

describe Y2Firstboot::Clients::Hostname do
  subject(:client) { described_class.new }

  let(:system_config) do
    Y2Network::Config.new(interfaces: [], hostname: hostname, source: :sysconfig)
  end

  let(:hostname) { Y2Network::Hostname.new(static: "linux") }

  describe "#run" do
    let(:wicked) { false }

    before do
      allow(Yast::Lan).to receive(:Read)
      allow(client).to receive(:propose_hostname?).and_return(false)
      Yast::Lan.add_config(:yast, system_config)
      allow(client).to receive(:hostname_dialog)
      allow(client).to receive(:write_config)
      allow(client).to receive(:wicked?).and_return(wicked)
    end

    context "when run the first time" do
      it "reads the system network configuration" do
        expect(Yast::Lan).to receive(:Read).with(:cache)

        client.run
      end

      context "when the hostname is empty or linux" do
        it "proposes a linux-XXXX hostname where XXXX is a random base-32 number" do
          allow(Yast::String).to receive(:Random).with(4).and_return("u54g")
          allow(client).to receive(:propose_hostname?).and_call_original
          expect { client.run }.to change { Yast::DNS.hostname }.from("linux").to(/linux-u54g/)
        end
      end

      it "runs the dialog to modify the hostname and dhcp_hostname setup" do
        expect(client).to receive(:hostname_dialog)

        client.run
      end

      context "when :next is selected in the hostname dialog" do
        before do
          allow(client).to receive(:hostname_dialog).and_return(:next)
        end

        context "and wicked is in use" do
          let(:wicked) { true }

          it "uses the hostname as an alias to static ips without them" do
            expect(client).to receive(:hostname_to_static_ips)

            client.run
          end
        end

        it "writes the config changes" do
          expect(client).to receive(:write_config)

          client.run
        end
      end

      it "returns the dialog result" do
        expect(client).to receive(:hostname_dialog).and_return(:whatever)

        expect(client.run).to eql(:whatever)
      end
    end
  end
end
