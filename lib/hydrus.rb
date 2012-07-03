module Hydrus

  def self.ap_dump(arg, file_handle = STDOUT)
    divider = '=' * 80
    file_handle.puts divider, arg.ai(:plain => true), divider
  end

end
