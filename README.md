# dice.rb
サイコロを表現できる(?)

Dice.newすることができる文字列

```BNF
expression := mul_div { ( "+" | "-" ) mul_div }
mul_div :=  pow { ( "*" | "/" ) pow }
pow := dice_int | dice_int "^" pow
dice_int := int_parentheses | int_parentheses "d" int_parentheses
int_parentheses := int | "(" expression ")"
int := int_l | ( "+" | "-" ) int_l
```

2d2d2は成立しない。(2d2)d2または2d(2d2)と書くように。

0割りの可能性がある場合はエラーが出る。
さいころの振り数・面数がマイナスになる可能性がある場合はエラーが出る。

TODO : 最頻値、分布、標準偏差
