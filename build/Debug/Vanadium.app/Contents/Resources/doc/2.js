function randomColor(){
  var letters = '0123456789ABCDEF'.split('');
  var color = '#';
  for (var i = 0; i < 6; i++){
    color += letters[Math.round(Math.random() * 15)];
  }
  return color;
}

function seizure(victim){
  var recolor = function(){
    $(victim).css('color', randomColor());
    $(victim).css('background-color', randomColor());
    setTimeout(recolor, 50);
  }
  recolor();
}