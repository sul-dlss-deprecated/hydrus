####
# Although Hydrus objects will be stored in the main DOR Fedora repository,
# the Hydrus application will have its own SOLR index, independent of
# the SOLR index tied to DOR.
#
# If Hydrus objects are ever created, modified, or deleted outside of
# the Hydrus application, we need a way to refresh the Hydrus SOLR index.
#
# The process works generally like this:
#
#   - Whenever Fedora objects are created, modified, or deleted, Fedora
#     sends a message to ActiveMQ.
#
#   - Apache Camel is the subscriber to that queue.
#
#   - Camel will send a REST call to the Hydrus application -- specifically,
#     to this controller.
#
#   - The methods in this controller then take the appropriate action,
#     either re-solrizing the object or deleting the SOLR document
#     from the index.
####

class HydrusSolrController < ApplicationController
  skip_authorization_check

  # Takes a PID in params.
  # Gets the object from Fedora and re-solrizees it.
  def reindex
    pid = params[:id]
    msg = "reindex(#{pid})"
    # Try to find the object in Fedora, and cast it to the appropriate class.
    begin
      obj = ActiveFedora::Base.find(pid, cast: true)
    rescue ActiveFedora::ObjectNotFoundError
      obj = nil
    end
    # Take action based on the type of object we got.
    if obj.nil?
      # Did not find any object with the given PID.
      msg = "#{msg}: failed to find object"
      index_logger.warn(msg)
      response.status = 404
      render(plain: msg)
    elsif is_hydrus_object(obj)
      # It's a Hydrus object: re-solrize it and render the SOLR document.
      solr_doc = obj.to_solr
      solr.add(solr_doc, add_attributes: { commitWithin: 5000 })
      msg = "#{msg}: updated SOLR index: class=#{obj.class}"
      index_logger.info(msg)
      render(plain: solr_doc)
    else
      # Not a Hydrus object: skip it.
      msg = "#{msg}: skipped non-Hydrus object"
      index_logger.info(msg)
      render(plain: msg)
    end
  end

  # Deletes a document from the SOLR index.
  # Here we don't bother to get the object from Fedora to check its type,
  # because the delete call to SOLR is faster. Note: delete_by_id() and
  # commit() don't appear to return a response that allows one to determine
  # whether the deletion succeeded.
  def delete_from_index
    pid = params[:id]
    msg = "delete_from_index(#{pid})"
    solr.delete_by_id(pid)
    solr.commit
    index_logger.info(msg)
    render(plain: msg)
  end

  private

  # Private method to determine if the given object belongs to
  # one of the Hydrus classes.
  def is_hydrus_object(obj)
    obj.respond_to?(:tags) && obj.tags.any? { |tag| tag.starts_with? Settings.hydrus.project_tag }
  end

  # Private method to return the application's SOLR connection.
  def solr
    Dor::SearchService.solr
  end

  # Private method to return the logger for the SOLR reindexer.
  def index_logger
    @@index_logger ||= Logger.new("#{Rails.root}/log/indexer.log", 10, 10240000)
  end
end
