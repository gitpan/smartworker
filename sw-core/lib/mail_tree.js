function Folder(folderDescription, hreference) //constructor 
{
    //constant data;
    this.desc = folderDescription;
    this.hreference = hreference;
    this.id = -1;
    this.navObj = 0;
    this.iconImg = 0;
    this.nodeImg = 0;
    this.isLastNode = 0;
                                                             
    // dynamic data                                           
    this.isOpen = true;
    this.iconSrc = imagebase+"1.gif";
    this.children = new Array;
    this.nChildren = 0;
                                                              
    // methods
    this.initialize = initializeFolder;
    this.setState = setStateFolder;
    this.addChild = addChild;
    this.createIndex = createEntryIndex;
    this.hide = hideFolder;
    this.display = display;
    this.renderOb = drawFolder;
    this.totalHeight = totalHeight;
    this.subEntries = folderSubEntries;
    this.outputLink = outputFolderLink;
}



function setStateFolder(isOpen)
{ 
  var subEntries; 
  var totalHeight; 
  var fIt = 0; 
  var i = 0; 
 
  if(isOpen == this.isOpen) 
      return 
 
  if(browserVersion == 2) {
      totalHeight = 0 
      for(i = 0; i < this.nChildren; i++) 
          totalHeight = totalHeight + this.children[i].navObj.clip.height; 
      subEntries = this.subEntries(); 

      if(this.isOpen) 
          totalHeight = 0 - totalHeight; 

      for(fIt = this.id + subEntries + 1; fIt < nEntries; fIt++) 
          indexOfEntries[fIt].navObj.moveBy(0, totalHeight); 
  }

  this.isOpen = isOpen; 
  propagateChangesInState(this); 
} 


 
function propagateChangesInState(folder) 
{   
  var i=0 
 
  if (folder.isOpen) 
  { 
    if (folder.nodeImg) 
      if (folder.isLastNode) 
        folder.nodeImg.src = imagebase+"ftv2mlastnode.gif" 
      else 
	  folder.nodeImg.src = imagebase+"ftv2mnode.gif" 
    folder.iconImg.src = imagebase+"icons/1.gif" 
    for (i=0; i<folder.nChildren; i++) 
      folder.children[i].display() 
  } 
  else 
  { 
    if (folder.nodeImg) 
      if (folder.isLastNode) 
        folder.nodeImg.src = imagebase+"ftv2plastnode.gif" 
      else 
	  folder.nodeImg.src = imagebase+"ftv2pnode.gif" 
    folder.iconImg.src = imagebase+"icons/1.gif" 
    for (i=0; i<folder.nChildren; i++) 
      folder.children[i].hide() 
  }  
} 
 

function hideFolder() 
{ 
    if(browserVersion == 1) { 
        if(this.navObj.style.display == "none")
            return 
        this.navObj.style.display = "none"
    }
    else { 
        if(this.navObj.visibility == "hidden")
            return 
        this.navObj.visibility = "hidden" 
    } 
   
    this.setState(0) 
} 


function initializeFolder(level, lastNode, leftSide) 
{ 
    var i = 0;
    var j = 0;

    var numberOfFolders;
    var numberOfDocs;
    var nc;
      
    nc = this.nChildren;
    this.createIndex();
 
    var auxEv = "";
 
    if(browserVersion > 0)
        auxEv = "<a href='javascript:clickOnNode("+this.id+")'>" 
    else 
        auxEv = "<a>" 
 

    if(level > 0) {
        if(lastNode) { //the last 'brother' in the children array 
           this.renderOb(leftSide + auxEv + "<img name='nodeIcon" + this.id + "' src='/sw_lib/images/ftv2mlastnode.gif' width=16 height=22 border=0></a>");
           leftSide = leftSide + "<img src='/sw_lib/images/ftv2blank.gif' width=16 height=22>";
           this.isLastNode = 1;
        } 
        else { 
            this.renderOb(leftSide + auxEv + "<img name='nodeIcon" + this.id + "' src='/sw_lib/images/ftv2mnode.gif' width=16 height=22 border=0></a>");
            leftSide = leftSide + "<img src='/sw_lib/images/ftv2vertline.gif' width=16 height=22>";
            this.isLastNode = 0;
        } 
    }
    else 
        this.renderOb("");
   

    if(nc > 0) {
        level = level + 1;
        for(i = 0; i < this.nChildren; i++) { 
            if(i == this.nChildren-1)
                this.children[i].initialize(level, 1, leftSide);
            else 
                this.children[i].initialize(level, 0, leftSide);
        } 
    } 
} 
 


function drawFolder(leftSide) 
{ 
  if (browserVersion == 2) { 
    if (!doc.yPos) 
      doc.yPos=8 
    doc.write("<layer id='folder" + this.id + "' top=" + doc.yPos + " visibility=hidden>") 
  } 
   
  doc.write("<table ") 
  if (browserVersion == 1) 
    doc.write(" id='folder" + this.id + "' style='position:block;' ") 
  doc.write(" border=0 cellspacing=0 cellpadding=0>") 
  doc.write("<tr><td>") 
  doc.write(leftSide) 
  this.outputLink() 
  doc.write("<img name='folderIcon" + this.id + "' ") 
  doc.write("src='/sw_lib/images/" + this.iconSrc+"' border=0></a>") 
  doc.write("</td><td nowrap>") 

  doc.write("<DIV CLASS=\"fldrroot\">");
  if (USETEXTLINKS) 
  { 
    this.outputLink() 
    doc.write(this.desc + "</a>") 
  } 
  else 
    doc.write(this.desc) 

  doc.write("</DIV>");
  
  
  
  doc.write("</td>")  
  doc.write("</table>") 
   
  if (browserVersion == 2) { 
    doc.write("</layer>") 
  } 

 
  if (browserVersion == 1) { 
    this.navObj = doc.all["folder"+this.id] 
    this.iconImg = doc.all["folderIcon"+this.id] 
    this.nodeImg = doc.all["nodeIcon"+this.id] 
  } else if (browserVersion == 2) { 
    this.navObj = doc.layers["folder"+this.id] 
    this.iconImg = this.navObj.document.images["folderIcon"+this.id] 
    this.nodeImg = this.navObj.document.images["nodeIcon"+this.id] 
    doc.yPos=doc.yPos+this.navObj.clip.height 
  } 
} 
 
function outputFolderLink() 
{
  if (this.hreference) 
  { 
    doc.write("<a href='" + this.hreference + "' TARGET=\"basefrm\" ") 
    if (browserVersion > 0) 
      doc.write("onClick='javascript:clickOnFolder("+this.id+")'") 
    doc.write(">") 
  } 
  else 
    doc.write("<a>")
//  doc.write("<a href='javascript:clickOnFolder("+this.id+")'>")   
} 
 
function addChild(childNode) 
{ 
  this.children[this.nChildren] = childNode 
  this.nChildren++ 
  return childNode 
} 
 
function folderSubEntries() 
{ 
  var i = 0 
  var se = this.nChildren 
 
  for (i=0; i < this.nChildren; i++){ 
    if (this.children[i].children) //is a folder 
      se = se + this.children[i].subEntries() 
  } 
 
  return se 
} 
 
 
// Definition of class Item (a document or link inside a Folder) 
// ************************************************************* 
 
function Item(itemDescription, itemLink, itemImg) // Constructor 
{ 
  // constant data 
  this.desc = itemDescription 

  this.link = itemLink 
 
  this.id = -1 //initialized in initalize() 
  this.navObj = 0 //initialized in render() 
  this.iconImg = 0 //initialized in render() 

// iconSrc
  this.iconSrc = itemImg;
 
  // methods 
  this.initialize = initializeItem 
  this.createIndex = createEntryIndex 
  this.hide = hideItem 
  this.display = display 
  this.renderOb = drawItem 
  this.totalHeight = totalHeight 
} 


function hideItem() 
{ 
  if (browserVersion == 1) { 
    if (this.navObj.style.display == "none") 
      return 
    this.navObj.style.display = "none" 
  } else { 
    if (this.navObj.visibility == "hidden") 
      return 
    this.navObj.visibility = "hidden" 
  }     
} 
 
function initializeItem(level, lastNode, leftSide) 
{  
  this.createIndex() 
 
  if (level>0) 
    if (lastNode) //the last 'brother' in the children array 
    { 
      this.renderOb(leftSide + "<img src='/sw_lib/images/ftv2lastnode.gif' width=16 height=22>") 
      leftSide = leftSide + "<img src='/sw_lib/images/ftv2blank.gif' width=16 height=22>"  
    } 
    else 
    { 
      this.renderOb(leftSide + "<img src='/sw_lib/images/ftv2node.gif' width=16 height=22>") 
      leftSide = leftSide + "<img src='/sw_lib/images/ftv2vertline.gif' width=16 height=22>" 
    } 
  else 
    this.renderOb("")   
} 

 
function drawItem(leftSide) 
{ 
  if (browserVersion == 2) 
    doc.write("<layer id='item" + this.id + "' top=" + doc.yPos + " visibility=hidden>") 
     
  doc.write("<table ") 
  if (browserVersion == 1) 
    doc.write(" id='item" + this.id + "' style='position:block;' ") 
  doc.write(" border=0 cellspacing=0 cellpadding=0>") 
  doc.write("<tr><td>") 
  doc.write(leftSide) 


  if(this.link != "")
      doc.write("<a " + this.link + ">") 
     // doc.write("<a href=" + this.link + ">") 


  doc.write("<img id='itemIcon"+this.id+"' ") 
  doc.write("src='/sw_lib/images/"+this.iconSrc+"' border=0 onClick='clickOnItem()'>") 

  if(this.link != "")
      doc.write("</a>") 

  doc.write("</td><td nowrap>") 
  
  doc.write("<DIV CLASS=\"fldritem\">");
  if (USETEXTLINKS) {
  if(this.link != "")
        doc.write("<a " + this.link + ">" + this.desc + "</a>") 
   //     doc.write("<a href=" + this.link + ">" + this.desc + "</a>") 
  else
    doc.write(this.desc)       
    
  }
  else {
    doc.write(this.desc) 
  }
  doc.write("</DIV>");

  doc.write("</table>") 
   
  if (browserVersion == 2) 
    doc.write("</layer>") 
 
  if (browserVersion == 1) { 
    this.navObj = doc.all["item"+this.id] 
    this.iconImg = doc.all["itemIcon"+this.id] 
  } else if (browserVersion == 2) { 
    this.navObj = doc.layers["item"+this.id] 
    this.iconImg = this.navObj.document.images["itemIcon"+this.id] 
    doc.yPos=doc.yPos+this.navObj.clip.height 
  } 
} 
 
 
// Methods common to both objects (pseudo-inheritance) 
// ******************************************************** 
 
function display() 
{ 
  if (browserVersion == 1) 
    this.navObj.style.display = "block" 
  else 
    this.navObj.visibility = "show" 
} 
 
function createEntryIndex() 
{ 
  this.id = nEntries 
  indexOfEntries[nEntries] = this 
  nEntries++ 
} 
 
// total height of subEntries open 
function totalHeight() //used with browserVersion == 2 
{ 
  var h = this.navObj.clip.height 
  var i = 0 
   
  if (this.isOpen) //is a folder and _is_ open 
    for (i=0 ; i < this.nChildren; i++)  
      h = h + this.children[i].totalHeight() 
 
  return h 
} 
 
 
// Events 
// ********************************************************* 
 
function clickOnFolder(folderId) 
{ 
  var clicked = indexOfEntries[folderId] 
 
  if (!clicked.isOpen) 
    clickOnNode(folderId) 
 
  return  
 
  if (clicked.isSelected) 
    return 
} 
 

function clickOnNode(folderId) 
{ 
  var clickedFolder = 0 
  var state = 0 
 
  clickedFolder = indexOfEntries[folderId] 
  state = clickedFolder.isOpen 
 
  clickedFolder.setState(!state) //open<->close  
} 
 

function initializeDocument() 
{ 
    if(doc.all) 
        browserVersion = 1; //IE4
    else if(doc.layers)
        browserVersion = 2; //NS4
    else 
        browserVersion = 0; //other
 
    foldersTree.initialize(0, 1, "");
    foldersTree.display();
  
    if(browserVersion > 0) {
        doc.write("<layer top="+indexOfEntries[nEntries-1].navObj.top+">&nbsp;</layer>");

    // close the whole tree
    clickOnNode(0) 

    // open the root folder 
    clickOnNode(0) 
  } 
} 
 

// Auxiliary Functions for Folder-Treee backward compatibility 
// ********************************************************* 

function gFldr(description, hreference) 
{ 
    folder = new Folder(description, hreference);
    return folder;
} 




function gLnk(target, description, linkData, itemImg) 
{ 
  fullLink = "" 
 
  if (target==0) 
  { 
    if(linkData != "")
        fullLink = "'"+linkData+"' target=\"basefrm\"" 
    else
        fullLink = "";
  } 
  else 
  { 
    if (target==1) {
       if(linkData != "")
           fullLink = "'http://"+linkData+"' target=_blank" 
       else
           fullLink = "";
       
    }
    else { // target == 2
       if(linkData != "")
           fullLink = "'http://"+linkData+"' target=\"basefrm\"" 
       else
           fullLink = "";

    }
  } 
 
  linkItem = new Item(description, fullLink, itemImg)   
  return linkItem 
} 
 
function insFldr(parentFolder, childFolder) 
{ 
  return parentFolder.addChild(childFolder) 
} 
 
function insDoc(parentFolder, document) 
{ 
  parentFolder.addChild(document) 
} 

 
// Global variables 
// **************** 
 
USETEXTLINKS = 1;
indexOfEntries = new Array;
nEntries = 0;
doc = document;
browserVersion = 0;
selectedFolder=0;
imagebase = "/sw_lib/images/";

