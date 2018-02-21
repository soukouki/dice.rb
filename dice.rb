
=begin

Dice.newすることができる文字列

expression := mul_div | mul_div + expression | mul_div - expression
mul_div :=  pow | pow * mul_div | pow / mul_div
pow := dice_int | dice_int ^ dice_int  # 2^2^2は成立しない。(2^2)^2または2^(2^2)と書くように。
dice_int := int_parentheses | int_parentheses d int_parentheses # 同じく2d2d2は成立しない。(2d2)d2または2d(2d2)と書くように
int_parentheses := int | ( expression )

(ただし字句解析で符号付きのintは処理される)

TODO : 最頻値、分布、標準偏差
=end


require "strscan"


module Dice
	module_function
	
	def new str
		Parser.parse(str)
	end
	
	class Dice
		attr_accessor :count, :faces
		
		def initialize count, faces
			@count = count
			@faces = faces
		end
		
		def to_s
			"(#{count}d#{faces})"
		end
		
		def sample
			@count
				.sample
				.times
				.map{|_i|rand(1..@faces.sample)}
				.sum
		end
		def min
			@count.min
		end
		def max
			@count.max*@faces.max
		end
		def median
			(min+max)/2.0
		end
	end
	class Int
		attr_accessor :num
		
		def initialize num
			@num = num
		end
		
		def to_s
			num.to_s
		end
		
		def sample
			@num
		end
		def min
			@num
		end
		def max
			@num
		end
		def median
			@num
		end
	end
	
	class FourArithmeticOperations
		attr_accessor :left, :right
		
		def initialize left, right
			@left = left
			@right = right
		end
		
		def sample
			base(@left.sample, @right.sample)
		end
		def min
			base(@left.min, @right.min)
		end
		def max
			base(@left.max, @right.max)
		end
		def median
			base(@left.median.to_f, @right.median)
		end
	end
	class Add < FourArithmeticOperations
		def to_s
			"(#{left}+#{right})"
		end
		private def base left, right
			left + right
		end
	end
	class Sub < FourArithmeticOperations
		def to_s
			"(#{left}-#{right})"
		end
		private def base left, right
			left - right
		end
	end
	class Mul < FourArithmeticOperations
		def to_s
			"(#{left}*#{right})"
		end
		private def base left, right
			left * right
		end
	end
	class Div < FourArithmeticOperations
		def to_s
			"(#{left}/#{right})"
		end
		private def base left, right
			left / right
		end
	end
	class Pow
		attr_accessor :base, :exponent
		
		def initialize base, exponent
			@base = base
			@exponent = exponent
		end
		
		def to_s
			"(#{base}^#{exponent})"
		end
		
		def sample
			@base.sample ** @exponent.sample
		end
		def min
			@base.min ** @exponent.min
		end
		def max
			@base.max ** @exponent.max
		end
		def median
			@base.median ** @exponent.median
		end
	end
	
	
	class Parser
		attr_writer :tokens
		
		class DiceFormatError < StandardError
			attr_reader :pos
			def initialize pos
				@pos = pos
			end
			def to_s
				"#{@message} pos = #{@pos}"
			end
		end
		class ParseError < DiceFormatError
			def initialize msg, *args
				super *args
				@message = msg
			end
		end
		class LexerError < DiceFormatError
			def initialize *args
				super *args
				@message = "lexer error."
			end
		end
		Token = Struct.new(:symbol, :pos, :data)
		
		def self.parse str
			parcer = Parser.new
			parcer.tokens = lexer(str)
			parcer.parce_syntax()
		end
		
		def parce_syntax
			e = expression()
			unless @tokens.first.symbol == "end"
				raise ParseError.new("tokenが残っています。 #{@tokens.first.symbol}", @tokens.first.pos)
			end
			e
		end
		
		private
		
		def self.lexer str
			s = StringScanner.new(str)
			result = []
			until s.eos?
				case
				when s.scan(/(\+|-|)\d+/)
					result << Token.new("int", s.pos, s[0].to_i)
				when s.scan(/[()+*\/^d-]/)
					result << Token.new(s[0], s.pos, nil)
				when s.scan(/[ 　\t\n]+/)
				else
					raise LexerError.new(s.pos)
				end
			end
			result << Token.new("end", s.pos, nil)
			result
		end
		
		def expression
			unless left = mul_div()
				raise ParseError.new("expressionはmul_divから始まらなければならない。", @tokens.first.pos)
			else
				case @tokens.first.symbol
				when "+"
					@tokens.shift
					unless right = expression()
						raise ParseError.new("+のあとはexpressionでなければならない。", @tokens.first.pos)
					else
						Add.new(left, right)
					end
				when "-"
					@tokens.shift
					unless right = expression()
						raise ParseError.new("-のあとはexpressionでなければならない", @tokens.first.pos)
					else
						Sub.new(left, right)
					end
				else
					left
				end
			end
		end
		
		def mul_div
			unless left = pow()
				raise ParseError.new("mul_divはpowから始まらなければならない。", @tokens.first.pos)
			else
				case @tokens.first.symbol
				when "*"
					@tokens.shift
					unless right = mul_div()
						raise ParseError.new("*のあとはmul_divでなければならない。", @tokens.first.pos)
					else
						Mul.new(left, right)
					end
				when "/"
					@tokens.shift
					unless right = mul_div()
						raise ParseError.new("/のあとはmul_divでなければならない。", @tokens.first.pos)
					else
						Div.new(left, right)
					end
				else
					left
				end
			end
		end
		
		def pow
			unless left = dice_int()
				raise ParseError.new("powはdice_intから始まらなければならない。", @tokens.first.pos)
			else
				if @tokens.first.symbol == "^"
					@tokens.shift
					unless right = dice_int()
						raise ParseError.new(
							"^のあとはdice_intでなければならない。(2^2^2は成立しない。(2^2)^2または2^(2^2)と書くように。)",
							@tokens.first.pos,
						)
					else
						Pow.new(left, right)
					end
				else
					left
				end
			end
		end
		
		def dice_int
			unless left = int_parentheses()
				raise ParseError.new("dice_intはint_parenthesesから始まらなければならない。", @tokens.first.pos)
			else
				if @tokens.first.symbol == "d"
					@tokens.shift
					unless right = int_parentheses()
						raise ParseError.new(
							"dのあとはint_parenthesesでなければならない。(2d2d2は成立しない。(2d2)d2または2d(2d2)と書くように。)",
							@tokens.first.pos,
						)
					else
						Dice.new(left, right)
					end
				else
					left
				end
			end
		end
		
		def int_parentheses
			if @tokens.first.symbol == "int"
				int = @tokens.shift.data
				Int.new(int)
			elsif @tokens.first.symbol == "("
				@tokens.shift
				unless content = expression()
					raise ParseError.new("(のあとはexpressionでなければならない。", @tokens.first.pos)
				else
					unless @tokens.first.symbol == ")"
						raise ParseError.new("(は)が対応していなければならない。", @tokens.first.pos)
					else
						@tokens.shift
						content
					end
				end
			else
				nil # それぞれの場所でエラー対策をしているのでそっちでメッセージを出すように
			end
		end
	end
end
