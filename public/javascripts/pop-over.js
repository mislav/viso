$(function() {

  $('.trigger').click(function(e) {
    e.preventDefault();
    e.stopPropagation();
  });
  
  $('.trigger').on('touchstart', function() {
    if ($(this).hasClass('triggered')) {
      $(this).removeClass('triggered');
      $('.drop-down').removeClass('show');
    } else {
      $('.drop-down').addClass('show');
      $(this).addClass('triggered');
    }
  });
    
  $('.trigger').on('hover', function(){
    $('.drop-down').addClass('show');
  });
  
  $('.menu').on('mouseleave', function(e){
    $('.drop-down').removeClass('show');
  });
  
});
