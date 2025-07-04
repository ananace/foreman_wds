function wds_server_selected(element) {
  const url = $(element).attr('data-url');
  const type = $(element).attr('data-type');
  const attrs = {};

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

function wds_os_selected() {
  if ($('#os_select select').val() === '') {
    $('#wds_server_select select').val('');
    $('#wds_image_select select').val('');
    $('#wds_server_select select').prop('disabled', true);
    $('#wds_image_select select').prop('disabled', true);
  } else {
    if ($('#wds_server_select select').val() !== '') {
        wds_server_selected($('#wds_server_select select'));
    }

    $('#wds_server_select select').prop('disabled', false);
  }
};

function wds_provision_method_selected() {
  $('div[id*=_provisioning]').hide();
  $('#network_provisioning').show();
  $('#wds_provisioning').show();

  if ($('#wds_image_select select').val() === '') {
    $('#wds_image_select select').prop('disabled', true);
  }
}

function wds_enable_provision_methods() {
  $('#provisioning_method').show();
  $('#host_provision_method_build').prop('disabled', false);
  $('#host_provision_method_wds').prop('disabled', false);

  if($('#host_provision_method_wds').is(':checked')) {
    wds_provision_method_selected();
  }
};

$(document)
  .on('change', '#host_provision_method_wds', wds_provision_method_selected)
  .on('change', '.host-architecture-os-select', wds_os_selected)
  .on('ContentLoad', wds_enable_provision_methods);

$(function() {
  $('#wds_provisioning').detach().insertBefore('#media_select');

  wds_enable_provision_methods();
});
