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
require "y2firstboot/clients/wsl_product_selection"
require "y2firstboot/dialogs/wsl_product_selection"
require "y2firstboot/wsl_config"
require "singleton"

describe Y2Firstboot::Clients::WSLProductSelection do
  subject { described_class.new }

  describe "#run" do
    context "when yast2-registration is not available" do
      before do
        allow(subject).to receive(:require).with(/registration\/*/).and_raise(LoadError)
      end

      it "raises an exception" do
        expect { subject.run }.to raise_error(RuntimeError, /yast2-registration/)
      end
    end

    context "when yast2-registration is available" do
      before do
        allow(subject).to receive(:require_registration)
      end

      # Mimic yast-registration classes
      module Registration
        class YamlProductsReader
          attr_reader :read
        end

        module Storage
          class InstallationOptions
            include Singleton

            attr_accessor :yaml_product, :force_registration
          end
        end
      end

      context "and there are no products from YAML file" do
        before do
          allow_any_instance_of(Registration::YamlProductsReader).to receive(:read).and_return([])
          allow(Y2Firstboot::Dialogs::WSLProductSelection).to receive(:new).and_return(dialog)
        end

        let(:dialog) { instance_double(Y2Firstboot::Dialogs::WSLProductSelection) }

        it "does not run the dialog for selecting product" do
          expect(dialog).to_not receive(:run)

          subject.run
        end

        it "does not change the current WSL config" do
          Y2Firstboot::WSLConfig.instance.product = { "name" => "test" }
          Y2Firstboot::WSLConfig.instance.patterns = ["test"]

          subject.run

          expect(Y2Firstboot::WSLConfig.instance.product).to eq("name" => "test")
          expect(Y2Firstboot::WSLConfig.instance.patterns).to contain_exactly("test")
        end

        it "returns :auto" do
          expect(subject.run).to eq(:auto)
        end
      end

      context "and there are products from YAML file" do
        before do
          allow_any_instance_of(Registration::YamlProductsReader)
            .to receive(:read).and_return([sles, sled])

          allow(Y2Firstboot::Dialogs::WSLProductSelection).to receive(:new).and_return(dialog)

          allow(Y2Firstboot::WSLConfig.instance)
            .to receive(:product_switched?).and_return(product_switched)
        end

        let(:sles) { { "name" => "SLES", "version" => "15.4" } }
        let(:sled) { { "name" => "SLED", "version" => "15.4" } }

        let(:dialog) do
          instance_double(Y2Firstboot::Dialogs::WSLProductSelection,
            run:             dialog_result,
            product:         selected_product,
            wsl_gui_pattern: wsl_gui_pattern)
        end

        let(:dialog_result) { :abort }
        let(:selected_product) { nil }
        let(:wsl_gui_pattern) { nil }

        let(:product_switched) { false }

        it "runs the dialog for selecting product" do
          expect(dialog).to receive(:run)

          subject.run
        end

        context "if the dialog is accepted" do
          let(:dialog_result) { :next }
          let(:selected_product) { sled }

          it "stores the selected product in the WSL config" do
            subject.run

            expect(Y2Firstboot::WSLConfig.instance.product).to eq(sled)
          end

          context "if the WSL GUI pattern was selected" do
            let(:wsl_gui_pattern) { true }

            before do
              Y2Firstboot::WSLConfig.instance.patterns = []
            end

            it "stores the WSL GUI pattern in the WSL config" do
              subject.run

              expect(Y2Firstboot::WSLConfig.instance.patterns).to include("wsl_gui")
            end
          end

          context "if the WSL GUI pattern was not selected" do
            let(:wsl_gui_pattern) { false }

            before do
              Y2Firstboot::WSLConfig.instance.patterns = ["wsl_gui"]
            end

            it "does not store the WSL GUI pattern in the WSL config" do
              subject.run

              expect(Y2Firstboot::WSLConfig.instance.patterns).to_not include("wsl_gui")
            end
          end

          it "updates the product in registration storage" do
            Registration::Storage::InstallationOptions.instance.yaml_product = nil

            subject.run

            expect(Registration::Storage::InstallationOptions.instance.yaml_product).to eq(sled)
          end

          context "if the product was switched" do
            let(:product_switched) { true }
            let(:wsl_gui_pattern) { false }

            it "updates registration storage to force registration" do
              Registration::Storage::InstallationOptions.instance.force_registration = false

              subject.run

              expect(Registration::Storage::InstallationOptions.instance.force_registration)
                .to eq(true)
            end
          end

          context "if the product was not switched" do
            let(:product_switched) { false }

            context "and the WSL GUI pattern was selected" do
              let(:wsl_gui_pattern) { true }

              it "updates registration storage to force registration" do
                Registration::Storage::InstallationOptions.instance.force_registration = false

                subject.run

                expect(Registration::Storage::InstallationOptions.instance.force_registration)
                  .to eq(true)
              end
            end

            context "and the WSL GUI pattern was not selected" do
              let(:wsl_gui_pattern) { false }

              it "updates registration storage to not force registration" do
                Registration::Storage::InstallationOptions.instance.force_registration = true

                subject.run

                expect(Registration::Storage::InstallationOptions.instance.force_registration)
                  .to eq(false)
              end
            end
          end

          it "returns :next" do
            expect(subject.run).to eq(:next)
          end
        end

        context "if the dialog is not accepted" do
          let(:dialog_result) { :cancel }
          let(:selected_product) { sled }
          let(:wsl_gui_pattern) { true }

          it "does not change the WSL config" do
            Y2Firstboot::WSLConfig.instance.product = sles
            Y2Firstboot::WSLConfig.instance.patterns = []

            subject.run

            expect(Y2Firstboot::WSLConfig.instance.product).to eq(sles)
            expect(Y2Firstboot::WSLConfig.instance.patterns).to eq([])
          end

          it "does not change the registration storage" do
            Registration::Storage::InstallationOptions.instance.yaml_product = sles
            Registration::Storage::InstallationOptions.instance.force_registration = false

            subject.run

            expect(Registration::Storage::InstallationOptions.instance.yaml_product).to eq(sles)
            expect(Registration::Storage::InstallationOptions.instance.force_registration)
              .to eq(false)
          end

          it "returns the dialog result" do
            expect(subject.run).to eq(:cancel)
          end
        end
      end
    end
  end
end
