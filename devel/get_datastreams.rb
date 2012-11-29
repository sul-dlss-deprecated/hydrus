# A script used to print datastreams for an object.

def main(args)
  abort "Usage:\n  #{$PROGRAM_NAME} DATASTREAM DATASTREAM ... PID" unless args.size >= 2
  pid = args.pop.sub /^(druid:)?/, 'druid:'
  obj = ActiveFedora::Base.find(pid)
  if args == ['LIST']
    obj.datastreams.keys.sort.each { |k| puts k }
    return
  end
  args = obj.datastreams.keys.sort if args == ['ALL']
  args.each { |ds|
    next unless obj.datastreams.include?(ds)
    puts
    puts obj.send(ds).content
  }
end

main(ARGV)
