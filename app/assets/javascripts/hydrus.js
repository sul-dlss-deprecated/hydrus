// this is loaded on each page
$(document).ready(function(){
	
	if ($('#hydrus_collections-edit').length == 1 || $('#hydrus_collections-update').length == 1) {collection_edit_init();}
	if ($('#hydrus_items-edit').length == 1 || $('#hydrus_items-update').length == 1) {item_edit_init();}
	if ($('#itemsTable').length == 1) {$("#itemsTable").tablesorter();}
	setup_links_that_disable();
	setup_action_links();
	
	$(".abstract").truncate({max_length: 350});

	$("[rel=tooltip]").tooltip();
		
	// Modal sign in
	$(".signin_link").each(function(){
		$(this).click(function(){
			$.ajax($(this).attr("data-url") + "&format=js");
			return false;
	  });
	});
	
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
		$('[data-control-element]', group).on("click",function(){
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

	$(".delete-node").live("click", function(){
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

	$("#add_person, #add_link, #add_related_citation").live('click',function(){
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
	if($("#uploaded-files .object_file").length == 0) {
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
// href links with the disable-after-click=true attribute will be automatically disabled after clicking to prevent double clicks
function setup_links_that_disable() {
	$("[disable-after-click='true']").each(function(){
		$(this).click(function(e){
			e.preventDefault(); // stop default href behavior
			ajax_loading_indicator(); // show loading indicator in UI
			url=$(this).attr("href"); // grab the URL
			$(this).attr("href","#"); // remove it so even if clicked again, nothing will happen!
			$(this).text('Please wait...'); // change the text
			$(this).parent().addClass('disabled'); // disable the parent's element visually
			$(this).addClass('disabled'); // disable the element visually
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
	if (!!element) {
		element.animate({opacity:0.25});
		element.attr("disabled","disabled");
		}
}

function ajax_loading_done(element) {
	$("body").css("cursor", "auto");	
	if (!!element) {
		element.animate({opacity:1.0});
		element.removeAttr("disabled");
		}
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
	$("form input, form textarea").live("blur", function(){
	    validate_hydrus_collection();
	});	
	
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

function item_edit_init(){
	
	// this method is called when the item edit page is fully loaded
  validate_hydrus_item();
	activate_edit_controls();
	$("form input, form textarea").live("blur", function(){
	    validate_hydrus_item();
	});
	$('[data-behavior="datepicker"]').each(function(){
		$(this).datepicker({
			endDate:   $(this).attr("data-end-date"),
			startDate: $(this).attr("data-start-date")
		});
	});
	manage_radio_groups();
	setup_form_state_change_tracking();
}


$(window).on('beforeunload', function() {
	state_changed = check_tracked_form_state_change();
	if(state_changed){
	  return "You have unsaved changes.";	
	}
});