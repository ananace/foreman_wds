# frozen_string_literal: true

FactoryBot.define do
  factory :wds_facet, class: 'ForemanWds::WdsFacet' do
    host

    install_image_name { 'install.wim' }
  end
end
