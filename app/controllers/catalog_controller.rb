# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController
  skip_authorization_check only: [:home, :index]

  include Blacklight::Catalog
  include Hydrus::AccessControlsEnforcement
  # These before_filters apply the hydra access controls
  before_filter :enforce_index_permissions, only: :index
  before_filter :enforce_viewing_context_for_show_requests, only: :show
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic << :exclude_unwanted_models

  helper_method :has_search_parameters?

  configure_blacklight do |config|
    config.default_solr_params = {
      qt: 'search',
      rows: 10
    }

    # solr field configuration for search results/index views
    config.index.show_link = 'id'
    config.index.record_display_type = 'has_model_ssim'

    # solr field configuration for document/show views
    config.show.html_title = 'id'
    config.show.heading = 'id'
    config.show.display_type = 'has_model_ssim'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    # config.add_facet_field 'object_profile_display', :label => 'Object Profile'
    # config.add_facet_field 'is_governed_by_ssim', :label => 'APOs'
    # config.add_facet_field 'conforms_to_ssim', :label => 'Model Type (?)'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'id', label: 'Identifier:'
    config.add_index_field 'timestamp', label: 'Timestamp:'
    config.add_index_field 'text', label: 'Text:'
    config.add_index_field 'pub_date', label: 'Pub Date:'
    config.add_index_field 'format', label: 'Format:'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'id', label: 'Identifier:'
    config.add_show_field 'timestamp', label: 'Timestamp:'
    config.add_show_field 'text', label: 'Text:'
    config.add_show_field 'pub_date', label: 'Pub Date:'
    config.add_show_field 'format', label: 'Format:'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

#    config.add_search_field 'text', :label => 'Everywhere'

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc', label: 'relevance'
    # config.add_sort_field 'title_sort asc', :label => 'year'
    # config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    # config.add_sort_field 'title_sort asc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def home
    # Issue some SOLR queries to get Collections involving the user,
    # along with counts of Items in those Collections, broken down by
    # their workflow status.

    if current_user
      @collections = Hydrus::Collection.collections_hash(current_user)

      # administrators get a full list of collections, but not as detailed to save on a big SOLR query
      @all_collections = Hydrus::Collection.dashboard_hash if Hydrus::Authorizable.can_act_as_administrator(current_user)
    end

    respond_to do |format|
      format.html
    end
  end

  def index
    # Issue some SOLR queries to get Collections involving the user,
    # along with counts of Items in those Collections, broken down by
    # their workflow status.

    if current_user
      @collections = Hydrus::Collection.collections_hash(current_user)

      # administrators get a full list of collections, but not as detailed to save on a big SOLR query
      @all_collections = Hydrus::Collection.dashboard_hash if Hydrus::Authorizable.can_act_as_administrator(current_user)
    end

    super

  end

  private

  def enforce_index_permissions
    if (current_user.nil? && has_search_parameters?)
      msg = 'You must sign in before searching.'
      flash[:error] = msg
      redirect_to(new_user_session_path)
    end
  end

  def has_search_parameters?
    true
  end
end
