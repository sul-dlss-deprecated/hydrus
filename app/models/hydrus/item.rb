class Hydrus::Item < Hydrus::GenericItem

  def submit_time
    query = '//workflow[@id="sdrDepositWF"]/process[@name="submit"]'
    return workflows.ng_xml.at_xpath(query)['datetime']
  end

end
