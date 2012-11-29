module Hydrus

  def self.ap_dump(arg, file_handle = STDOUT)
    d = '=' * 80
    file_handle.puts(d, caller[0], arg.ai(:plain => true), d)
  end

end
