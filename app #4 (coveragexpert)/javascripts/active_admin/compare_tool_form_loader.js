$(document).ready(function() {
  if (!$('.show.admin_compare_tools').length) return;
  $('#comparing_documents_button').click(function(){return false;});

  var retryAfterTime = 5000;
  var pathname = window.location.pathname;
  var index = pathname.lastIndexOf('/');
  var comparingStatus = false;

  $("#main_content").append("<div class='loading-container'>" +
    "<div class='loader'></div>" +
    "<div class='load-description'>Please wait a few minutes.</div></div>");

  $( "#comparing_documents_button" ).on( "click", function() {
    if (!!$('.compare_tool_container').length) return;
    showLoader();
    if (comparingStatus) return;
    ajaxTrigger(true);
  });

  $.ajaxSetup({
    retryAfter: retryAfterTime,
  });

  ajaxTrigger = function(continueStatus) {
    comparingStatus = true;
    $.ajax( { type: "POST",
      url: '/compare_tool',
      data: {id: pathname.substring(index + 1, pathname.length)},
      success: function(response) {
        if (response["status"] === 'error') return setTimeout ( function(){ ajaxTrigger() },
          $.ajaxSetup().retryAfter );
        hideLoader();
        comparingStatus = true;
        compareTableHTML(response)
      },
    })
  };

  ajaxTrigger(false);

  function compareTableHTML(response) {
    var data = response['data'];
    var first_file_name = data['first_file_name'];
    var second_file_name = data['second_file_name'];
    var endorsments = data['endorsement_form_numbers'];
    delete data['endorsement_form_numbers'];
    delete data['first_file_name'];
    delete data['second_file_name'];
    var main_form_data = data;

    var compareToolResults = '';
    $.each(main_form_data, function (field_name, data) {
      field_name = field_name.split("_").join(" ")
      format_field_name = field_name.charAt(0).toUpperCase() + field_name.slice(1);
      compareToolResults = compareToolResults +
        "    <tr>\n" +
        `     <td>${format_field_name}</td>\n` +
        `     <th>${data && data[0] || 'N/A' }</th>` +
        `     <th>${data && data[1] || 'N/A' }</th>` +
        `     <th>${data && data[2] || '-' }</th>` +
        "    </tr>\n"
    });
    $.each(endorsments, function( field_name, data ) {
      compareToolResults = compareToolResults +
        "    <tr>\n" +
        "     <td>Endorsement Form #</td>\n" +
        `     <th>${data && data[0] || 'N/A' }</th>` +
        `     <th>${data && data[1] || 'N/A' }</th>` +
        `     <th>${data && data[2] || '-' }</th>` +
        "    </tr>\n"
    });
    appendCompareTable(first_file_name, second_file_name, compareToolResults)
  }

  function appendCompareTable(first_file_name, second_file_name, compareToolResults) {
    $("#main_content").append(''+
      "<div class='compare_tool_container panel'>" +
      "<h3>Compare Tool Results</h3>" +
      "<div class='panel_contents'>" +
      "<div class='attributes_table product_compare_results'>" +
        "<table class='compare_tool_results'>" +
        "    <tr>\n" +
        "      <th>Field</th>" +
        `     <th>${first_file_name}</th>` +
        `     <th>${second_file_name}</th>` +
        "      <th>Analysis</th>\n" +
        "    </tr>\n" +
        ` ${compareToolResults}` +
        "  </div>" +
        " </div>" +
      " </div>" +
      "</div>");

    appendTableStatus = true;
  }

  function hideLoader() {
    $('.loading-container').hide()
  }

  function showLoader() {
    $('.loading-container').show()
  }
});
