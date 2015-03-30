$(document).ready(function()
{
	
	$('.modal-trigger').leanModal();
	$('.button-collapse').sideNav();
	$('.parallax').parallax();
	$('.dropdown-button').dropdown(
	{
	    inDuration: 300,
	    outDuration: 225,
	    constrain_width: false, // Does not change width of dropdown to that of the activator
	    hover: false, // Activate on click
	    alignment: 'left', // Aligns dropdown to left or right edge (works with constrain_width)
	    gutter: 0, // Spacing from edge
	    belowOrigin: true // Displays dropdown below the button
	});
	setActive($('.nav-schedule'));
})

function resizeFrameOnResize()
{
	$('#innerframe').attr('height', ($(window).height() - $('header').height()) - 10)
}

function setActive(object)
{
	clearActive();
	object.addClass('active');
}

function clearActive()
{
	$('.active').removeClass('active');
}