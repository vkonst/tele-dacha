<!DOCTYPE=HTML>
<html>
<head>
</head>
<body>
<?PHP
  // Original PHP code by Chirp Internet: www.chirp.com.au
  // Please acknowledge use of this code by including this header.

  function getFileList($dir)
  {
    // array to hold return value
    $retval = array();

    // add trailing slash if missing
    if(substr($dir, -1) != "/") $dir .= "/";

    // open pointer to directory and read list of files
    $d = @dir($dir) or die("getFileList: Failed opening directory $dir for reading");
    while(false !== ($entry = $d->read())) {
      // skip hidden files
      if($entry[0] == ".") continue;
      if(is_dir("$dir$entry")) {
        $retval[] = array(
          "lastmod" => filemtime("$dir$entry"),
          "name" => "$dir$entry/",
          "type" => filetype("$dir$entry"),
          "size" => 0
        );
      } elseif(is_readable("$dir$entry")) {
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
?>

<?PHP
function cmp($a, $b)
{
   $res=strcmp($a['lastmod'], $b['lastmod']);
#  $res=strcmp($a['name'], $b['name']);
  if ( $res != 0 ) {
    $res=-$res;
  }
  return $res;
}
?>

<h1>vkhome-fi</h1>

<table class="collapse" border="1">
<thead>
<tr><th></th></tr>
</thead>
<tbody>
<?PHP

$dir=$_GET[dir];
$type=$_GET[type];

if ( $dir == "" ) {
  $dir=".";
  }
else {
  $dir="./".$dir;
  }

switch ($type) {
case "jpg":
  $regex="/\.jpg$/";
  break;
case "txt":
  $regex="/\.txt$/";
  break;
case "png":
  $regex="/\.png$/";
  break;
case "swf":
  $regex="/\.swf$/";
  break;
default :
  $regex="/\.jpg$/";
}

// echo $dir;
// echo $type;

  $dirlist = getFileList($dir);
  usort($dirlist, "cmp");
// print_r("$dirlist");

  foreach($dirlist as $file) {
    if(!preg_match($regex, $file['name'])) continue;
    echo "<tr>\n";
    echo "<td><a href=\"{$file['name']}\"><img src=\"{$file['name']}\" width=\"256\" alt=\"\">\n";
    echo "<br />";
    echo date('r', $file['lastmod']),"</td>\n</a>";
    echo "</tr>\n";
  }
?>

