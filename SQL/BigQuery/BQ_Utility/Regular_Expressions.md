# Regular Expressions [JS]


## Pipe |
- This operator means logical OR
- Example: Regular expression matches /ebooks/|/tools/

## Dot .
- dot equals one character
- Example- .ook. matches book, look, took,cook

## Asterisk * 
- matches zero or more of the previous item
- Example: boo*ks matches boks books boooks

## Dot Asterisk(.*)
- matches zero or more random characters i.e matches everything
- Example: /products/(.*)/cycles/ matches /products/men/cycles/, /products/women/cycles/, /products/kids/cycles/

## Backslash
- They turn special charaters into normal characters
- Example: IP address = 67\.172\.171\.105

## Caret ^
- Something begins with 
- Example:^shoe matches shoe and shoes

## Dollar $
- Something ends with 
- Example: shoe$ matches winter shoe

## Question mark ?
- means the last character is optional 
- useful to target misspellings
- Example : colou?r

## Parentheses()
- group characters/numbers
- Example- ^/products/(men|women|kids)/cycles/$

## Square brackets[]
- Make simple list 
- Example: t[aeo]p matches tap,tep,top
          [a-zA-Z0-9] matches lower case, upper case letters and numbers between 0 and 9

## Plus +
- Matches one or more of the previous character
- Example: boo+ks matches books,boooks  

## Curly brackets {}
- {1,2}- it means repeat the last item atleast once and no more than 2 times
- {2}- repeat the last item 2 times 
- Example- ^77\.120\.120\.[0–9]{1,2}$ matches 77.120.120.0 to 77.120.120.99

## Other charaters
- \d- Digit character
- \D- Non-digit character
- \s- White space
- \S- No white space
- \w - word
- \W- Non-word(punctuation)