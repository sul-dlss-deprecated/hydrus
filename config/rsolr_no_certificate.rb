# Override make_solr_connection() so that we don't need certs in dev and test.
module Dor
  class Configuration
    def make_solr_connection(add_opts = {})
      opts = Config.solrizer.opts.merge(add_opts).merge(:url => Config.solrizer.url)
      ::RSolr.connect(opts).extend(RSolr::Ext::Client)
    end
  end
end
class RSolr::Connection
  def execute client, request_context
    h = http request_context[:uri], request_context[:proxy], request_context[:read_timeout], request_context[:open_timeout]
    request_context[:method] = :post
    request = setup_raw_request request_context
    request.body = request_context[:data] if request_context[:method] == :post and request_context[:data]
    begin
      response = h.request request
      charset = response.type_params["charset"]
      {:status => response.code.to_i, :headers => response.to_hash, :body => force_charset(response.body, charset)}
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