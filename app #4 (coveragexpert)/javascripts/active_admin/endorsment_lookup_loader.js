$(document).ready(function() {
  if (!$('.show.admin_endo_lookups').length) return;
  $('#lookup_document_button').click(function(){return false;});

  var retryAfterTime = 5000;
  var pathname = window.location.pathname;
  var index = pathname.lastIndexOf('/');
  var comparingStatus = false;

  $("#main_content").append("<div class='loading-container'>" +
    "<div class='loader'></div>" +
    "<div class='load-description'>Please wait a few minutes.</div></div>");

  $( "#lookup_document_button" ).on( "click", function() {
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
      url: '/endorsment_lookup',
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
    var status = response['status'];
    var compareToolResults = '';
    if (status === 'data_not_found') {
      appendDataNotFound();
      return
    }

    $.each(data, function( field_name, data ) {
      compareToolResults = compareToolResults +
        "    <tr>\n" +
        `     <th>${data['analysis_status']}</th>` +
        `     <th>${data['company_name']}</th>` +
        `     <th>${data['naic_company_code']}</th>` +
        `     <th>${data['form_type']}</th>` +
        `     <th>${data['form_number']}</th>` +
        `     <th>${data['form_title']}</th>` +
        `     <th><a href='${data['file_url']}'>${data['file_name']}</a></th>` +
        "    </tr>\n"
    });
    appendCompareTable(compareToolResults);
  }

  function appendDataNotFound() {
    $("#main_content").append(''+
      "<h3>Endorsment Lookup data not found.</h3>")
  }

  function appendCompareTable(compareToolResults) {
    $("#main_content").append(''+
      "<div class='compare_tool_container panel'>" +
      "<h3>Endorsment Lookup Results</h3>" +
      "<div class='panel_contents'>" +
      "<div class='attributes_table product_compare_results'>" +
      "<table class='compare_tool_results'>" +
      "    <tr>\n" +
      "     <th>Analysis</th>" +
      "     <th>Company Name</th>" +
      "     <th>Naic Company Code</th>" +
      "     <th>Form Type</th>" +
      "     <th>Form Number</th>" +
      "     <th>Form Title</th>" +
      "     <th>File Name</th>" +
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
