# Dor-services already has defined the model constants, so we need to
# explicitly require them here
require_dependency Rails.root + 'app/models/hydrus/collection.rb'
require_dependency Rails.root + 'app/models/hydrus/item.rb'
require_dependency Rails.root + 'app/models/hydrus/admin_policy_object.rb'
