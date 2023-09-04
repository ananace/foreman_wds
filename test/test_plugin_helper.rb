# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start 'rails' do
    root File.dirname(__dir__)

    add_group 'Interactors', '/app/interactors'
    add_group 'Services', '/app/services'

    formatter SimpleCov::Formatter::SimpleFormatter if ENV['CI']
  end
end

# This calls the main test_helper in Foreman-core
require 'test_helper'

ActiveSupport::TestCase.file_fixture_path = File.join(__dir__, 'fixtures')

# Add plugin to FactoryBot's paths
FactoryBot.definition_file_paths << File.join(__dir__, 'factories')
FactoryBot.reload

class ActiveSupport::TestCase
  setup :setup_winrm_stubs

  def stub_winrm_powershell(command = nil, &block)
    ret = if block_given?
            @winrm_shell_mock[:powershell].stubs(:run).with(&block)
          else
            @winrm_shell_mock[:powershell].stubs(:run).with(command)
          end
    class << ret
      def returns_pwsh(value, **params)
        returns OpenStruct.new(stdout: value, **params)
      end
    end
    ret
  end

  def stub_winrm_wql(query = nil)
    if query
      WinRM::Connection.any_instance.stubs(:run_wql).with(query)
    else
      WinRM::Connection.any_instance.stubs(:run_wql)
    end
  end

  private

  def setup_winrm_stubs
    return if @winrm_mock

    @winrm_mock = true
    require 'winrm'

    transport_mock = mock('winrm::http::transport')
    WinRM::Connection.any_instance.stubs(:transport).returns(transport_mock)

    transport_mock.stubs(:send_request).raises(StandardError, 'Real WinRM connections are not allowed')

    @winrm_shell_mock = {
      powershell: mock('winrm::shell::powershell')
    }
    WinRM::Connection.any_instance.stubs(:shell).with(:powershell).yields @winrm_shell_mock[:powershell]
  end
end
