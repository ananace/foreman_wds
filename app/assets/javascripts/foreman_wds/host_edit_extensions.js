function wds_server_selected(element){
  var url = $(element).attr('data-url');
  var type = $(element).attr('data-type');
  var attrs = {};
  attrs[type] = attribute_hash(['architecture_id', 'operatingsystem_id', 'wds_server_id']);
  tfm.tools.showSpinner();
  $.ajax({
    data: attrs,
    type:'post',
    url: url,
    complete: function(){
      reloadOnAjaxComplete(element);
    },
    success: function(request) {
      $('#wds_image_select').html(request);
    }
  });
}

var old_os_selected = os_selected;
os_selected = function(element){
  old_os_selected(element);

  if ($('#os_select select').val() === '') {
    $('#wds_server_select select').val('');
    $('#wds_image_select select').val('');
    $('#wds_server_select select').prop('disabled', true);
    $('#wds_image_select select').prop('disabled', true);
  } else {
    $('#wds_server_select select').prop('disabled', false);
  }
};

var old_onHostEditLoad = onHostEditLoad;
onHostEditLoad = function() {
  old_onHostEditLoad();

  $('#wds_provisioning').detach().insertBefore('#media_select');
};


function wds_provision_method_selected() {
  $('div[id*=_provisioning]').hide();
  $('#network_provisioning').show();
  $('#wds_provisioning').show();

  if ($('#wds_image_select select').val() === '') {
    $('#wds_image_select select').attr('disabled', true);
  }
}
$(document).on('change', '#host_provision_method_wds', wds_provision_method_selected);

$(function() {
  if($('#host_provision_method_wds').is(':checked')) {
    wds_provision_method_selected();
  }

  var caps = $('#capabilities').val() || $('#bare_metal_capabilities').val();
  update_capabilities(caps);
});
