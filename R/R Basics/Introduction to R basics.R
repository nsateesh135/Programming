# Arithmetic Operators 
# In R operations follow BODMAS (bracket- of - division - multiplication - addition - subtraction) rule

# Addition 
1 + 1
# Subtraction 
5 - 2
# Multiplication 
6*2
# Division 
8/2
# Power 
2^3
# Modulo(provide remainder)
5%%2 

# Variables 
# Use  '<-' for assignment 
# Keep the variable(s) lower case 
# If it's a long word, separate word by period or underscore (bank.account or bank_account)
bank_account <-  100
deposit <-  50 
bank_account = bank_account + deposit 

# Data Types 
# Use 'class' function to identify type of data 
# Integer[numeric] : 2 
class(2)

# Floating Point[numeric] : 2.2
class(2.3)

# Logical : TRUE or T 
class(TRUE)
class(FALSE)
class(T)
class(F)

# Character : 'hello'
class('a')

# Data Structure 

# Vector (1D)
# We can create a vector in R using combine operator 
# Vector cannot have different data types 
# Coercion : Vector coverts data types into a common data type if there are multiple data types in a vector 
# Coercion Order : Character - numeric - logical
nvec <- c(1,2,3,4,5)
cvec <- c('a','b','c')
lvec <- c(T,F)

class(nvec) # numeric
class(cvec) # character 
class(lvec) # logical

coercion <- c('a',1,T)
class(coercion) # character 

# Assigning names to vector using 'names()' function
# Assigning names to function makes it easier for indexing/slicing
days <- c('Mon','Tue','Wed','Thu','Fri','Sat','Sun')
temp <- c(32,35,36,37,38,39,40)
names(temp) <-  days

# Vector Operations
# Vector operations are element by element 

v1 <- c(1,2,3,4)
v2 <- c(4,5,6,7)

v1 + v2 # 5,7,9,11
v1 - v2 # -3,-3,-3,-3
v1 * v2 # 4,10,18,28
v1/v2 # 0.25, 0.40, 0.50, 0.57

# Built in functions 
sum(v1) # 10
mean(v1) # 2.5
sd(v1) # 1.29
prod(v1) # 24
max(v1) # 4
min(v1) # 1

# Comparison Operators

5 > 6 # FALSE
5 < 6 # TRUE
10 == (5+5) # TRUE
15 != 3*(4+1) # FALSE
121 >= (50*2)+(10*2)+1 # TRUE

# For vector it returns element by element comparison 
v1 <- c(1,2,3,3,4)
v1 >5 # FALSE FALSE FALSE FALSE FALSE

#Vector Indexing and Slicing
# Indexing : Begins at 1 
v1 <- c(100,200,300)
v2 <- c('a','b','c')

v1[1]
v2[3]

v3 <- c(19,12,12,13)
names(v3) <- c('a','b','c','d')

v3['c'] # 12

#Slicing 
v1[c(1,3)]
v2[c(2,3)]

# While working with ranges the upper bound in inclusive 
# v[1:4] Starts at 1 and includes index 4 
v <- c(1,2,3,4,5,6,7,8,9,10)
v[1:4]

# Boolean Filtering 
v[v>2]

# Getting help with R 
help('vector') # Tailored search
??numeric
help.search('vector') # Generic search 
