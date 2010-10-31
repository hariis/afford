
(function() {
  function toggle(reveal, e) {
    var trigger = e.findElement('li'),
      tooltip = trigger && trigger.down('.tooltip');
    if (!tooltip) return;
    tooltip[reveal ? 'show' : 'hide']();
  }

  document.observe('dom:loaded', function() {
    var isIE6 = Prototype.Browser.IE &&
      undefined === document.body.style.maxHeight;
    if (!isIE6) return;
    var files = $('band-actions'), tooltips = files && files.select('.tooltip');
    if (!files || 0 == tooltips.length) return;
    tooltips.invoke('hide');
    files.observe('mouseover', toggle.curry(true)).
      observe('mouseout', toggle.curry(false));
  });
})();
function setFocus(){
 var flag=false;
 for(z=0;z<document.forms.length;z++){
  var form = document.forms[z];
  var elements = form.elements;
  for (var i=0;i<elements.length;i++){
    var element = elements[i];
    if(element.type == 'text' &&
      !element.readOnly &&
      !element.disabled &&
       element.id != 'subscriber_email'){
      element.focus();
	  flag=true;
     break;
    }
  }
  if(flag)break;
 }
}