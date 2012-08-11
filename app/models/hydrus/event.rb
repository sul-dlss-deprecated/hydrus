class Hydrus::Event

  attr_reader(:text, :who, :when, :type)

  def initialize(node)
    @text = node.text
    @who  = node['who']
    @when = node['when']
    @type = node['type']
  end

end
