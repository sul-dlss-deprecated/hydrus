require 'dor-services'

Dor.registered_classes["collection"] = Hydrus::Collection
Dor.registered_classes["item"] = Hydrus::Item
Dor.registered_classes["adminPolicy"] = Hydrus::AdminPolicyObject