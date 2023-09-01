# frozen_string_literal: true

FactoryBot.define do
  factory :wds_facet, class: 'ForemanWds::WdsFacet' do
    host
    wds_server
  end
end
