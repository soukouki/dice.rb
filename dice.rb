

require "strscan"


module Dice
	module_function
	
	PROBABILITY_CACHE = {}
	MAY_BE_NEGATIVE_CACHE = {}
	MAY_BE_ZERO_CACHE = {}
	
	class DiceRuntimeError < RuntimeError
	end
	
	class MathematicalError < DiceRuntimeError
	end
	
	class DivideZeroFromZeroError < MathematicalError
		def to_s
			<<~EOS
				Divide zero from zero may occur.
				ゼロのゼロ除算が発生する可能性があります。
			EOS
		end
	end
	class DivisionByZeroError < MathematicalError
		def to_s
			<<~EOS
				Division by zero may occur.
				ゼロ除算が発生する可能性があります。
			EOS
		end
	end
	class DiceCountIsNegativeError < MathematicalError
		def to_s
			<<~EOS
				There is a possibility that the number of times you roll the dice becomes a negative number.
				ダイズを振る回数が負の数になる可能性があります。
			EOS
		end
	end
	class DiceFacesIsNegativeError < MathematicalError
		def to_s
			<<~EOS
				There is a possibility that the number of dice faces becomes a negative number.
				ダイズの面数が負の数になる可能性があります。
			EOS
		end
	end
	
	def new str
		Parser.parse(str)
	end
	
	class Dice
		attr_accessor :count, :faces
		
		def initialize count, faces
			raise DiceCountIsNegativeError if count.may_be_negative?
			raise DiceFacesIsNegativeError if faces.may_be_negative?
			@count = count
			@faces = faces
		end
		
		def to_s
			"(#{count}d#{faces})"
		end
		
		def probability
			PROBABILITY_CACHE[to_s] ||= (min..max).map{|n|[n, true]}.to_h
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
		
		def may_be_zero?
			count == 0 || faces == 0
		end
		def may_be_negative?
			false
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
		
		def probability
			{@num => true}
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
		
		def may_be_zero?
			@num.zero?
		end
		def may_be_negative?
			@num.negative?
		end
	end
	
	class BinomialOperation
		attr_reader :left, :right
		
		def initialize left, right
			@left = left
			@right = right
		end
		
		def probability
			PROBABILITY_CACHE[to_s] ||= (
				result = {}
				_count = 0
				left.probability.each do |l, _|
					right.probability.each do |r, _|
						result[base(l, r)] = true
						_count += 1
					end
				end
				puts "probability loop count : #{_count}"
				result
			)
		end
		
		def sample
			base(left.sample, right.sample)
		end
		def min
			base(left.min, right.min)
		end
		def max
			base(left.max, right.max)
		end
		def median
			base(left.median.to_f, right.median)
		end
		
		def may_be_zero?
			MAY_BE_ZERO_CACHE[to_s] ||= probability[0] || false
		end
		def may_be_negative?
			MAY_BE_NEGATIVE_CACHE[to_s] ||= probability.keys.any?(&:negative?)
		end
	end
	class Add < BinomialOperation
		def to_s
			"(#{left}+#{right})"
		end
		private def base left, right
			left + right
		end
		
		def may_be_zero?
			if @left.min > 0 && @right.min > 0
				false
			else
				super
			end
		end
		def may_be_negative?
			if not @left.may_be_negative? || @right.may_be_negative?
				false
			else
				super
			end
		end
	end
	class Sub < BinomialOperation
		def to_s
			"(#{left}-#{right})"
		end
		private def base left, right
			left - right
		end
	end
	class Mul < BinomialOperation
		def to_s
			"(#{left}*#{right})"
		end
		private def base left, right
			left * right
		end
		
		def may_be_zero?
			if not @left.may_be_zero? || @right.may_be_zero?
				false
			else
				super
			end
		end
		def may_be_negative?
			if not @left.may_be_negative? || @right.may_be_negative?
				false
			else
				super
			end
		end
	end
	class Div < BinomialOperation
		def initialize left, right
			raise DivideZeroFromZeroError if left.may_be_zero? && right.may_be_zero?
			raise DivisionByZeroError if right.may_be_zero?
			super
		end
		def to_s
			"(#{left}/#{right})"
		end
		private def base left, right
			left / right
		end
		
		def may_be_negative?
			if not @left.may_be_negative? || @right.may_be_negative?
				false
			else
				super
			end
		end
	end
	class Pow < BinomialOperation
		attr_reader :base_num, :exponent
		alias left base_num
		alias right exponent
		
		def initialize base_num, exponent
			@base_num = base_num
			@exponent = exponent
		end
		
		def to_s
			"(#{base_num}^#{exponent})"
		end
		def base base_num, exponent
			base_num ** exponent
		end
		
		def may_be_zero?
			if not base_num.may_be_zero? || exponent.may_be_zero?
				false
			else
				super
			end
		end
	end
	
	
	class Parser
		attr_writer :tokens
		
		class DiceFormatError < DiceRuntimeError
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
				when s.scan(/\d+/)
					result << Token.new("int_l", s.pos, s[0].to_i)
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
				loop {
					case @tokens.first.symbol
					when "+"
						@tokens.shift
						unless right = mul_div()
							raise ParseError.new("+のあとはexpressionでなければならない。", @tokens.first.pos)
						else
							left = Add.new(left, right)
						end
					when "-"
						@tokens.shift
						unless right = mul_div()
							raise ParseError.new("-のあとはexpressionでなければならない", @tokens.first.pos)
						else
							left = Sub.new(left, right)
						end
					else
						break left
					end
				}
			end
		end
		
		def mul_div
			unless left = pow()
				raise ParseError.new("mul_divはpowから始まらなければならない。", @tokens.first.pos)
			else
				loop {
					case @tokens.first.symbol
					when "*"
						@tokens.shift
						unless right = pow()
							raise ParseError.new("*のあとはmul_divでなければならない。", @tokens.first.pos)
						else
							left = Mul.new(left, right)
						end
					when "/"
						@tokens.shift
						unless right = pow()
							raise ParseError.new("/のあとはmul_divでなければならない。", @tokens.first.pos)
						else
							left = Div.new(left, right)
						end
					else
						break left
					end
				}
			end
		end
		
		def pow
			unless left = dice_int()
				raise ParseError.new("powはdice_intから始まらなければならない。", @tokens.first.pos)
			else
				if @tokens.first.symbol == "^"
					@tokens.shift
					unless right = pow()
						raise ParseError.new(
							"^の後にpowがなければならない",
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
			if int = int_l
				int
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
		
		def int_l
			case @tokens.first.symbol
			when "int_l"
				int = @tokens.shift
				Int.new(int.data)
			when "+"
				unless @tokens[1].symbol == "int_l"
					# それぞれのエラー処理に任せる
				else
					_plas, int = @tokens.shift(2)
					Int.new(int.data)
				end
			when "-"
				unless @tokens[1].symbol == "int_l"
					# それぞれのエラー処理に任せる
				else
					_negative, int = @tokens.shift(2)
					Int.new(-int.data)
				end
			else
				# それぞれのエラー処理に任せる
			end
		end
	end
end
