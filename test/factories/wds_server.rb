# frozen_string_literal: true

FactoryBot.define do
  factory :wds_server, class: 'WdsServer' do
    name { 'WDS server' }
    description { 'Example WDS server for testing' }
    url { 'http://example.com:5985/wsman' }
    user { 'username' }
    password { 'password' }
  end
end
