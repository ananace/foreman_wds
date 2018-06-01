function wds_load(element){
  var url = $(element).attr('data-url');
  tfm.tools.showSpinner();
  $.ajax({
    type:'get',
    url: url,
    complete: function(){
      reloadOnAjaxComplete(element);
    },
    success: function(request) {
      element.html(request);
    }
  });
}

$(function() {
  wds_load($('#images'));
  wds_load($('#clients'));
})();
