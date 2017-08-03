class Hydrus::Event
  attr_reader(:text, :who, :when, :type)

  def initialize(who, whe, text)
    @text = text
    @who  = who
    @when = whe
    @type = 'hydrus'
  end
end
