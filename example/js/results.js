window.onload = function() {
	// Search all the links in code columns
	jQuery.each(
		$('#results .code a'),
		function() {
			// Activate toggling
			$(this).click(
				function() {
					$(this).parent().find('div').toggle();
					return false;
				}
			);
		}
	);
	
	// Activate toggling all
	$('#toggle_all').click(
		function() {
			jQuery.each(
				$('#results .code div'),
				function() {
					$(this).toggle();
				}
			);
			return false;
		}
	);
}

