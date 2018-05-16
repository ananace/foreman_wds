function wds_images_load(element){
  var url = $(element).attr('data-url');
  tfm.tools.showSpinner();
  $.ajax({
    type:'get',
    url: url,
    complete: function(){
      reloadOnAjaxComplete(element);
    },
    success: function(request) {
      $('#images').html(request);
    }
  });
}

$(function() {
  wds_images_load($('#images'));
})();
