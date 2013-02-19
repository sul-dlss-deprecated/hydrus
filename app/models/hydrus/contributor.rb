class Hydrus::Contributor < Hydrus::GenericModel

  # TODO We would like to validate contributors, but we can't if we need to create a
  #      blank one and save the whole item when the user clicks 'add' in the UI.
  # validates :name, :role, :presence=>true

end
