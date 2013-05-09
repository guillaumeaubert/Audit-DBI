/*!
 * Audit::DBI v1.7.3
 * https://metacpan.org/release/Audit-DBI
 *
 * Copyright 2010-2013 Guillaume Aubert
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3 as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/
 */
$(document).ready(
	function()
	{
		// Search all the links in code columns.
		$('#results .code a').each(
			function()
			{
				// Activate toggling.
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

