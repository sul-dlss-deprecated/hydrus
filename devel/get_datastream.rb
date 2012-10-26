# A script used to print a datastream for an object.

def main(args)
  abort "Usage:\n  #{$PROGRAM_NAME} DATASTREAM PID" unless args.size == 2

  ds  = args.shift
  pid = args.shift.sub /^(druid:)?/, 'druid:'
  
  obj = ActiveFedora::Base.find pid
  puts obj.send(ds).content
end

main(ARGV)
