/**
 * Water meter interface for 1w-system@vkhome-fi
 * file: waterMeter.js
 **/

var theMeter = function()
{
	var publicObj = {};		// placeholder to return public methods

	// for processing of counter readings
	var	SCALE = 159336;		// impulses per litre, constant (old: 158868)
	var	SCALEl = SCALE/1000;	// impulses per litre, constant
	var PRICE = 4.5;		// Eur for 1 m3, constant
	var PRICEl = PRICE/1000;	// Eur for 1 litre, constant
	var counterOffset = 446.4136;	// accumulated counter offset in m3
	var sessionOffset = 0;	// counter offset in m3 for current session
	var numOfReadings = 0;	// number of readings received for session  
	var sessionStart; 		// time when session started
	// last reading received
	var currReading = {	
		timeStamp: 0,		// seconds from epoch
		impulseCount: 0,	// quantity if counted impulses
		cubicMeters: 0,		// SCALE impulses = 1 m3
		instUsage: 0		// in litres per minute
	};
	// previous reading
	var prevReading = {
		timeStamp: 0,
		impulseCount: 0,	
		cubicMeters: 0,
		instUsage: 0
	};

	// for HTML page rendering
	var activeDataSet = "all";	// set of shown data sections on the webpage
	var classToShow = [".total", ".session", ".last"]; // list of data sections to show
	var classToHide = [".only"];	// list of data sections to hide
	var showTitle = true;	// show data section titles
	var showMoney = true;	// show price/cost data
	var showReset = true;	// show reset button/links
	var showPulse = true;	// show "pulse" string
	var showHelp = true;	// show help


	publicObj.configCounter = function(chip) {
		if ( ! isNaN(chip.offset) ) { counterOffset = Number(chip.offset); };
		if ( ! isNaN(chip.scale) ) { SCALE = Number(chip.scale); SCALEl = SCALE / 1000; };
		if ( ! isNaN(chip.price) ) { PRICE = Number(chip.price); PRICEl = PRICE / 1000; };
		updateCounterParam();
	}
	
	publicObj.updatePageTime = function() {
		$('#pageTime').text(Date());
		$('#pulse').text( ( Date.now() / 1000 ).toFixed(0) - currReading.timeStamp );
	}
	
	function updateCounterParam() {
		$('#counterConf').text(SCALE + ", " + PRICE + ", +" + counterOffset);
	}

	function updateSessionParams() {
		$('#sessionTime').text(sessionStart);
		$('#sessionOffset').text("-" + sessionOffset.toFixed(3));
	}

	function updateSessionUsage() {
		var adjustedL = ( currReading.cubicMeters - sessionOffset ) * 1000; 
		$('#sessionLitres').text(adjustedL.toFixed(1));
		$('#sessionEur').text((adjustedL * PRICEl).toFixed(2));
	}
	
	function updateTotalUsage() {
		var adjustedCubM = currReading.cubicMeters + counterOffset;
		$('#cubicMeters').text(Math.floor(adjustedCubM));
		$('#litres').text((( adjustedCubM * 1000 ) % 1000).toFixed(1));
		// $('#m3').text(adjustedCubM.toFixed(4));
		// var litres = (( adjustedCubM * 1000 ) % 1000).toFixed(1);
		// $('#eur').text((adjustedCubM * PRICE).toFixed(2));
		// $('#hectoLitres').text(Math.floor(litres / 100));
		// $('#decaLitres').text(Math.floor((litres % 100) / 10));
		// $('#deciLitres').text(Math.floor((litres * 10) % 10));
	}
	
	function updateInstUsage() {
		$('#instLitres').text(currReading.instUsage.toFixed(1));
		$('#instCents').text((currReading.instUsage * PRICEl * 100).toFixed(2));
	}

	function updateReadingStats() {
		var d = new Date(0);
		d.setUTCSeconds(currReading.timeStamp);
		$('#readingValue').text(currReading.impulseCount);
		$('#readingNum').text(numOfReadings);
		$('#readingTime').text(d.toString());
		$('#pulse').text(" ");
	}

	publicObj.onReading = function(reading) {


		if ((!isNaN(currReading.timeStamp)) && (reading.time != currReading.timeStamp))
		{
			numOfReadings++;
			
			if (reading.value === currReading.impulseCount) {
				currReading.timeStamp = reading.time;
                if ( currReading.instUsage != 0 ) {
					currReading.instUsage = 0
					updateInstUsage();
				}
			} else {
				prevReading.timeStamp = currReading.timeStamp;
				prevReading.impulseCount = currReading.impulseCount;
				prevReading.cubicMeters = currReading.cubicMeters;
				prevReading.instUsage = currReading.instUsage;
				currReading.timeStamp = reading.time;
				currReading.impulseCount = reading.value;
				currReading.cubicMeters = reading.value / SCALE;
				currReading.instUsage = (currReading.impulseCount - prevReading.impulseCount) / ( SCALEl * ((currReading.timeStamp - prevReading.timeStamp)/60));
				if ( numOfReadings === 1 ) {
					sessionOffset = currReading.cubicMeters;
					sessionStart= Date();
					updateSessionParams();
				}
				updateTotalUsage();
				updateSessionUsage()			
				updateInstUsage();
			}
			updateReadingStats();
		}
		publicObj.updatePageTime();
	}

	publicObj.resetSession = function() {
		numOfReadings = 0;
		sessionStart = Date();
		sessionOffset = currReading.cubicMeters;
		updateSessionParams();
		updateSessionUsage();
	}

	publicObj.switchSections = function (sectionLst) {

		var i;
	
		function activateSections() {
			for( i=0; i<classToShow.length; i++) { $(classToShow[i]).show(); }
			for( i=0; i<classToHide.length; i++) { $(classToHide[i]).hide(); }

			if ( showMoney ) {
			for(i=0; i<classToShow.length; i++) { $(classToShow[i] + " .money").show(); }
			} else {
				$(".money").hide();
			}

			if (showTitle) {
				for(i=0; i<classToShow.length; i++) { $(classToShow[i] + " .headline").show(); }
			} else {
				$(".headline").hide();
			}
				
			if (showPulse) {
				$("#pulse").show();
			} else{
				$("#pulse").hide();
			}

			if (showHelp) {
				$("#help").show();
			} else{
				$("#help").hide();
			}

			if (showReset) $("#resetBut").show(); else $("#resetBut").hide();

		}	// activateSections
			
		if ( sectionLst.length === 0) { return; }
		var sections = sectionLst.split(';');

		for( i=0; i < sections.length; i++) { 
		switch (sections[i]) {

			case "togglemoney":	showMoney = ! showMoney; break;
			case "togglereset":	showReset = ! showReset; break;
			case "toggletitle":	showTitle = ! showTitle; break;
			case "togglehelp":	showHelp = ! showHelp;   break;
			case "togglepulse":	showPulse = ! showPulse; break;
			case "toggledata":
				switch (activeDataSet) {
					case "all":		this.switchSections("nototal"); break;
					case "nototal":	this.switchSections("total"); break;
					case "total":	this.switchSections("session"); break;
					case "session":	this.switchSections("last"); break;
					case "last":	this.switchSections("all"); break;
				}
				return;	// exit after recursive call
		
			case "all":
				classToShow = [".total", ".session", ".last"];
				classToHide = [".only"];
				activeDataSet = sections[i];
				break;
			case "nototal":
				classToShow = [".session", ".last"];
				classToHide = [".total", ".only"];
				activeDataSet = sections[i];
				break;
			case "total":
				classToShow = [".total", ".only"];
				classToHide = [".session", ".last"];
				activeDataSet = sections[i];
				break;
			case "session":
				classToShow = [".session", ".only"];
				classToHide = [".total", ".last"];
				activeDataSet = sections[i];
				break;
			case "last":
				classToShow = [".last", ".only"];
				classToHide = [".total", ".session"];
				activeDataSet = sections[i];
				break;

			case "money":	showMoney = true;  break;
			case "reset":	showReset = true;  break;
			case "title":	showTitle = true;  break;
			case "pulse":	showPulse = true;  break;
			case "help":	showHelp  = true;  break;
			case "nomoney":	showMoney = false; break;
			case "noreset":	showReset = false; break;
			case "notitle":	showTitle = false; break;
			case "nohelp":	showHelp  = false; break;
			case "nopulse":	showPulse = false; break;
					
		}}	// switch, for
		activateSections();

	}	// publicObj.switchSections
		
	return publicObj;
	
}();

$(function() {

	function getUrlParameter(sParam)
	{
		var sPageURL = window.location.search.substring(1);
		var sURLVariables = sPageURL.split('&');
		for (var i = 0; i < sURLVariables.length; i++) {
			var sParameter = sURLVariables[i].split('=');
			if (sParameter[0] == sParam) {
				return sParameter[1];
			}
		}
		return '';
	}
	
	
	var sParam;

	// "default" sections of webpage to show/hide
	theMeter.switchSections("total;notitle;nomoney;nohelp;noreset");
	
	// show another sections if requested by URL
	sParam = getUrlParameter("section");
	if ( sParam.length != 0 ) { theMeter.switchSections(sParam); }

	$("#meter").click(function(event){
		if ( event.shiftKey && !event.ctrlKey) { theMeter.switchSections("togglemoney"); return false; }
		if (!event.shiftKey &&  event.ctrlKey) { theMeter.switchSections("togglepulse"); return false; }
		if (!event.shiftKey && !event.ctrlKey) { theMeter.switchSections("toggledata");  return false; }
		if ( event.shiftKey &&  event.ctrlKey) { theMeter.switchSections("togglereset"); return false; }
		return;
	});
	
	$(document).keypress(function(event){
		switch (event.which) {
			case 32: theMeter.switchSections("togglepulse"); return false;
			case 63: theMeter.switchSections("togglehelp");  return false;
			case 13:
			if ( event.shiftKey && !event.altKey && !event.ctrlKey) {theMeter.switchSections("togglemoney"); return false;}
			if (!event.shiftKey &&  event.altKey && !event.ctrlKey) {theMeter.switchSections("toggletitle"); return false;}
			if (!event.shiftKey && !event.altKey &&  event.ctrlKey) {theMeter.switchSections("togglepulse"); return false;}
			if (!event.shiftKey && !event.altKey && !event.ctrlKey) {theMeter.switchSections("toggledata");  return false;}
			if ( event.shiftKey && !event.altKey &&  event.ctrlKey) {theMeter.switchSections("togglereset"); return false;}
		};
		return;
	});

	$("#resetBut").click(function(){ theMeter.resetSession(); return false; });

	$("#helpLink").click(function()       { theMeter.switchSections('togglehelp'); return false; }); 
	$("#toggleDataLink").click(function() { theMeter.switchSections('toggledata'); return false; }); 
	$("#togglePulseLink").click(function(){ theMeter.switchSections('togglepulse'); return false; }); 
	$("#toggleTitleLink").click(function(){ theMeter.switchSections('toggletitle'); return false; }); 
	$("#toggleResetLink").click(function(){ theMeter.switchSections('togglereset'); return false; }); 

	// Read config (once)
	$.ajax({
		url: "getCounterConfig.json",
		data: { "_": $.now() },
		success: function(conf) {
			console.log('inside callback');
			theMeter.configCounter(conf);
		},
		dataType: "json"
	});

	// Read data constantly ("poll" requests)
	// 2 sec after the previous request completed create a new one
	(function poll() {
		setTimeout(
			function() {
				$.ajax(
					{ url: "getReading.json",
					data: {"_": $.now(),},
					success: function(data) { theMeter.onReading(data); },
					dataType: "json",
					complete: poll
				});
		    	},
			2000
		);
	})();
});
