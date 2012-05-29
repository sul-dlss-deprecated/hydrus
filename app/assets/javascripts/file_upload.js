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
	
	$("#file-dnd-text:hidden").toggle();
	var files = evt.dataTransfer.files;
	for(i = 0;  i < files.length; i++) {
		var file = files[i];
    var reader = new FileReader();

    reader.readAsDataURL(file);
		// init the reader event handlers
		//reader.onprogress = function(){ console.log(evt) };
		$("#file-upload").append("<input type='hidden' name='file_names[]' value='" + file.name + "' />");
		var file_name_add = file.name;
		if($("#file-dnd-text #uploaded-file-names").text() != "") {
			file_name_add = ", " + file.name;
		}
		$("#file-dnd-text #uploaded-file-names").text($("#file-dnd-text #uploaded-file-names").text() + file_name_add);
		reader.onloadend = function(evt){
			$("#file-upload").append("<input type='hidden' name='binary_files[]' value='" + evt.target.result + "' />");			
			$("#file-dnd-text #uploaded-files").text(parseInt($("#file-dnd-text #uploaded-files").text()) + 1);
		};
	}
}