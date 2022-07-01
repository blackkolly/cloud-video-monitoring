<<!DOCTYPE html>
  <html lang="en">

  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="X-UA-Compatible" content="ie=edge" />
    <link rel="stylesheet" href="style.css" />
    <title>FORM</title>
  </head>

  <body>
    <form action="insert.php" method="post">


      <div class="container">
        <h1>VOLATILE SITES AND LOCATION</h1>
        <p>Please fill in this form to register volatile area.</p>
        <hr>

        <label for="email"><b>Name of volatile Area</b></label>
        <input type="text" placeholder="Enter the volatile area" name="volatile_location" id="state" required>

        <label for="psw"><b>Types of Volatility</b></label>
        <input type="volat" placeholder="Enter the type of volatility" name="volatility_type" id="psw" required>
        <!--

        <label for="psw-repeat"><b>Level of Volatility</b></label>
        <input type="level" placeholder="Enter level" name="psw-repeat" id="psw-repeat" required>
-->
        <hr>

        <button type="submit" class="registerbtn">SUBMIT</button>
      </div>

      </div>
    </form>
  </body>

  </html>