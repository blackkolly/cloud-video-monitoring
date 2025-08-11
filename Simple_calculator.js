//The calculator should be able to perform basic operations like Addition, Subtraction, Multiplication, & Division
//Input a num1
const num1 = parseFloat(prompt("Enter your num:"));
//Input a num2
const num2 = parseFloat(prompt("Enter your num2 "));
//Input the operator
const operator = prompt("Enter the operator like +,x,-")
//condition statement
if (operator == "+") {
  //Addition of two numbers
  result = num1 + num2;
  console.log(result);
}
//subtract two numbers
else if (operator == "-") {
  result = num1 - num2;
  console.log(result);
}
//Mutiply two numbers
else if (operator == "*") {
  result = num1 * num2;
  console.log(result);
}




