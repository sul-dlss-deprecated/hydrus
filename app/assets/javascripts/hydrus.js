$(document).ready(function(){
	$("#add_person, #add_link").click(function(){
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
	
	// $("#hydrus_items-edit form input, #hydrus_items-edit form textarea").live("blur", function(){
	//     validate_hydrus_item();
	// });
	// $("#terms").click(function(){
	// 	validate_hydrus_item();
	// });
});

function validate_hydrus_item() {
	var all_required_filled = true;
	$("#hydrus_items-edit form input:required, #hydrus_items-edit form textarea:required").each(function(){
		if($(this).attr("value") == "") {
			all_required_filled = false;
		}
	});
	if(all_required_filled && $("input#terms").is(":checked")) {
		$("#publish").removeAttr("disabled");
	}else{
		$("#publish").attr("disabled", "disabled");
	}
}