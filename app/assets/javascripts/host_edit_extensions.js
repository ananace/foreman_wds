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

function wds_provision_method_selected() {
  $('div[id*=_provisioning]').hide();
  $('#wds_provisioning').show();
  $('#wds_image_select select').attr('disabled', true);
  if ($('#provider').val() == 'Ovirt')
    $('#host_compute_attributes_template').attr('disabled', false);
}
$(document).on('change', '#host_provision_method_wds', wds_provision_method_selected);

$(function() {
  var caps = $('#capabilities').val() || $('#bare_metal_capabilities').val();
  update_capabilities(caps);
})();
