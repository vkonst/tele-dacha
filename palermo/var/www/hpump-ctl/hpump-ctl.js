// Javascript function interface for HeatPump@vkhome-fi
// based on code by SM.Ching http://ediy.com.my

var refreshTimeout = 10000; //set refresh timer to 10 seconds
var myTimer = setInterval(function(){getStatus()},0); //define which function to be trigger
var url;
var camst;	// "live" or "off-line" webcam stream
var micst;      // "on" or "off" sound stream from webcam

function keyPressed(e)
{
	var keynum
	var keychar

	if(window.event) // IE
	{
		keynum = e.keyCode
	}
	else if(e.which) // Netscape/Firefox/Opera
	{
		keynum = e.which
	}

	keychar = String.fromCharCode(keynum); //convert keycode to character
        keychar = keychar.toUpperCase(); //convert input to upper case

        if(keychar == "C") runCmd("cam");
        if(keychar == "H") runCmd("snapshot");
	if(keychar == "M") runCmd("mic");
	if(keychar == "W") runCmd("up");
	if(keychar == "A") runCmd("left");
	if(keychar == "S") runCmd("down");
	if(keychar == "D") runCmd("right");

	return true;
};

function keyUp(e)
{
  var keynum
  var keychar

  if(window.event) // IE
  {
    keynum = e.keyCode
  }
  else if(e.which) // Netscape/Firefox/Opera
  {
    keynum = e.which
  }

  if (keynum == 32) runCmd("up");	//up arrow
  if (keynum == 37) runCmd("left");	//left arrow
  if (keynum == 38) runCmd("up");	//up arrow
  if (keynum == 39) runCmd("right");	//right arrow
  if (keynum == 40) runCmd("down");	//down arrow

  return true;
};


// run this function when webpage start load
function autoRun() {
  camst = "off-line";
  updateCam(camst);
  micst = "off";
  updateCam(camst);
  updateMic(micst);
  runCmd("connect");
};


// get all relay status from serial device & update display
function getStatus(){
  	// runCmd("status");
};


// called by image onClick (see index.html)
function runCmd(command) {
	clearInterval(myTimer); //clear timer whenever a command is executed
	myTimer = setInterval(function(){getStatus()},refreshTimeout); //start a new timer
	xmlhttpGet(command);
};


// Ajax
function xmlhttpGet(command) {
	var xmlHttpReq = false;
	var self = this;
	var serialMessage;    
	// Mozilla/Safari
	if (window.XMLHttpRequest) {
		self.xmlHttpReq = new XMLHttpRequest();
	}
	// IE
	else if (window.ActiveXObject) {
		self.xmlHttpReq = new ActiveXObject("Microsoft.XMLHTTP");
	}
	
	codeURL(command);
        self.xmlHttpReq.open('GET', url, true);
	self.xmlHttpReq.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	self.xmlHttpReq.onreadystatechange = function() {
		if (self.xmlHttpReq.readyState == 4) {
			serialMessage = self.xmlHttpReq.responseText;
			//serialMessage = url;
			updatePage(serialMessage);
		        if ( command == "cam" ) updateCam("switch");
		        if ( command == "mic" ) updateMic("switch");
                        updateBanner();
 		        if ( command == "snapshot" ) updateSnap();
		        restoreButton(command);
		}
                if (self.xmlHttpReq.readyState == 3) {
                        serialMessage = self.xmlHttpReq.responseText;
                        updatePage(serialMessage);
                }
	}
        disableButton(command);
	self.xmlHttpReq.send();
};

function codeURL(command) {
	strURL = "/cgi-bin/hp-ctl.sh";
	//var start_character = "&"; 
	url = strURL + "?cmd=" + command;
	if ( command == "cam" || command == "mic" ) url = url + "&camst=" + camst + "&micst=" + micst;
};

// update status bar
function updatePage(str){
	document.getElementById("result").innerHTML = str;
};

function disableButton(cmd) {
 if( cmd == "cam" || cmd == "mic" || cmd == "up" || cmd == "left" || cmd == "down" || cmd == "right" ) {
 var pic = document.getElementById(cmd);
 pic.src = "images/stop.png";
 pic.style.opacity = "0.4";
 }
}

function restoreButton(cmd) {
 if( cmd == "cam" || cmd == "mic" || cmd == "up" || cmd == "left" || cmd == "down" || cmd == "right" ) {
 var pic = document.getElementById(cmd);
 pic.src = "images/" + cmd  + ".png";
 pic.style.opacity = "1.0";
 if ( cmd == "cam" && camst == "live" ) pic.style.opacity = "0.4";
 if ( cmd == "mic" && micst == "on" ) pic.style.opacity = "0.4";
 }
}

/*
var urlParts = window.location.href.split("/");
var liveUrl = urlParts[0] + '//' + urlParts[2] + ':8083';
*/
function updateCam(state) {
 var pic = document.getElementById("live");
 if ( state == "switch" ) {
  if ( camst == "live" ) updateCam("off-line"); else updateCam("live");
 } else {
  if ( state == "live" ) { 
    // pic.src = liveUrl;
    pic.src = '/hpump_cam/';
    pic.style.opacity = "1.0";
  } else {
    pic.src = "images/lastsnap.jpg?t=" + new Date().getTime();
    pic.style.opacity = "0.8";
  }
  camst = state;
 }
}

function updateSnap() {
  if ( camst == "off-line" ) document.getElementById("live").src = "images/lastsnap.jpg?t=" + new Date().getTime();
}

function updateMic(state) {
 if ( state == "switch" ) {
   if ( micst == "on" ) updateMic("off"); else updateMic("on");
 } else {
  micst = state;
 }
}

function updateBanner() {
  document.getElementById("banner").innerHTML = "picture: " + camst + " & " + "sound: " + micst;
}
