FactoryBot.define do
  factory :archivist1, class: User do
    email 'archivist1@example.com'
  end

  factory :archivist2, class: User do
    email 'archivist2@example.com'
  end

  factory :archivist3, class: User do
    email 'archivist3@example.com'
  end

  factory :archivist4, class: User do
    email 'archivist4@example.com'
  end

  factory :archivist5, class: User do
    email 'archivist5@example.com'
  end

  factory :archivist6, class: User do
    email 'archivist6@example.com'
  end

  factory :archivist7, class: User do
    email 'archivist7@example.com'
  end

  factory :archivist99, class: User do
    email 'archivist99@example.com'
  end

  factory :mock_user, class: User do
    email 'some-user@example.com'
  end
end
