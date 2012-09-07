$(document).ready(
	function()
	{
		// Search all the links in code columns
		$('#results .code a').each(
			function()
			{
				// Activate toggling
				$(this).click(
					function()
					{
						$(this).parent().find('div').toggle();
						return false;
					}
				);
			}
		);
		
		// Activate toggling all
		$('#toggle_all').click(
			function()
			{
				$('#results .code div').each(
					function()
					{
						$(this).toggle();
					}
				);
				return false;
			}
		);
	}
);

