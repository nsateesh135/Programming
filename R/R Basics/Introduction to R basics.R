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

v1[1] # 100
v2[3] # 300

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

#Matrix (2D arrays)
# To create a sequence of numbers use : operator (For example, 1:10 creates sequence of numbers between 1 to 10)
goog <- c(450,451,452,453,468)
msft <- c(230,231,232,233,220)

stocks <- c(goog,msft)
days <- c('Mon','Tue','Wed','Thu','Fri')
company_name <- c('Google','Microsoft')

stock_matrix <- matrix(stocks,nrow = 2, byrow = T)

stock_matrix

colnames(stock_matrix) <- days
rownames(stock_matrix) <- company_name

#Matrix operations 
mat <- matrix(1:25,nrow = 5, byrow = T)
mat

mat + mat # element by element or scalar operation
mat - mat 
mat * mat # This is scalar multiplication 
mat %*% mat # This is vector multiplication
mat/mat
1/mat # Reciprocal of every element in a matrix

mat[mat>5] # Returns vector (6 11 16 21  7 12 17 22  8 13 18 23  9 14 19 24 10 15 20 25) position where condition is TRUE

colSums(stock_matrix) # Sums elements across columns
rowSums(stock_matrix) # Sums elements across rows
colMeans(stock_matrix) # Mean of elements across columns
rowMeans(stock_matrix) # Mean of elements across rows
sum(stock_matrix)

# use rbind and cbind to add rows and columns to an existing matrix

FB <- c(310,311,312,313,325)
tech_stocks <- rbind(stock_matrix,FB)
tech_stocks

avg_stock_price <- rowMeans(tech_stocks)
avg_stock_price

tech_stocks <- cbind(tech_stocks,avg_stock_price)
tech_stocks

# Matrix indexing
# mat[rows,columns]
mat <- matrix(1:50,byrow = T, nrow=5)
mat[1,] # Data for the first row
mat[,1] # Data for the first column
mat[1:3,2:4]

# Factor() used to create categorical matrices
# 2 types: Nominal(no order) and ordinal(order) categorical variables

#Nominal
cars <- c("honda","maruti",'hyndai','honda','skoda')
cust_id <- c(1,2,3,4,5)
car_fact <- factor(cars)
car_fact

#Ordinal
temp <- c("cold","med","hot","hot","med","cold")
temp_fact <- factor(temp,ordered = T,levels = c("cold","med","hot"))
temp_fact
summary(temp_fact)
summary(temp)

#is method is used to check, if it is a particular data structure but class method is used to check if its a particular data type
mat <- matrix(1:25,byrow = T,nrow = 5)
mat
is.matrix(mat)
is.array(mat)
is.data.frame(mat)

# How to use runif function?
runif(20, min = 0, max = 100)

mat2 <- matrix(runif(20, min = 0, max = 100),nrow=4)
mat2

# Dataframes
# Use data() : to list all built in data sets in R
# head() : returns first six rows of the dataframe
# tail() : returns last six rows of the dataframe
# str() : returns structure of the dataframe(like variable names and data types)
# summary(): returns statistical data(quartile,mean,max) for each column in the dataframe

# Creating dataframe from vectors
# Vector names become column names 
# In order to pass column names data.frame(row.names = ,)

v1 <- c("Mon","Tue","wed","Thu","Fri")
v2 <- c(36.2,35.7,36.7,39,41.5)
v3 <- c(T,T,F,F,T)

df <- data.frame(v1,v2,v3)
df
str(df)

# Indexing and slicing dataframe

df[1,] # Returns first row of the dataframe
df[,1] # Returns first column of the dataframe
df[,'v3'] # Returns all values from all rows and column v3
df[1:5,c('v1','v2')] # Returns values from rows 1 to 5 and columns v1 and v2
df$v1 # Select a particular column, the output is a vector
df['v1'] # Select a particular column, the output is a dataframe with column v1

subset(df,subset = v3==TRUE)
subset(df,subset = v2>38)

df
sort_temp <- order(df['v2']) # Index number in ascending order
sort_temp
df[sort_temp,] # ascending order

sort_desc_temp <- order(-df['v2']) # Index number in descending order
sort_desc_temp
df[sort_desc_temp,] # descending order

# Dataframe Operations
# Creating Data Frames
empty_df <- data.frame() # empty dataframe
v1 <- c(1:10)
v2 <- letters[1:10] #Letters is a default vector which outputs vector of letters from a to z
df <- data.frame(col.name.1 = v1, col.name.2=v2)
df 

# Importing and Exporting Data
data_read <- read.csv('some_file.csv')
data_write <- write.csv(df,file='saved_df.csv') # While writing data to csv make sure to drop index column

nrow(df) # Returns number of rows
ncol(df) # Returns number of columns
colnames(df) # Returns column names
rownames(df) # Returns row names
str(df) # Returns structure of the dataframe(var names, datatype)
summary(df)# Returns statistical results from each column in a dataframe

# Referencing cells
df[[5,2]]
df[[5,'col.name.2']]
df[[2,'col.name.1']] <- 999

#Referencing rows
df[1,]

#Referencing columns as vectors
df$col.name.1
df[[,'col.name.1']]
df[[,2]]
df[['col.name.2']]

#Referencing columns as dataframe
df['col.name.2']

#Referencing multiple columns
df[c('col.name.1','col.name.2')]

# Adding Rows
df2 <- data.frame(col.name.1 = 2000,col.name.2 = 'new')
df_new <- rbind(df,df2)
df_new

#Adding columns
df
df$col.name.3 <- 2*df$col.name.1
df$col.name.3.copy <- df$col.name.3 # Creates a new column which is a copy of col.name.3
df[,'col.name.4'] <- df$col.name.2
df

# Setting column names
colnames(df) <- c('1','2','3','4','5') # Change all column names
colnames(df)[1] <- 'New col name' # change a particular column name

# Setting row names
rownames(df) <- c("A","B","C")

#Selecting multiple rows
df[1:10,] # Select first 10 rows
df[1:3,] # Select first 3 rows
head(df,5) # First 5 rows of the dataframe
df[-2,] # Everything excluding 2nd row
head(mtcars)
mtcars[mtcars$mpg>20,]
mtcars[(mtcars$mpg>20) & (mtcars$cyl==6),][,'hp']

# Dealing with missing Data
is.na(df) # Returns data frame with Boolean values
any(is.na(df)) # Returns True/False if any element in the dataframe is true or false
any(is.na(mtcars$mpg)) # Check if a particular column has missing values

df[is.na(df)] <- 0 # Assign 0 to all missing values in a dataframe
mtcars$mpg[is.na(mtcars$mpg)] <- mean(mtcars$mpg) # Replace missing values of a particular column with mean of the column values

# as function is used to convert to a particular data type
mat <- matrix(1:25,nrow =5)
as.data.frame(mat)

#round() function 
# round(x, digits = )
df$performance <- round(df$performance,digits = 2)

# Use mtcars data set and find average mpg for cars that have more than 100 hp AND a wt value of more than 2.5
head(mtcars)
mean(mtcars[mtcars$hp>100 & mtcars$wt>2.5,]$mpg)

#Lists 
# Helps combine multiple data structures(More like an organisation tool)
v <- c(1,2,3)
m <- matrix(1:10,nrow=2)
df <- mtcars

my_list <- list(my_vector = v,my_matrix = m,my_df = df)
my_list

#Indexing lists
my_list$my_vector
my_list[1]
class(my_list)
class(my_list$my_vector)
class(my_list[['my_vector']])


double_list <- c(my_list,my_list) # Combining 2 lists
double_list

str(my_list) # number and kind of data structure in a list 


#Data Input and Output with R 

#CSV File
# Reading a csv file creates a dataframe
help("read.csv")/
write.csv(mtcars,file="myexample.csv") # Create a csv file
read.csv('example.csv') # Read a csv file

# EXCEL Files
# readxl and writexl library to read and write to excel file(https://readxl.tidyverse.org/)
#install.packages('readxl') to read from excel file
#install.packages('xlsx') to write to excel file
library(readxl)
library(xlsx)
excel_sheets('example.xlsx') # Lists sheet in the excel worksheet
read_excel('example.xlsx',sheet = 'Sheet1')
write.xlsx(mtcars,file = "example.xlsx")

#lapply : list apply 
#Step 1: Extract all sheet names as list 
#Step 2: apply read_excel to each element in the list obtained in step 1 
#Step 3: Specify path from which we can fetch the entire notebook
entire_workbook <- lapply(excel_sheets('example.xlsx'), read_excel,path = '')

#SQL with R 
# Most of the SQL libraries are built of RODBC package 
# install.packages("RODBC")
#library("RODBC")
myconn <- odbcConnect("Database_Name",uid="User_ID",pwd="password")
querydat <- sqlFetch(myconn,"Table_Name")
querydat <- sqlQuery(myconn,"SELECT * FROM table")
close(myconn)

#Web scraping with R 
# import.io : automated way of extracting data from websites
# install.packages('rvest)
library('revest')
demo(package = 'rvest') # List demo datasets
demo(package = 'rvest',topic = 'tripadvisor') # provides all required code