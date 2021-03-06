FactoryGirl.define do

  factory :user do
    sequence(:login) { |n| "138#{n}".ljust(11, '0') }
    password "superPassword"

    after(:create) do |user|
      user.user_info.update(service_rate: 5, platform_service_rate: 25, agent_service_rate: 25)
    end

    trait :agent do
      after(:create) do |user|
        if !user.is_agent?
          create(:agent_role_relation, user: user)
        end
      end
    end

    trait :seller do
      after(:create) do |user|
        create(:seller_role_relation, user: user)
        user.user_info.update(service_rate: 5, platform_service_rate: 25, agent_service_rate: 25)
      end
    end

    trait :admin do
      after(:create) do |user|
        create(:admin_role_relation, user: user)
      end
    end

    factory :user_with_address do
      after(:create) do |user|
        create(:user_address, user: user, default: true)
      end
    end

    factory :user_with_onek_income do
      after(:create) do |user|
        user.user_info.income = 1000
        user.user_info.save
      end
    end

    factory :agent_user, traits: [:agent]
    factory :admin_user, traits: [:admin]
    factory :seller_user, traits: [:seller]

  end

end
