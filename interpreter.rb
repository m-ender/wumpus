# coding: utf-8

require_relative 'point2d'
require_relative 'direction'
require_relative 'icosahedron'

class Interpreter
    class ProgramError < Exception; end


    OPERATORS = {
        ' '  => :nop,

        '`'  => :debug,
        '@'  => :terminate,

        '"'  => :string_mode,

        '/'  => :mirror_sw_ne,
        '\\' => :mirror_nw_se,
        '_'  => :mirror_w_e,
        '|'  => :mirror_n_s,
        ','  => :strafe,
        '&'  => :iterate,
        '$'  => :skip,
        '?'  => :conditional_skip,
        '.'  => :jump,
        '{'  => :turn_left,
        '}'  => :turn_right,
        '^'  => :conditional_turn,

        '#'  => :push_zero,
        '0'  => :digit, '1'  => :digit, '2'  => :digit, '3'  => :digit, '4'  => :digit, '5'  => :digit, '6'  => :digit, '7'  => :digit, '8'  => :digit, '9'  => :digit,
        '!'  => :not,
        '\'' => :neg,
        '+'  => :add,
        '-'  => :sub,
        '*'  => :mul,
        ':'  => :div,
        '%'  => :mod,
        '('  => :dec,
        ')'  => :inc,
        'a'  => :bit_and,
        'n'  => :bit_not,
        'v'  => :bit_or,
        'x'  => :bit_xor,

        ';'  => :discard,
        '='  => :duplicate,
        '~'  => :swap,
        'l'  => :stack_depth,
        'r'  => :reverse_stack,
        '['  => :rotate_left,
        ']'  => :rotate_right,

        'A'  => :ico_rot_edge_nw,
        'B'  => :ico_rot_edge_ne,
        'C'  => :ico_rot_edge_s,
        'P'  => :ico_rot_edge_nw_n,
        'Q'  => :ico_rot_edge_ne_se,
        'R'  => :ico_rot_edge_s_sw,
        'V'  => :ico_rot_flip,
        'W'  => :ico_rot_face,
        'X'  => :ico_rot_corner_n,
        'Y'  => :ico_rot_corner_se,
        'Z'  => :ico_rot_corner_sw,
        'D'  => :ico_roll,
        'T'  => :ico_conditional_rot,
        'U'  => :ico_random_rot,
        'F'  => :ico_get_face,

        'S'  => :ico_store,
        'L'  => :ico_load,

        'g'  => :ico_get,
        's'  => :ico_set,
        'e'  => :ico_end,
        '<'  => :move_ico_w,
        '>'  => :move_ico_e,
        'b'  => :move_ico_nw,
        'd'  => :move_ico_ne,
        'p'  => :move_ico_sw,
        'q'  => :move_ico_se,
        'G'  => :rotate_cells,

        'I'  => :input_int,
        'O'  => :output_int,
        'i'  => :input_char,
        'o'  => :output_char,
        'N'  => :output_lf,
    }

    def self.run(src, debug_level=0, in_str=$stdin, out_str=$stdout, max_ticks=-1)
        new(src, debug_level, in_str, out_str, max_ticks).run
    end

    def initialize(src, debug_level=false, in_str=$stdin, out_str=$stdout, max_ticks=-1)
        @debug_level = debug_level
        @in_str = in_str
        @out_str = out_str
        @out_str.binmode # Put the output stream in binary mode so that
                         # we can write non-UTF-8 bytes.

        @max_ticks = max_ticks

        @grid = parse(src)
        @height = @grid.size
        @width = @height == 0 ? 0 : @grid[0].size

        @ip = Point2D.new(0, 0)
        @dir = East.new
        @strafe = false
        @jump_target = nil
        @iterate = 1
        @string_mode = false

        @stack = []
        @ico = Icosahedron.new

        @ico_mode = :none
        @ico_pos = Point2D.new(0, 0)

        @tick = 0
    end

    def run
        loop do
            break if @max_ticks > -1 && @tick >= @max_ticks

            print_debug_info if @debug_level > 1

            if @string_mode
                val = cell @ip
                if val == '"'.ord
                    @string_mode = false
                else
                    push val
                end
            else
                val = cell @ip
                cmd = is_char?(val) ? OPERATORS[val.chr] : :nop
                iter = @iterate
                @iterate = 1
                if iter > 0 && cmd == :terminate
                    break
                end
                iter.times { process cmd, val }
            end
            
            move

            @tick += 1
        end

        @max_ticks > -1 && @tick >= @max_ticks
    end

    def print_debug_info
        $stderr.puts
        $stderr.puts "Tick: #{@tick}"
        $stderr.puts "Grid:"
        $stderr.puts ' '*@ip.x + 'v'
        @grid.each_with_index {|l, i| 
            l.each{|c| $stderr << (is_char?(c) ? c.chr : ' ') }
            $stderr << ' <' if i == @ip.y
            $stderr.puts
        }
        $stderr.puts "IP: #{@ip}"
        $stderr.puts "Direction: #{@dir}"
        $stderr.puts
        $stderr.puts "Stack: #{@stack.inspect}"
        $stderr.puts "Icosahedron:"
        $stderr.puts @ico
        $stderr.puts
        $stderr.puts "Position: #{@ico_mode == :none ? 'n/a' : @ico_pos.to_s + ' ' + @ico_mode.to_s}"
        $stderr.puts
        # print memory state here
    end

    private

    def parse(src)
        lines = src.split($/)

        grid = lines.map{|l| l.chars.map(&:ord)}

        width = grid.map(&:size).max

        grid.each{|l| l.fill(0, l.length...width)}
    end

    # Check whether a point is out of bounds
    def oob? coords
        coords.x < 0 || coords.y < 0 || coords.x >= @width || coords.y >= @height
    end

    # Check whether a given integer is a valid ASCII code point
    def is_char? val
        val && (val >= 0 && val <= 0x7F)
    end

    def x
        @ip.x
    end

    def y
        @ip.y
    end

    def cell coords
        oob?(coords) ? 0 : @grid[coords.y][coords.x]
    end

    def push val
        @stack << val
    end

    def pop
        @stack.pop || 0
    end

    def peek
        @stack[-1] || 0
    end

    def move
        if @jump_target
            @ip = @jump_target
            @jump_target = nil
        else
            if @strafe
                @strafe = false
                new_ip = @dir.strafe @ip

                if !oob? new_ip
                    @ip = new_ip
                    return
                end
            end

            new_ip = @dir.step @ip

            while oob? new_ip
                @dir = @dir.reflect_boundary @ip
                new_ip = @dir.step @ip
            end

            @ip = new_ip
        end
    end

    def process cmd, cellVal
        case cmd
        # Control flow
        when :mirror_n_s
            @dir = @dir.reflect_n_s
        when :mirror_w_e
            @dir = @dir.reflect_w_e
        when :mirror_nw_se
            @dir = @dir.reflect_nw_se
        when :mirror_sw_ne
            @dir = @dir.reflect_sw_ne
        when :strafe
            @strafe = !@strafe
        when :skip
            @iterate = 0
        when :conditional_skip
            val = pop
            @iterate = 0 if val == 0
        when :iterate
            @iterate = [pop, 0].max
        when :jump
            y = pop % @height
            x = pop % @width
            @jump_target = Point2D.new(x, y)
        when :turn_left
            @dir = @dir.left
        when :turn_right
            @dir = @dir.right
        when :conditional_turn
            @dir = (pop <= 0) ? @dir.left : @dir.right

        # Arithmetic
        when :push_zero
            push 0
        when :digit
            val = pop
            if val < 0
                push(val*10 - cellVal-48) # 48 == '0'.ord
            else
                push(val*10 + cellVal-48) # 48 == '0'.ord
            end
        when :inc
            push(pop+1)
        when :dec
            push(pop-1)
        when :not
            push(pop == 0 ? 1 : 0)
        when :neg
            push(-pop)
        when :add
            push(pop+pop)
        when :sub
            a = pop
            b = pop
            push(b-a)
        when :mul
            push(pop*pop)
        when :div
            a = pop
            b = pop
            push(b/a)
        when :mod
            a = pop
            b = pop
            push(b%a)
        when :bit_and
            push(pop & pop)
        when :bit_or
            push(pop | pop)
        when :bit_xor
            push(pop ^ pop)
        when :bit_bot
            push(~pop)

        # Stack manipulation
        when :discard
            pop
        when :duplicate
            a = pop
            push a
            push a
        when :swap
            a = pop
            b = pop
            push a
            push b
        when :stack_depth
            push @stack.size
        when :reverse_stack
            @stack.reverse!
        when :rotate_left
            val = @stack.shift
            push val if val
        when :rotate_right
            val = pop
            @stack.unshift(val) if val

        # Icosahedron manipulation
        when :ico_rot_edge_nw
            @ico.rot_edge_nw!
            ico_getset
        when :ico_rot_edge_ne
            @ico.rot_edge_ne!
            ico_getset
        when :ico_rot_edge_s
            @ico.rot_edge_s!
            ico_getset
        when :ico_rot_edge_nw_n
            @ico.rot_edge_nw_n!
            ico_getset
        when :ico_rot_edge_ne_se
            @ico.rot_edge_ne_se!
            ico_getset
        when :ico_rot_edge_s_sw
            @ico.rot_edge_s_sw!
            ico_getset
        when :ico_rot_corner_n
            @ico.rot_corner_n!
            ico_getset
        when :ico_rot_corner_se
            @ico.rot_corner_se!
            ico_getset
        when :ico_rot_corner_sw
            @ico.rot_corner_sw!
            ico_getset
        when :ico_rot_face
            @ico.rot_face!
            ico_getset
        when :ico_rot_flip
            @ico.rot_flip!
            ico_getset
        when :ico_roll
            rand(5).times{ @ico.rot_corner_n! }
            rand(3).times{ @ico.rot_face! }
            rand(2).times{ @ico.rot_edge_nw_n! }
            rand(2).times{ @ico.rot_edge_ne_se! }
            ico_getset
        when :ico_conditional_rot
            val = pop
            if val < 0
                @ico.rot_edge_nw!
            elsif val == 0
                @ico.rot_edge_s!
            else
                @ico.rot_edge_ne!
            end
            ico_getset
        when :ico_random_rot
            val = rand(3)
            case val
            when 0 then @ico.rot_edge_nw!
            when 1 then @ico.rot_edge_s!
            when 2 then @ico.rot_edge_ne!
            end
            ico_getset
        when :ico_get_face
            push @ico.active_face

        when :ico_store
            @ico.store pop
            ico_getset
        when :ico_load
            push @ico.load


        # Grid manipulation
        when :ico_get
            y = pop % @height
            x = pop % @width

            @ico_mode = :get
            @ico_pos = Point2D.new(x, y)

            ico_getset
        when :ico_set
            y = pop % @height
            x = pop % @width

            @ico_mode = :set
            @ico_pos = Point2D.new(x, y)

            ico_getset
        when :ico_end
            @ico_mode = :none
        when :move_ico_w
            return if @ico_mode == :none
            new_pos = West.new.step @ico_pos
            return if oob? new_pos
            @ico_pos.up? ? @ico.rot_edge_nw! : @ico.rot_edge_ne!
            @ico_pos = new_pos
            ico_getset
        when :move_ico_e
            return if @ico_mode == :none
            new_pos = East.new.step @ico_pos
            return if oob? new_pos
            @ico_pos.up? ? @ico.rot_edge_ne! : @ico.rot_edge_nw!
            @ico_pos = new_pos
            ico_getset
        when :move_ico_nw
            return if @ico_mode == :none
            new_pos = NorthWest.new.step @ico_pos
            return if oob? new_pos
            @ico_pos.up? ? @ico.rot_edge_nw! : @ico.rot_edge_s!
            @ico_pos = new_pos
            ico_getset
        when :move_ico_ne
            return if @ico_mode == :none
            new_pos = NorthEast.new.step @ico_pos
            return if oob? new_pos
            @ico_pos.up? ? @ico.rot_edge_ne! : @ico.rot_edge_s!
            @ico_pos = new_pos
            ico_getset
        when :move_ico_sw
            return if @ico_mode == :none
            new_pos = SouthWest.new.step @ico_pos
            return if oob? new_pos
            @ico_pos.up? ? @ico.rot_edge_s! : @ico.rot_edge_ne!
            @ico_pos = new_pos
            ico_getset
        when :move_ico_se
            return if @ico_mode == :none
            new_pos = SouthEast.new.step @ico_pos
            return if oob? new_pos
            @ico_pos.up? ? @ico.rot_edge_s! : @ico.rot_edge_nw!
            @ico_pos = new_pos
            ico_getset
        when :rotate_cells
            y = pop
            x = 2*pop + (y%2)
            n = pop % 6

            return if y < 0 || y >= @height-1 || x < 0 || x >= @width-2

            n.times do
                temp = cell Point2D.new(x, y)
                @grid[y][x] = cell Point2D.new(x+1, y)
                @grid[y][x+1] = cell Point2D.new(x+2, y)
                @grid[y][x+2] = cell Point2D.new(x+2, y+1)
                @grid[y+1][x+2] = cell Point2D.new(x+1, y+1)
                @grid[y+1][x+1] = cell Point2D.new(x, y+1)
                @grid[y+1][x] = temp
            end

            ico_getset

        # I/O
        when :input_char
            byte = read_byte
            push(byte ? byte.ord : -1)
        when :output_char
            @out_str.print (pop % 256).chr
        when :input_int
            val = 0
            sign = 1
            loop do
                byte = read_byte
                case byte
                when '+'
                    sign = 1
                when '-'
                    sign = -1
                when '0'..'9', nil
                    @next_byte = byte
                else
                    next
                end
                break
            end

            loop do
                byte = read_byte
                if byte && byte[/\d/]
                    val = val*10 + byte.to_i
                else
                    @next_byte = byte
                    break
                end
            end

            push(sign*val)
        when :output_int
            @out_str.print pop
        when :output_lf
            @out_str.puts

        # Miscellaneous
        when :string_mode
            @string_mode = !@string_mode
        when :terminate
            raise '[BUG] Received :terminate. This shouldn\'t happen.'
        when :nop
            # Nop(e)
        when :debug
            print_debug_info
        end
    end

    def ico_getset
        case @ico_mode
        when :get
            @ico.store(cell @ico_pos)
        when :set
            @grid[@ico_pos.y][@ico_pos.x] = @ico.load
        end
    end

    def read_byte
        result = nil
        if @next_byte
            result = @next_byte
            @next_byte = nil
        else
            result = @in_str.read(1)
        end
        result
    end
end