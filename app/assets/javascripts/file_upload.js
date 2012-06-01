$(document).ready(function() {
	var dropbox = document.getElementById("main");

	// init event handlers
	dropbox.addEventListener("dragenter", dragEnter, false);
	dropbox.addEventListener("dragexit", dragExit, false);
	dropbox.addEventListener("dragover", dragOver, false);
	dropbox.addEventListener("drop", drop, false);
});

function dragEnter(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function dragExit(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function dragOver(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function drop(evt) {
	evt.stopPropagation();
	evt.preventDefault();
	
	var files = evt.dataTransfer.files;
	for(i = 0;  i < files.length; i++) {
		var file = files[i];
    var reader = new FileReader();
    reader.readAsDataURL(file);
    reader.original_filename = file.name;
		
		// We can do something like a progress bar below.
		//reader.onprogress = function(){ console.log(evt) };
		reader.onloadend = function(evt){
			var object_id = $("#object_id").attr("value");
			$.post("/object_files?format=js", {file_name: evt.target.original_filename, binary_data: evt.target.result, id: object_id}, function(data){});
		};
	}
}