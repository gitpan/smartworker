if(!window.name) window.name='application';

function infoDeskPopup (url) 
{
	var xSize = 700, ySize = 450;

	if (document.all) var xMax = screen.width, yMax = screen.height;
	else if (document.layers) var xMax = window.outerWidth, yMax = window.outerHeight;
	else var xMax = 640, yMax=480;
	var xOffset = (xMax - xSize)/2, yOffset = (yMax - ySize)/2;  

	window.open(url,'InfoDesk','width='+xSize+',height='+ySize+',scrollbars=yes,resizable=no,directories=no,toolbar=no,titlebar=no,location=no,screenX='+xOffset+',screenY='+yOffset+',top='+yOffset+',left='+xOffset+',menubar=yes');
}

function openPopup(url,xSize,ySize,returnValue,newWindow) {
	 
	//centering stuff (resizing breaks something but almost 100% correct)
	if (document.all) var xMax = screen.width, yMax = screen.height;
	else if (document.layers) var xMax = window.outerWidth, yMax = window.outerHeight;
	else var xMax = 640, yMax=480;

	var xOffset = (xMax - xSize)/2, yOffset = (yMax - ySize)/2;  
	  
	var windowName = "popupWindow";
	if (newWindow) windowName = newWindow;

	myPopup = window.open(url,windowName,'width='+xSize+',height='+ySize+',scrollbars=auto,resizable=no,directories=no,toolbar=no,titlebar=no,location=no,screenX='+xOffset+',screenY='+yOffset+',top='+yOffset+',left='+xOffset);
	if (!myPopup.opener) myPopup.opener = self;
	  
	//important to return false to block the real click behaviour
	if (!returnValue) return false;
}

//this function is for pop-up windows.  It takes a ref to the form they
//want to submit, submits that information to the parent window, then closes
//it :-)

function submitPopup(pop,close,target,action) {

	//get info on where we get back to...	  
	if (target == "self") pop.target = self.name;
	else if(target) pop.target = target;
	else pop.target = opener.name;

	//close after we are finished
	if (close) setTimeout('window.close()',200);

	// give the OK to submit
	pop.onsubmit = "function onsubmit(event) { return true; }";

	//important to return false to block the real submit behaviour	
	return false;
}

 function submitPopupLink(location,close,target) {
 	if(target)
		{
		target.location.href=location;
		}
	else
		{
 		self.opener.document.location.href=location;
		}
	if (close) window.close();
	return false;
 	}
