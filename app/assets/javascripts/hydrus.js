// this is loaded on each page
var tooltip;

$(document).ready(function(){

	showOnLoad();
	
	$('#show_all_collections').click(function (){
		$('#all_collections').toggleClass('hidden');
		return false;
	});

	$('#show_special_users').click(function (){
		$('#special_users').toggleClass('hidden');
		return false;
	});
		
  if ($('#hydrus_collections-edit').length == 1 || $('#hydrus_collections-update').length == 1) {collection_edit_init();}
  if ($('#hydrus_items-edit').length == 1 || $('#hydrus_items-update').length == 1) {item_edit_init();}
  if ($('#itemsTable').length == 1) {$("#itemsTable").tablesorter();}
  setup_links_that_disable();
  setup_action_links();

  $(".abstract").truncate({max_length: 350});

  $("[rel=tooltip]").tooltip();

  Blacklight.setup_modal('.signin_link', '', true);

  // Open terms of deposit modal window for ajax users
  $(".tod_link").each(function(){
    $(this).click(function(){
      $.ajax($(this).attr("data-url") + "&format=js");
      return false;
    });
  });

  // Show all dropdown menus.  This only happens on HydrusCollections#show and HydrusItems#indexc currently.
  $(".add-content-dropdown").each(function(){
    $(this).toggle();
  });

	$(document).on('confirm:complete', function(e,answer) {
		item=$('#' + e.target.id);
	  if (answer) { 	// user has clicked OK in one of our "confirm" buttons
  		ajax_loading_indicator(item);
			return true;
	  }
	  else // user has clicked on the cancel button in one of our "confirm" buttons
		{
			ajax_loading_done(item);
			return false;
		}
	});


});

// Manage groups of radio buttons that have related fields that need to be disabled.
function manage_radio_groups() {
  $('[data-behavior="radio-disable-group"]').each(function(){
    var group = $(this);
    // disable all non-radio inputs in group
    $('select, input:not([type="radio"])', group).prop("disabled","disabled");
    // enable any elements that correspond to a pre-checked radio that would enable the element on click
    $('[data-control-disable="false"]:checked', group).each(function(){
      $($(this).attr("data-control-element"), group).each(function(){
        $(this).removeAttr("disabled");
      });
    });
    // add click events to radios in disable group to disable or enable the element referred in the data-control-element attribute.
    $('[data-control-element]', group).click(function(){
      if($(this).attr("data-control-disable") == "true") {
        $($(this).attr("data-control-element"), group).prop("disabled", "disabled");
      }else{
        $($(this).attr("data-control-element"), group).each(function(){
          $(this).removeAttr("disabled");
        });
      }
    });
  });
}

function activate_edit_controls() {

  $(document).on('click','.delete-node',function(){
    var button = $(this);
    ajax_loading_indicator(button);
    $.ajax({url: button.attr("href") + "&format=js",
            success: function(data){
              ajax_loading_done(button);
            },
            error: function(data){
              ajax_loading_done(button);
            }
    });
    return false;
  });
  
  // javascript form submission
  $("#item-actions, #collection-actions").toggle();
  $("#item-actions button[type=submit], #collection-actions button[type=submit]").click(function(){
    $("form.step").append("<input type='hidden' value='" + $(this).attr('value') + "' name='" + $(this).attr('name') + "' />");
    $(this).attr("disabled","disabled");
    $(this).text("Please wait...");
    $("form.step").submit();
  });

  $(document).on("click","#add_contributor, #add_link, #add_related_citation",function(){
    var button = $(this);
    var type = $(this).attr("class");
    var form = $(this).closest("form");
    var method = $(this).closest("form").attr("method");
    ajax_loading_indicator(button);
    if($("input[name=_method]",form).length > 0){
      method = $("input[name=_method]").attr("value");
    }
    $.ajax({
      type: method,
      url: form.attr("action") + "?format=js&" + button.attr("data-attribute") + "=" + button.attr("value"),
      success: function(data){
        ajax_loading_done(button);
      },
      error: function(data){
        ajax_loading_done(button);
      }
    });
    return false;
  });
}

function validate_hydrus_item() {
  var all_required_filled = true;
  $("#hydrus_items-edit form input:required, #hydrus_items-edit form textarea:required, #hydrus_items-update form input:required, #hydrus_items-update form textarea:required").each(function(){
    if($(this).attr("value") == "") {
      all_required_filled = false;
    }
  });
  if($("#uploaded-files .object_file_name").length == 0) {
    all_required_filled = false;
  }
  if(all_required_filled) {
    $("#hydrus_item_publish").each(function(){
      $(this).removeAttr("disabled");
    });
  }else{
    $("#hydrus_item_publish").each(function(){
      $(this).attr("disabled", "disabled");
    });
  }
}

function check_for_files_uploading() {
	$("#edit_form").submit(function(e) {
	     var self = this;
	     e.preventDefault();
     	if (filesInProgress != 0) 
			{
			var r=confirm("There are still files uploading.  If you click OK to continue saving the form, you may lose the uploading files.  Click cancel to allow these files to finish uploading.");
			if (r==false)
			  {
				  $('.save-edits').attr('disabled',false);
				  $('.save-edits').text('Save');
				  return false;
			  }
	 		}
	      ajax_loading_indicator($('.save-edits')); // show loading indicator in UI
          self.submit();		
	});
}

function validate_hydrus_collection() {
  var all_required_filled = true;
  $("#hydrus_collections-edit form input:required, #hydrus_collections-edit form textarea:required,#hydrus_collections-update form input:required, #hydrus_collections-update form textarea:required").each(function(){
    if($(this).attr("value") == "") {
      all_required_filled = false;
    }
  });
}

function setup_action_links() {
  $('#discard-item').show();
  $('#share-purl').show();
  $('#copy-purl-link-area').hide();
  $('#share-purl-link').click(function(e) {
    e.preventDefault(); // stop default href behavior
    $('#copy-purl-link-area').toggle();
    $('#copy-purl-link').focus();
    $('#copy-purl-link').select();
  });
  $("#copy-purl-link").click(function() {
    $('#copy-purl-link').select();
  });
}
// href links with the disable_after_click=true attribute will be automatically disabled after clicking to prevent double clicks
function setup_links_that_disable() {
	$("[show_loading_indicator='true']").each(function(){
    $(this).click(function(e){
	    ajax_loading_indicator($(this)); // show loading indicator in UI
	    });
    });
  $("[disable_after_click='true']").each(function(){
    $(this).click(function(e){
      e.preventDefault(); // stop default href behavior
      ajax_loading_indicator($(this)); // show loading indicator in UI
      url=$(this).attr("href"); // grab the URL
      $(this).attr("href","#"); // remove it so even if clicked again, nothing will happen!
      $(this).parent().addClass('disabled'); // disable the parent's element visually
      window.location.href=url; // go to the URL
      });
    });
}

function setup_form_state_change_tracking() {
  $("form[data-track-state-change='true']").each(function(){
    $(this).data("serialized",$(this).serialize());
  });
}

function ajax_loading_indicator(element) {
  $("body").css("cursor", "progress");
	$('#loading-message').removeClass('hidden');
  if (element) {
      element.animate({opacity:0.25});
  		element.addClass("disabled");
  		if (element.attr("disable_with") != '') { 
  			element.attr("enable_with",element.text()); // store the current text
  			element.text(element.attr("disable_with"));  // change the text
  			}		
    }
}

function ajax_loading_done(element) {
  $("body").css("cursor", "auto");
	$('#loading-message').addClass('hidden');
  if (!!element) {
    element.animate({opacity:1.0});
    element.removeAttr("disabled");
    element.removeClass("disabled");
		if (element.attr("enable_with") != '') { element.text(element.attr("enable_with"));} // change the text back		
    }
}

function show_message(text,id) {
	$('#flash-notices').append('<div id="' + id + '" class="span8 offset2"><div class="alert alert-info"><button class="close" data-dismiss="alert">×</button>' + text + '</div></div>');
}

function check_tracked_form_state_change() {
  var state_changed = false;
  $("form[data-track-state-change='true']").each(function(){
    if($("input[type='hidden'][name='save']", $(this)).length < 1){
      if(!state_changed && ($(this).serialize() != $(this).data("serialized")) ){
        state_changed = true;
      }
    }
  });
  return state_changed;
}

function collection_edit_init(){

  // this method is called when the collection edit page is fully loaded
  validate_hydrus_collection();
  activate_edit_controls();
  $(document).on('blur',"form input, form textarea", function(){
      validate_hydrus_collection();
  });

  // show or hide reviewer fields depending on if the user has selected the reviewer workflow
  $("input:radio[name='hydrus_collection[requires_human_approval]']").on('click',function()
  {
  	  if ($(this).attr('value') == 'yes') {
		  $('#reviewer-roles').removeClass('hidden'); 
	  }
	  else
	  {
		  $('#reviewer-roles').addClass('hidden'); 
  	  }
  });
  
  // if the user does not require human approval, hide the reviewer roles section by default
  if ($('#hydrus_collection_requires_human_approval_no').is(':checked')) {$("#reviewer-roles").addClass('hidden')};
  
  // Manage state of select dropdowns when the select should be enabled only when its associated radio button is selected
  $('div.radio-select-group input:radio').click(function() { // when a radio button in the group is clicked
    $('div.radio-select-group select').prop('disabled', true); // disable all the selects
    $('div.radio-select-group input:radio:checked').parentsUntil('.radio-select-option').siblings('div.radio-label').children('select')
      .prop('disabled', false); // re-enable the select that is associated with the selected radio button
  });
  // On page load, execute the code block above to disable appropriate select dropdowns
  $('div.radio-select-group input:radio:checked').trigger('click');
  setup_form_state_change_tracking();
}

function clear_author_tooltip(elem) {
	elem.attr('data-title','');
  elem.tooltip('hide');
}

function item_edit_init(){

  // this method is called when the item edit page is fully loaded
  validate_hydrus_item();
  activate_edit_controls();
  check_for_files_uploading();
  $('input[name="hydrus_item[dates[date_type]]"]:checked').click()
  
  // fill in default citation using authors, year, title format
	$('#use_default_citation').click(function(){
		var authors=''
		var title=$('#hydrus_item_title').val().replace(/\.$/, "");
		
		// build authors list
		$('.authors_textbox').each(function(index) {
			var authorNumber=$(this).attr('data-author-number');
			var authorType=$('.authors_dropdown[data-author-number="' + authorNumber + '"]').val();
			if (authorType.indexOf('personal') == 0 || authorType.indexOf('author') != -1) {
		  	authors += $(this).val() + ' and ';	
			}
		});
			
		var entered_year = $('#hydrus_item_dates_date_created').val().trim().substr(0,4);
		
		// complete citation format		
		var citation=authors.slice(0, -" and ".length) + '. (' + entered_year + '). ' + title + '. Stanford Digital Repository. Available at: http://purl.stanford.edu/' + $('#object_id').attr('value').replace('druid:',''); 
		$('#hydrus_item_preferred_citation').val(citation);
		return false;
	});
	
	// check for user entered authors/contributors -- if they have selected an "author" or "personal" type (e.g. personal name), warn them if we don't see any commas, implying they forgot to do LAST, FIRST
	$(document).on('blur',".authors_textbox",function(){
			var authorNumber=$(this).attr('data-author-number');
			var authorType=$('.authors_dropdown[data-author-number="' + authorNumber + '"]').val();
			if (authorType.indexOf('personal') == 0 || authorType.indexOf('author') != -1) {
			  var authorName=$(this).val();
				if (authorName.indexOf(',') == -1) {
					tooltip=$(this);
					tooltip.attr('data-title','Please be sure the format of personal names is LAST, FIRST.');
					tooltip.tooltip('show');
					window.setTimeout(function() { tooltip.tooltip('hide') }, 4000);
					}
				}
		});
		
  $(document).on('blur',"form input, form textarea",function(){
      validate_hydrus_item();
  });
  $('[data-behavior="datepicker"]').each(function(event){
    $(this).datepicker({
      endDate:   $(this).attr("data-end-date"),
      startDate: $(this).attr("data-start-date")
    });
  });
  manage_radio_groups();
  setup_form_state_change_tracking();
}


function showOnLoad() {
	$('.showOnLoad').removeClass('hidden');	
	$('.showOnLoad').show();
}

$(window).on('beforeunload', function() {
  state_changed = check_tracked_form_state_change();
  if(state_changed){
    return "You have unsaved changes.";
  }
});
