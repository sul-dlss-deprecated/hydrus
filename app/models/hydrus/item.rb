class Hydrus::Item < Hydrus::GenericItem

  def files
    Hydrus::ObjectFile.find_all_by_pid(pid,:order=>'weight')  # coming from the database
  end
  
  def submit_time
    query = '//workflow[@id="sdrDepositWF"]/process[@name="submit"]'
    return workflows.ng_xml.at_xpath(query)['datetime']
  end
  
end
