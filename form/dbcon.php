<?php

$servername = "localhost";
$username = "root";
$password = "Adekemi24.";
$dbname = "rfm_data_mysql";

// Create connection
$conn = new mysqli($servername,
	$username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
	die("Connection failed: "
		. $conn->connect_error);
}

$sqlquery = "INSERT INTO table VALUES
	('John', 'Doe')"

if ($conn->query($sql) === TRUE) {
	  echo "record inserted successfully";
} 
else {
	echo "Error: " . $sql . "<br>" . $conn->error;
}
