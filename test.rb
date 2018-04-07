
require_relative "./dice"

def assert_equal a, b
	if a!=b
		puts "fail.\n#{a}\n#{b}"
	end
end

def assert_raise type, name = nil, &block
	begin
		result = block.call
	rescue type => err
	rescue StandardError => err
		puts "fail raised #{err.class}.\n#{err}"
	else
		puts "fail not raise.\n\t#{name || result}"
	end
end

def assert_time second, name = nil, &block
	start = Time.now
	result = block.call
	time = Time.now - start
	if time >= second
		puts "fail time too long\n\t#{name || result}\n\t#{time}"
	end
end

assert_equal "(1d6)", Dice.new("1d6").to_s
assert_equal "(1+1)", Dice.new("1+1").to_s
assert_equal "(2+(2*2))", Dice.new("2+2*2").to_s
assert_equal "((10-3)-3)", Dice.new("10-3-3").to_s
assert_equal "((2/2)/2)", Dice.new("2/2/2").to_s
assert_equal "(3^(3^3))", Dice.new("3^3^3").to_s
assert_equal "(((3^((3d3)^3))d3)^3)", Dice.new("(3^3d3^3)d3^3").to_s

assert_equal 2, Dice.new("1d6*2").min
assert_equal 20, Dice.new("10+1d10").max
assert_equal 5.5, Dice.new("1d10").median
assert_equal 3, Dice.new("1*4-1").sample # 計算機にもなる
assert_equal 1, Dice.new("1d1").sample

assert_equal({1 => true}, Dice.new("1").probability)
assert_equal({1 => true, 2 => true}, Dice.new("1d2").probability)
assert_equal({2 => true, 4 => true}, Dice.new("1d2*2").probability)
assert_equal({2 => true, 3 => true, 4 => true}, Dice.new("1d2+1d2").probability) # = 2d2
assert_equal({-1=> true, 0 => true, 1 => true}, Dice.new("1d2-1d2").probability) # 1-1, 1-2, 2-1, 2-2
assert_equal({1 => true, 2 => true, 4 => true}, Dice.new("1d2*1d2").probability) # 1*1, 1*2, 2*1, 2*2
assert_equal({0 => true, 1 => true, 2 => true}, Dice.new("1d2/1d2").probability) # 1/1, 1/2, 2/1, 2/2  1, 0.5, 2 だが、0方向切り捨てのためこうなる

assert_equal true,  Dice.new(" 0").may_be_zero?
assert_equal false, Dice.new("-1").may_be_zero?
assert_equal false, Dice.new("2-3").may_be_zero?
assert_equal true,  Dice.new("2-1d3").may_be_zero?

assert_equal false, Dice.new(" 0").may_be_negative?
assert_equal true,  Dice.new("-1").may_be_negative?
assert_equal true,  Dice.new("2-3").may_be_negative?
assert_equal true,  Dice.new("2-1d3").may_be_negative?

assert_raise Dice::Parser::LexerError do Dice.new("_") end
assert_raise Dice::Parser::ParseError do Dice.new("1+") end
assert_raise Dice::DivisionByZeroError do Dice.new("1/0") end
assert_raise Dice::DivideZeroFromZeroError do Dice.new("0/0") end
assert_raise Dice::DivisionByZeroError do Dice.new("1/(2-2)") end
assert_raise Dice::DivideZeroFromZeroError do Dice.new("(1*0)/(1/2)") end
assert_raise Dice::DiceFacesIsNegativeError do Dice.new("1d(1-1d2)") end
assert_raise Dice::DiceCountIsNegativeError do Dice.new("(1-1d2)d1") end

assert_time 0.01, "a1" do Dice.new("200d10+200d10").may_be_zero? end
assert_time 0.01, "a2" do Dice.new("200d10-199d10").may_be_zero? end
assert_time 0.01, "a3" do Dice.new("200d10*200d10").may_be_zero? end
assert_time 0.01, "a4" do Dice.new("200d10/200d10").may_be_zero? end
assert_time 0.01, "a5" do Dice.new("30 d10^40 d10").may_be_zero? end
	
assert_time 0.01, "b1" do Dice.new("200d10+200d10").may_be_negative? end
assert_time 0.01, "b2" do Dice.new("200d10-200d10").may_be_negative? end
assert_time 0.01, "b3" do Dice.new("200d10*200d10").may_be_negative? end
assert_time 0.01, "b4" do Dice.new("200d10/200d10").may_be_negative? end
assert_time 0.01, "b5" do Dice.new("30 d10^50 d10").may_be_negative? end
