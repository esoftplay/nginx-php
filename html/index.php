<!DOCTYPE html>
<html lang="en">
<head>

  <!-- Basic Page Needs
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <meta charset="utf-8">
  <title>Docker | esoftplay/nginx-php</title>
  <meta name="description" content="">
  <meta name="author" content="">

  <!-- Mobile Specific Metas
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <!-- FONT
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <link href="https://fonts.googleapis.com/css?family=Montserrat" rel="stylesheet">

  <!-- CSS
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <link rel="stylesheet" href="css/normalize.min.css">
  <link rel="stylesheet" href="css/skeleton.min.css">

  <!-- Favicon
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <link rel="icon" type="image/png" href="images/favicon.png">

</head>
<body>

  <!-- Primary Page Layout
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <div class="container">
    <div class="row">
      <div class="one-half column" style="margin-top: 25%">
        <img height="45px" src="https://esoftplay.com/images/esplogo.png">
        <h4>Congratulations!</h4>
        <p>You have successfully deployed a <strong>docker</strong> container running our <strong>NGINX</strong> with <strong>PHP-FPM 7.x</strong> image</p>
        <p><strong>NGINX: </strong>v<?php echo $_ENV['NGINX_VERSION'] ?><br><strong>PHP-FPM: </strong>v<?php echo phpversion(); ?><br><strong>LOADED CONFIG: </strong><?php echo php_ini_loaded_file(); ?><br><strong>WEB ROOT: </strong><?php echo $_ENV['DOCUMENT_ROOT'] ?><br><strong>HOSTNAME: </strong><?php echo gethostname(); ?><br></p>
          <em>Thank you for using <a style="text-decoration:none" href="https://esoftplay.com" target="_blank">esoftplay.com</a></em>
      </div>
    </div>
  </div>

<!-- End Document
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
</body>
</html>
