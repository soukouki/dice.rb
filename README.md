# dice.rb
サイコロを表現できる(?)

Dice.newすることができる文字列

expression := mul_div | mul_div + expression | mul_div - expression
mul_div :=  pow | pow * mul_div | pow / mul_div
pow := dice_int | dice_int ^ dice_int  # 2^2^2は成立しない。(2^2)^2または2^(2^2)と書くように。
dice_int := int_parentheses | int_parentheses d int_parentheses # 同じく2d2d2は成立しない。(2d2)d2または2d(2d2)と書くように
int_parentheses := int | ( expression )

(ただし字句解析で符号付きのintは処理される)

TODO : 最頻値、分布、標準偏差
