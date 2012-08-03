class ApplicationController < ActionController::Base
  include SulChrome::Controller
  include Blacklight::Controller  
  include Hydra::Controller::ControllerBehavior
  include Hydrus::ModelHelper
    
  helper_method :to_bool # defined in Hydra::ModelHelper so it can be used in models as well
  helper_method :is_production?, :current_user,:hydrus_is_empty?,:hydrus_is_object_empty?
  
  def layout_name
   'sul_chrome/application'
  end

  # this returns an array of the attributes that have setter methods on any arbitrary object (stripping out attribures you don't want), "=" stripped out as well
  def get_attributes(obj)
    obj.methods.grep(/\w=$/).collect{|method| method.to_s.gsub('=','')}-['validation_context','_validate_callbacks','_validators']
  end
  
  # this checks to see if the object passed in is "empty", which could be nil, a blank string, an array of strings with all elements that are blank, 
  # an arbitrary object whose attributes are all blank, or an array of arbitrary objects whose attributes are all blank
  def hydrus_is_empty?(obj)
    if obj.nil? # nil case
      is_blank=true
    elsif obj.class == Array # arrays      
      is_blank=obj.all? {|element| hydrus_is_empty?(element)}
    elsif obj.class == String # strings
      is_blank=obj.blank?
    else # case of abitrary object
      is_blank=hydrus_is_object_empty?(obj) 
    end
    return is_blank
   end
  
  # this checks to see if the object passed in has attributes that are all blank
  def hydrus_is_object_empty?(obj)
    !get_attributes(obj).collect{|attribute| obj.send(attribute).blank?}.include?(false)
  end
  
  # used to determine if we should show beta message in UI
  def is_production?
    return (Rails.env.production? and (
      !request.env["HTTP_HOST"].nil? and
      !request.env["HTTP_HOST"].include?("-test") and
      !request.env["HTTP_HOST"].include?("-dev") and
      !request.env["HTTP_HOST"].include?("localhost")
    ))
  end

  # when on an item/collection page, check druid against object type and redirect to correct controller if needed
  def redirect_if_not_correct_object_type
    return unless @document_fedora
    if !self.controller_name.include?(@document_fedora.object_type) && @document_fedora.object_type!='adminPolicy'
      redirect_url=Rails.application.routes.url_helpers.send("hydrus_#{@document_fedora.object_type}_path",@document_fedora.pid) 
      redirect_to redirect_url    
    elsif @document_fedora.object_type=='adminPolicy'
      redirect_to root_url
    end
  end
  
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery

  protected
  
  def current_user
    if request.env["WEBAUTH_USER"]
      current_user = WebAuthUser.new(request.env["WEBAUTH_USER"])
    else
      return super
    end
  end
  
end
