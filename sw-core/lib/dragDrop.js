	 IE4 = (document.all) ? 1 : 0;    
    NS4 = (document.layers) ? 1 : 0;
    ver4 = (IE4 || NS4) ? 1 : 0;

    currentX = currentY = 0;
    whichEl = top.desktopFrame.whichEl;
	 activeEl = top.desktopFrame.whichEl;
    
    function grabEl(e) {
        tempwhichEl = event.srcElement;
    
        currentX = event.screenX;
        currentY = event.screenY; 

        if (event.srcElement.id.indexOf("bohide") != -1) {
            elName = event.srcElement.id;
            elName = elName.substring(6,elName.length);
            elName = "top.desktopFrame.document.all."+elName;

            el = eval(elName);
            el.style.pixelLeft = 700;

        } 
        if (event.srcElement.id.indexOf("bclose") != -1) {
            elName = event.srcElement.id;
            elName = elName.substring(6,elName.length);
            elName = "top.desktopFrame.document.all."+elName;

            el = eval(elName);

          //  el.style.pixelLeft = 4000;
          //  el.style.pixelTop = 4000;
					el.outerHTML = "";

        }


//		 top.outputwin.document.write("first - current: "+currentX+" "+currentY+"\n\n");
      if (tempwhichEl.id.indexOf("border") == -1) { return } 
//            while (whichEl.id.indexOf("DRAG") == -1) {
//               	whichEl = whichEl.parentElement;
//               	if (whichEl == null) { return }

		whichEl = tempwhichEl
		elName = whichEl.id
		elName = elName.substring(6,elName.length)
		elName = "top.desktopFrame.document.all."+elName
		
//		alert (elName);
		whichEl = eval(elName);
		top.desktopFrame.whichEl = whichEl;
//		alert (whichEl);
//-				   whichEl = top.document.all.DRAGwin1
//            }
 
		  if (top.desktopFrame.activeEl == null)
	     {
				top.desktopFrame.activeEl = whichEl;
//				alert("activeEl is null");
		  }
   
        if (top.desktopFrame.whichEl != top.desktopFrame.activeEl) {
//					alert("whichEl != activeEl");
            	 top.desktopFrame.whichEl.style.zIndex = top.desktopFrame.activeEl.style.zIndex + 1;
                top.desktopFrame.activeEl = top.desktopFrame.whichEl;
        }
    
      
		  whichEl.style.pixelLeft = whichEl.offsetLeft;
        whichEl.style.pixelTop = whichEl.offsetTop;
    
//-        currentX = (event.clientX + top.desktopFrame.document.body.scrollLeft);
//-        currentY = (event.clientY + top.desktopFrame.document.body.scrollTop);
    
    }
    
    function moveEl(e) {
        if (whichEl == null) { return };

        newX = event.screenX;
        newY = event.screenY;
//-        newX = (event.clientX + top.desktopFrame.document.body.scrollLeft);
//-        newY = (event.clientY + top.desktopFrame.document.body.scrollTop);

        distanceX = (newX - currentX);
        distanceY = (newY - currentY);
//		 top.outputwin.document.write("current: "+currentX+" "+currentY+" new: "+newX+" "+newY+"\n");
        currentX = newX;
        currentY = newY;
    

            whichEl.style.pixelLeft += distanceX;
            whichEl.style.pixelTop += distanceY;
            event.returnValue = false;
    }

    function checkEl() {
        if (whichEl!=null) { return false }
    }
    
    function dropEl() {
        if (NS4) { document.releaseEvents(Event.MOUSEMOVE) }
        top.desktopFrame.whichEl = null;
		  whichEl = null;
    }
    
    function cursEl() {
        if (event.srcElement.id.indexOf("border") != -1) {
            event.srcElement.style.cursor = "move"
        }
        if (event.srcElement.id.indexOf("bclose") != -1) {
            event.srcElement.style.cursor = "hand"
        }
		  if (event.srcElement.id.indexOf("bohide") != -1) {
            event.srcElement.style.cursor = "e-resize"
        }
    }
    
        document.onmousemove = moveEl;
        document.onselectstart = checkEl;
        document.onmouseover = cursEl;
   
        document.onmousedown = grabEl;
        document.onmouseup = dropEl;

    
