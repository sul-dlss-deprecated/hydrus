FactoryBot.define do
  factory :archivist1, class: User do
    email 'archivist1'
    groups ['dlss:hydrus-app-administrators']
  end

  factory :archivist2, class: User do
    email 'archivist2'
  end

  factory :archivist3, class: User do
    email 'archivist3'
    groups ['dlss:hydrus-app-administrators']
  end

  factory :archivist4, class: User do
    email 'archivist4'
  end

  factory :archivist5, class: User do
    email 'archivist5'
    groups ['dlss:hydrus-app-administrators']
  end

  factory :archivist6, class: User do
    email 'archivist6'
  end

  factory :archivist7, class: User do
    email 'archivist7'
  end

  factory :archivist99, class: User do
    email 'archivist99'
  end

  factory :mock_user, class: User do
    email 'some-user@example.com'
  end
end
