# frozen_string_literal: true

FactoryBot.modify do
  factory :host do
    trait :with_wds_facet do
      association :wds_facet, factory: :wds_facet, strategy: :build
    end
  end
end
