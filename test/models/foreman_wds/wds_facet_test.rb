# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWds
  class WDSFacetTest < ActiveSupport::TestCase
    let(:wds_server) do
      FactoryBot.build(:wds_server)
    end
    let(:host) do
      FactoryBot.build(:host, :managed, :with_wds_facet) do |host|
        host.wds_facet.wds_server = wds_server
      end
    end

    context 'without WDS server' do
      let(:wds_server) { nil }

      it 'does not error' do
        assert_nil host.wds_facet.boot_image
        assert_nil host.wds_facet.install_image
      end
    end

    context 'with WDS server' do
      setup do
        wds_server.stubs(:run_wql).returns({})
        wds_server.stubs(:run_pwsh).with('Get-WDSBootImage').returns(OpenStruct.new stdout: '[]')
        wds_server.stubs(:run_pwsh).with("Get-WDSInstallImage -ImageName 'install.wim'").returns(OpenStruct.new stdout: '[]')
      end

      it 'does not error' do
        assert_nil host.wds_facet.boot_image
        assert_nil host.wds_facet.install_image
      end
    end
  end
end
