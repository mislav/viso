$(function() {

  $('.trigger').click(function(e) {
    e.preventDefault();
    e.stopPropagation();
  });
  
  $('.trigger').on('hover', function(){
    $('.drop-down').addClass('show');
  });
  
  $('.menu').on('mouseleave', function(e){
    $('.drop-down').removeClass('show');
  });
  
  $(document).click(function(e) {
    if ($('.menu .drop-down').is(':visible')) {
      $('.drop-down').removeClass('show');
    }
  });
  
});
