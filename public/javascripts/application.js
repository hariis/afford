jQuery.noConflict();
    var $j = jQuery;
    $j(function(){  // $(document).ready shorthand
       $j('#flash-notice').fadeOut(5000);
       $j('#flash-error').fadeOut(50000);
        // Tabs
       $j('#tabs').tabs();
       $j('input[name=tos_check_box]').attr('checked', false);
       setFocus();
    });
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
       element.id != 'subscriber_email' &&
       element.id != 'feedback_email'){
      element.focus();
	  flag=true;
     break;
    }
  }
  if(flag)break;
 }
}