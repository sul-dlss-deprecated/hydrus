# A script used to print datastreams for an object.

def main(args)
  abort "Usage:\n  #{$PROGRAM_NAME} DATASTREAM DATASTREAM ... PID" unless args.size >= 2
  pid = args.pop.sub /^(druid:)?/, 'druid:'
  obj = ActiveFedora::Base.find(pid)
  args.each { |ds| puts obj.send(ds).content }
end

main(ARGV)
