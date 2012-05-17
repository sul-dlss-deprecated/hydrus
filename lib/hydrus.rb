module Hydrus
  autoload :RoutingHacks, 'hydrus/routing_hacks'

  def self.ap_dump(*args)
    divider = '=' * 80
    args.each do |arg|
      puts divider, arg.ai, divider
    end
  end

end
