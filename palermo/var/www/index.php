<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title>vkhome-fi</title>
 <meta http-equiv="Cache-Control" content="no-cache" />
 <meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1">
 <meta http-equiv="Pragma" content="no-cache" />
 <meta http-equiv="Refresh" content="600" />
 <style>
 <style>
a:link    {color:#000000; background-color:transparent; text-decoration:none}
a:visited {color:#000000; background-color:transparent; text-decoration:none}
a:hover   {color:#ff0000; background-color:transparent; text-decoration:underline}
a:active  {color:#ff0000; background-color:transparent; text-decoration:underline}
</style> 
 </style>
</head>

<body>
<?PHP

function getFileList($dir, $regex)
{
// Original PHP code by Chirp Internet: www.chirp.com.au
// Please acknowledge use of this code by including this header.

  // array to hold return value
  $retval = array();
  // add trailing slash if missing
  if(substr($dir, -1) != "/") $dir .= "/";
  // open pointer to directory and read list of files
  $d = @dir($dir) or die("getFileList: Failed opening directory $dir for reading");
  while( false !== ($entry = $d->read()) ) {
    // skip hidden files
    if($entry[0] == ".") continue;
    // skip mismatching filenames
    if(!preg_match($regex, $entry)) continue;
    if( ! is_dir("$dir$entry")) {
      $retval[] = array(
        "name" => "$dir$entry",
        "type" => mime_content_type("$dir$entry"),
        "size" => filesize("$dir$entry"),
        "lastmod" => filemtime("$dir$entry")
      );
    }
  }
  $d->close();
  return $retval;
}

function cmp($a, $b)
{
   $res=strcmp($a['lastmod'], $b['lastmod']);
  if ( $res != 0 ) {
    $res=-$res;
  }
  return $res;
}

function filesize_formatted($_bytes)
{
    $bytes = $_bytes;

    if ($bytes >= 1073741824) {
        return number_format($bytes / 1073741824, 2) . ' GB';
    } elseif ($bytes >= 1048576) {
        return number_format($bytes / 1048576, 2) . ' MB';
    } elseif ($bytes >= 1024) {
        return number_format($bytes / 1024, 2) . ' KB';
    } elseif ($bytes > 1) {
        return $bytes . ' bytes';
    } elseif ($bytes == 1) {
        return '1 byte';
    } else {
        return '0 bytes';
    }
}

?>
<table border="1" class="collapse">
<tbody>
<tr>

<td valign="top">
<?PHP
$filename = './webcams/cam4-lastsnap.jpg';
if (file_exists($filename)) {
  echo "<a href=\"$filename\" target=\"_blank\"><img height=\"170\" src=\"$filename\"></a><br>";
  echo "<small>";
  echo date ("r", filemtime($filename));
  echo "</small>";
}
?>
<br>

<?PHP
$filename = './webcams/cam3-lastsnap.jpg';
if (file_exists($filename)) {
  echo "<a href=\"$filename\" target=\"_blank\"><img height=\"170\" src=\"$filename\"></a><br>";
  echo "<small>";
  echo date ("r", filemtime($filename));
  echo "</small>";
}
?>
<br>

<?PHP

  echo "<br />Recent webcam records:<small></br>";
  echo "<div style=\"overflow:auto;width:100%;height:150px;border:1px solid #ccc;\">";
  $regex="/\.swf$/";

  $dir="./webcams/cam3/";

  $dirlist = getFileList($dir, $regex);
  usort($dirlist, "cmp");
  foreach($dirlist as $file) {
    echo "<a href=\"{$file['name']}\" target=\"_blank\">",date('d-M H:i', $file['lastmod'])," - ", filesize_formatted($file['size']),"</a></br>","\n";
  }

  $dir="./webcams/cam3-lastarchive/";
  $dirlist = getFileList($dir, $regex);
  usort($dirlist, "cmp");
  foreach($dirlist as $file) {
    echo "<a href=\"{$file['name']}\" target=\"_blank\">",date('d-M H:i', $file['lastmod'])," - ", filesize_formatted($file['size']), "</a></br>","\n";
  }

  echo "</small>";
  echo "</div>"
?>

</br>
<a target="_blank" href="road_cam/?action=stream">live road cam</a></br>
<a target="_blank" href="webcams/cam3-archive/?C=M;O=D">webcams archive</a></br>
<a target="_blank" href="cgi-bin/1w_rrdgraph.cgi">more graphs...</a></br>
<a target="_blank" href="water/">water meter</a></br>
<a target="_blank" href="hpump-ctl/">heat pump</a></br>
<a target="_blank" href="vent-ctl/">ventillation</a></br>
<a target="_blank" href="usbhub-ctl/">USB-hub</a></br>
<a target="_blank" href="http://192.168.XXX.XX2:2121">one-wire iface</a></br>
<a target="_blank" href="cgi-bin/1w_rrdgraph.cgi?timespan=30d&start=&rrd=temperature-heat_centralroom_l&rrd=temperature-central_room&rrd=temperature-outdoor&dsname=&width=&debug=">
  heat temperatures
</a></br>
<a target="_blank" href="cgi-bin/re3m_get-updates-for-last-two-minutes.cgi?format=json">
last&nbsp;
<?PHP
$output=shell_exec('/usr/lib/cgi-bin/re3m_get-updates-for-last-two-minutes.cgi');
echo "$output";
?>
&nbsp;sensor readings
</a></br>
<a target="_blank" href="cgi-bin/apcupsd/upsstats.cgi?host=127.0.0.1&temp=C">
  UPS stats
</a></br>
<a target="_blank" href="php-collection/index.php">collectd graphs</a></br>
</td>

<td valign="top">
<a target="_blank" href="cgi-bin/room_temp_rrdgraph.cgi?timespan=3d">
<?PHP
$output=shell_exec('/usr/lib/cgi-bin/room_temp_rrdgraph.cgi --no_header --query timespan=24h');
echo "$output";
?>
</a>

<br/>
<img alt="weather forecast by foreca.fi" src="include/foreca.fi">

</td>
<br/>

</tr>

</tbody></table>

</body></html>
