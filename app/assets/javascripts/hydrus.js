$(document).ready(function(){
	$("#add_person, #add_link, #add_related_citation").click(function(){
		var button = $(this);
		var type = $(this).attr("class");
		var form = $(this).closest("form");
		var method = $(this).closest("form").attr("method");
		if($("input[name=_method]",form).length > 0){
			method = $("input[name=_method]").attr("value");
		}
		$.ajax({
			type: method,
			url: form.attr("action") + "?format=js&" + button.attr("data-attribute") + "=" + button.attr("value")
		});
		return false;
	});
	
	$("[rel=tooltip]").tooltip();
	
	// Modal sign in
	$(".signin_link").each(function(){
		$(this).click(function(){
			$.ajax($(this).attr("data-url"));
			return false;
	  });
	});

	$(".abstract").truncate({max_length: 350});

	// Manage state of select dropdowns when the select should be enabled only when its associated radio button is selected
	$('div.radio-select-group input:radio').click(function() { // when a radio button in the group is clicked
		$('div.radio-select-group select').prop('disabled', true); // disable all the selects
		$('div.radio-select-group input:radio:checked').parentsUntil('.radio-select-option').siblings('div.radio-label').children('select')
			.prop('disabled', false); // re-enable the select that is associated with the selected radio button
	});
	// On page load, execute the code block above to disable appropriate select dropdowns
	$('div.radio-select-group input:radio:checked').trigger('click');

	
	$(".delete-node").live("click", function(){
		var button = $(this);
		$.ajax({url: button.attr("href") + "&format=js",
		        success: function(data){
						  //hydrus_alert("notice", "Field deleted.");
						},
						error: function(data){
							//hydrus_alert("error", "Unable to destroy field.");
						}
		});
		return false;
	});
	
	// javascript form submission
	$("#item-actions, #collection-actions").toggle();
	$("#item-actions button[type=submit], #collection-actions button[type=submit]").click(function(){
		$("form.step").append("<input type='hidden' value='" + $(this).attr('value') + "' name='" + $(this).attr('name') + "' />");	
  	$("form.step").submit();
	});
  
  validate_hydrus_item();
	$("#hydrus_items-edit form input, #hydrus_items-edit form textarea").live("blur", function(){
	    validate_hydrus_item();
	});
	$(".terms_of_deposit").each(function(){
		$(this).click(function(){
			validate_hydrus_item();
		});
	});
	
});
function validate_hydrus_item() {
	var all_required_filled = true;
	$("#hydrus_items-edit form input:required, #hydrus_items-edit form textarea:required").each(function(){
		if($(this).attr("value") == "") {
			all_required_filled = false;
		}
	});
	if($("#uploaded-files .object_file").length == 0) {
		all_required_filled = false;
	}
	if(all_required_filled && $("input#terms_js").is(":checked")) {
		$(".publish").each(function(){
			$(this).removeAttr("disabled");
		});
	}else{
		$(".publish").each(function(){
			$(this).attr("disabled", "disabled");
		});
	}
}