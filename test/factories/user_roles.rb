FactoryGirl.define do
  factory :user_role do
    display_name 'userrole'

    factory :admin_role do
      name 'super_admin'
    end

    factory :seller_role do
      name 'seller'
    end

    factory :agent_role do
      name 'agent'
    end

    factory :city_manager_role do
      name 'city_manager'
    end

  end

end
