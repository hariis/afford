jQuery.noConflict();
    var $j = jQuery;
    $j(function(){  // $(document).ready shorthand
       $j('#flash-notice').fadeOut(5000);
       $j('#flash-error').fadeOut(50000);
        // Tabs
       $j('#tabs').tabs();
       $j('#testimonials').cycle();
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