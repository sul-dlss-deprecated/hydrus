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
});