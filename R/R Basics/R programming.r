# Logical Operators
# AND(&), OR(|) , NOT(!) 

df <- mtcars
head(df)

#Grab rows with cars of at least 20mpg and over 100 hp.
df[(df$mpg>=20) & (df$hp>100),]

# Logical operators with vectors
tf <- c(TRUE,FALSE)
tt <- c(TRUE,TRUE)
ft <- c(FALSE, TRUE)

tt & tf # Element by element logical check so [1]  TRUE FALSE
tt | tf #Element by element logical check so [1] TRUE TRUE

ft && tt # [1] FALSE
tt || tf # [1] TRUE

# if, else, else if Statements
# Items sold that day
ham <- 10
cheese <- 10

# Report to HQ
report <- 'blank'


if(ham >= 10 & cheese >= 10){
  report <- "Strong sales of both items"
  
}else if(ham == 0 & cheese == 0){
  report <- "Nothing sold!"
}else{
  report <- 'We had some sales'
}
print(report)

# while Loop
# while loops are a while to have your program continuously run some block of code until a condition is met (made TRUE). The syntax is:
# Use ctrl+c to kill an infinite loop
  while (condition){
    # Code executed here 
    # while condition is true
  }

# cat() : Printing a variable with a string
# alternative : paste0()
var <- 'a variable'
cat('My variable is: ',var)
print(paste0("Variable is: ", var))

x <- 0

while(x < 10){
  
  cat('x is currently: ',x)
  print(' x is still less than 10, adding 1 to x')
  
  # add one to x
  x <- x+1
  if(x==10){
    print("x is equal to 10! Terminating loop")
  }
}

# break command to terminate a while loop
x <- 0

while(x < 10){
  
  cat('x is currently: ',x)
  print(' x is still less than 10, adding 1 to x')
  
  # add one to x
  x <- x+1
  if(x==10){
    print("x is equal to 10!")
    break
    print("I will also print, woohoo!")
  }
}

# for loops
#A for loop allows us to iterate over an object (such as a vector) and we can then perform and execute blocks of codes for every loop we go through. The syntax for a for loop is:
  
  for (temporary_variable in object){
    # Execute some code at every loop
  }

vec <- c(1,2,3,4,5)
for (temp_var in vec){
  print(temp_var)
}

for (i in 1:length(vec)){
  print(vec[i])
}

# for loop over a list 
li <- list(1,2,3,4,5)

for (i in li){ # Use case 1 
  print(i)
}

for (i in 1:length(li)){
  print(li[[i]]) # Same result as use case 1 because of the double bracket
}

# for loop over a matrix
mat <- matrix(1:25,nrow=5)
mat
for (num in mat){
  print(num)
}

# Nested for loop
for (row in 1:nrow(mat)){
  for (col in 1:ncol(mat)){
    print(paste('The element at row:',row,'and col:',col,'is',mat[row,col]))
  }
}

# Functions
# Simple function, no inputs!
hello <- function(){
  print('hello!')
}
#hello()

helloyou <- function(name){
  print(paste('hello ',name))
}
#helloyou('Nehal')

# add 2 numbers
add_num <- function(num1,num2){
  print(num1+num2)
}
#add_num(5,10)

# Pass default values for arguments 
hello_someone <- function(name='Frankie'){
  print(paste('Hello ',name))
}
# hello_someone() : [1] "Hello  Frankie"

# return values to a function 
formal <- function(name='Sam',title='Sir'){
  return(paste(title,' ',name))
}

# formal('Issac Newton'): [1] "Sir   Issac Newton"

# Build a function to check if a number is a prime number

prime_check <- function(num){
  # Could put more checks for negative numbers etc...
  if (num == 2) {
    return(TRUE)
  }
  for (x in 2:(num-1)){
    
    if ((num%%x) == 0){
      return(FALSE)
    }
  }
  return(TRUE)
  
}

# Scope
#Scope is the term we use to describe how objects and variable get defined within R.
#When discussing scope with functions, as a general rule we can say that if a variable is defined only inside a function than its scope is limited to that function. 
# Multiplies input by 5
times5 <- function(input) {
  result <- input ^ 2
  return(result)
}

pow_two(4)
result # Not defined outside the scope of the function
input # Not defined outside the scope of the function

double <- function(a) {
  a <- 2*a
  a
}
var <- 5
double(var) # [1] 10
var # [1] 5

