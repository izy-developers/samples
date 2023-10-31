function onUploadButtonChange() {
  $("[disabled]").attr("disabled", false);

  var files = this.files;

  for (var i = 0; i < files.length; i++) {
    var file = files[i];
    var reader = new FileReader();

    reader.onload = function () {
      var imgElement = $("<img class='img-fluid preview-image'>");
      imgElement.attr({
        src: reader.result,
      });

      imgElement.css({
        objectFit: "cover",
      });

      var newID = "#upload_file_btn_" + generateRandomIntegerInRange(1, 100000);
      var btnClone = $("#upload_file_btn").clone().attr("id", newID);
      btnClone.on("change", onUploadButtonChange);
      $(".attachments-container").append(btnClone);
      $(".choose-file-label").attr({ for: newID });

      var removeButton = $(
        "<button class='btn remove-button'>&times;</button>"
      );
      removeButton.click(function () {
        $(this).parent().remove();
        btnClone.remove();
      });

      var col = $("<div class='col-md-4 mb-3'>");
      col.append(removeButton);
      col.append(imgElement);
      $("#preview").append(col);
    };

    reader.readAsDataURL(file);
  }
}
