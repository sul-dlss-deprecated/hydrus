# frozen_string_literal: true
# A script used to print all Hydrus objects, with their PIDs and titles.

def main()
  cpids = Hydrus::Collection.all_hydrus_collections.sort
  abort 'No Hydrus objects found' if cpids.size == 0
  cpids.each do |cpid|
    coll = Hydrus::Collection.find(cpid)
    apo  = coll.apo
    puts
    list(apo, '', 'APO')
    list(coll)
    coll.hydrus_items.sort_by(&:pid).each { |item| list(item, '  ') }
  end
end

def list(obj, prefix = '', title = nil)
  fmt     = "%-6s%-15s%s%s\n"
  title ||= obj.title
  typ     = obj.hydrus_class_to_s.downcase[0..3]
  pid     = obj.pid.split(':').last
  printf(fmt, typ, pid, prefix, title)
end

main()
