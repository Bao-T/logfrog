<html>
<head>
<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="qrcode.js"></script>
</head>
<body>

<?php 

    include('phpqrcode/qrlib.php'); 
     //http://phpqrcode.sourceforge.net/examples/index.php?example=020
    // outputs image directly into browser, as PNG stream 
    ?>
<?php
$loops = 0;
if (isset($_REQUEST['loopy'])) {
    $loops = intval($_REQUEST['loopy']);
}
?>
<form>
how many qr codes? <input type='text' name='loopy'>
<input type='submit'>
</form>

<?php
if ($loops != 0) {
    for ($i=0; $i<$loops; $i=$i+1) {
        //generate your random string
        //call qrcode library to get the code.
        //display qrcode in <img>
        $createID = "";
        for ($j = 0; $j < 32; $j=$j+1){
            $createID = $createID.chr(rand(256));
        }
        
        QR::png($createID, $createID.".png");
        echo "<img src= '".$createID.".png'> <br/>";
?>

<!-- The core Firebase JS SDK is always required and must be listed first -->
<script src="/__/firebase/6.0.2/firebase-app.js"></script>
<script src="/__/firebase/6.0.2/firebase-firestore.js"></script>
<!-- Initialize Firebase -->
<script src="/__/firebase/init.js"></script>
<script src="/main.js"></script>


<!-- TODO: Add SDKs for Firebase products that you want to use
     https://firebase.google.com/docs/web/setup#reserved-urls -->

</body>
</html>