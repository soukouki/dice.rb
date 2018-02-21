
require_relative "./dice"

def assert_equal a, b
	if a!=b
		puts "fail\n#{a}\n#{b}"
	end
end

assert_equal "(1d6)", Dice.new("1d6").to_s
assert_equal "(1+1)", Dice.new("1+1").to_s
assert_equal "(2+(2*2))", Dice.new("2+2*2").to_s
assert_equal "((10-3)-3)", Dice.new("10-3-3").to_s
assert_equal "((2/2)/2)", Dice.new("2/2/2").to_s
assert_equal 2, Dice.new("1d6*2").min
assert_equal 20, Dice.new("10+1d10").max
assert_equal 5.5, Dice.new("1d10").median
assert_equal 3, Dice.new("1*4-1").sample # 計算機にもなる
assert_equal 1, Dice.new("1d1").sample
