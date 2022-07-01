<?php
//connect to the database with credentials

$conn = mysqli_connect("localhost", "root", "Adekemi24.", "rfm_data_mysql");

// Check connection
if ($conn === false) {
  die("ERROR: Could not connect. "
    . mysqli_connect_error());
}

// Taking  values from the form data(input)
$volatile_location =  $_REQUEST['volatile_location'];
$volatility_type = $_REQUEST['volatility_type'];

// Performing insert query execution
// here our table name is volatile_area
$sql = "INSERT INTO volatile_area  VALUES ('$volatile_location',
            '$volatility_type')";

if (mysqli_query($conn, $sql)) {
  echo "<h3>data stored in a database successfully.</h3>";

  echo nl2br("\n$volatile_location\n $volatility_type\n");
} else {
  echo "ERROR: Hush! Sorry $sql. "
    . mysqli_error($conn);
}

// Close connection
mysqli_close($conn);
