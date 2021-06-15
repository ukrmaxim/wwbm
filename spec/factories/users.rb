FactoryBot.define do
  factory :user do
    name { "Гриша_#{rand(666)}" }

    sequence(:email) { |n| "dude_#{n}@example.com" }

    is_admin { false }

    balance { 0 }

    after(:build) { |u| u.password_confirmation = u.password = '123456' }
  end
end
