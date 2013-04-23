$(document).ready(function() {
  
  var dropbox = document.getElementById("file-dropzone");
  filesInProgress = 0;
  
  if (dropbox != null) {
	  // init event handlers
	  dropbox.addEventListener("dragenter", dragEvent, false);
	  dropbox.addEventListener("dragexit", dragEvent, false);
	  dropbox.addEventListener("dragover", dragEvent, false);
	  dropbox.addEventListener("drop", drop, false);
  }
});

function dragEvent(evt) {
	evt.stopPropagation();
	evt.preventDefault();
	evt.target.className = (evt.type == "dragover" ? "hover" : "");
}

function drop(evt) {
  dragEvent(evt);
  var files = evt.target.files || evt.dataTransfer.files;
 
  // process all File objects
 for (var i = 0, f; f = files[i]; i++) {
		uploadFile(f);
  }
}

function updateFilesUploading(num) {
	if (num == 0) {
		$('#files-uploading').text("");		
	}
	else
	{
		$('#files-uploading').text(num + " files uploading");
	}
}

function uploadFile(file) {

	var xhr = new XMLHttpRequest();
	filesInProgress += 1;
	updateFilesUploading(filesInProgress);
	
	var filename=file.name;
	
	// create progress bar
	var o = $("#file-progress");
	var progress = $("<p />");
	progress.attr("data-progress-bar",filename);
	progress.text(filename);
	o.append(progress);

	// progress bar
	xhr.upload.addEventListener("progress", function(e) {
		var pc = parseInt(100 - (e.loaded / e.total * 100));
		progress.css("backgroundPosition", pc + "% 0");
	}, false);

	// file received/failed
	xhr.onreadystatechange = function(e) {
		if (xhr.readyState == 4) {
			filesInProgress -= 1;
			updateFilesUploading(filesInProgress);
			if (xhr.status == 200) 
			{
				// remove progress bar
				progress.remove();
				eval(xhr.responseText);
			}
			else
			{
				progress.text(filename + " failed");
				progress.addClass('failed');
			}
		}
	};

	// create the post URL
    var object_id = $("#object_id").attr("value");
    var post_url = "/items/" + object_id + "/create_file?format=js";

	// setup the form data
	var data = new FormData();
    data.append('file', file);
	data.append('id',object_id);

	// post to the server
	xhr.open("POST", post_url, true);
	xhr.setRequestHeader("X-CSRF-Token", $('meta[name="csrf-token"]').attr('content'));
	xhr.send(data);
			  
}