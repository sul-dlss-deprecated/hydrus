class Hydrus::Collection < Hydrus::GenericItem

  def title
    self.DC.title.first
  end
  
  def abstract
    descMetadata.abstract.first 
  end
  
end
