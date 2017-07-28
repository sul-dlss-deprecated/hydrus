class RSolr::Connection
  def execute client, request_context
    if request_context[:method] != :post
      #if this is not a POST, take all of the parameters in the query string and put them into a POST body to avoid queryies with the query string being too long
    uri=URI.parse(request_context[:uri].to_s)
    body=uri.query
    uri.query=nil
    request_context[:uri]=uri
    body=Rack::Utils.parse_query(body)
    #move qt to post body
    
    h = http request_context[:uri], request_context[:proxy], request_context[:read_timeout], request_context[:open_timeout]
    
    request_context[:method] = :post
    request = setup_raw_request request_context
    request.set_form_data(body)
  else
    
    h = http request_context[:uri], request_context[:proxy], request_context[:read_timeout], request_context[:open_timeout]
    
    request = setup_raw_request request_context
    
    
    request.body = request_context[:data] if request_context[:method] == :post and request_context[:data]
  end
    begin
      response = h.request request
      charset = response.type_params["charset"]
      {status: response.code.to_i, headers: response.to_hash, body: force_charset(response.body, charset)}
    rescue Errno::ECONNREFUSED => e
      raise(Errno::ECONNREFUSED.new(request_context.inspect))
    # catch the undefined closed? exception -- this is a confirmed ruby bug
    rescue NoMethodError
      $!.message == "undefined method `closed?' for nil:NilClass" ?
        raise(Errno::ECONNREFUSED.new) :
        raise($!)
    end
end
end
