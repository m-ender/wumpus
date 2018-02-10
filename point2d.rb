# coding: utf-8

class Point2D
    attr_accessor :x, :y

    def initialize(x, y)
        @x = x
        @y = y
    end

    def self.from_string(string)
        coords = string.split.map(&:to_i)
        Point2D.new(coords[0], coords[1])
    end

    def +(other)
        if other.is_a?(Point2D)
            return Point2D.new(@x+other.x, @y+other.y)
        end
    end

    # Indicates whether the triangle at this coordinate points upwards
    def up?
        (@x + @y) % 2 == 0
    end

    def coerce(other)
        return self, other
    end

    def to_s
        "(%d,%d) %s" % [@x, @y, up? ? '/\\' : '\/']
    end

    def inspect
        "(%d,%d)" % [@x, @y]
    end
end