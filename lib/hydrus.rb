module Hydrus

  def self.ap_dump(message, arg, file_handle = STDOUT)
    divider = '=' * 80
    file_handle.puts divider, message, arg.ai(:plain => true), divider
  end

end
