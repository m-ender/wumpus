# coding: utf-8

require_relative 'point2d'

class NorthEast
    def right() East.new end
    def left() NorthWest.new end

    def reflect_sw_ne() NorthEast.new end
    def reflect_nw_se() West.new end
    def reflect_w_e() SouthEast.new end
    def reflect_n_s() NorthWest.new end
    def reflect_boundary(pos) (pos.up? ? West.new : SouthEast.new) end
    
    def reverse() SouthWest.new end
    def vec() Point2D.new(1,-1) end

    def step from
        from + (from.up? ? Point2D.new(1, 0) : Point2D.new(0, -1))
    end
    def strafe from
        from + (from.up? ? Point2D.new(-1, 0) : Point2D.new(1, 0))
    end

    def ==(other) other.is_a?(NorthEast) end
    def coerce(other) return self, other end

    def to_s() "North East" end
end

class NorthWest
    def right() NorthEast.new end
    def left() West.new end

    def reflect_sw_ne() East.new end
    def reflect_nw_se() NorthWest.new end
    def reflect_w_e() SouthWest.new end
    def reflect_n_s() NorthEast.new end
    def reflect_boundary(pos) (pos.up? ? East.new : SouthWest.new) end
    
    def reverse() SouthEast.new end
    def vec() Point2D.new(-1,-1) end

    def step from
        from + (from.up? ? Point2D.new(-1, 0) : Point2D.new(0, -1))
    end
    def strafe from
        from + (from.up? ? Point2D.new(1, 0) : Point2D.new(-1, 0))
    end

    def ==(other) other.is_a?(NorthWest) end
    def coerce(other) return self, other end

    def to_s() "North West" end
end

class West
    def right() NorthWest.new end
    def left() SouthWest.new end

    def reflect_sw_ne() SouthEast.new end
    def reflect_nw_se() NorthEast.new end
    def reflect_w_e() West.new end
    def reflect_n_s() East.new end
    def reflect_boundary(pos) (pos.up? ? SouthEast.new : NorthEast.new) end
    
    def reverse() East.new end
    def vec() Point2D.new(-1,0) end

    def step(from) from + Point2D.new(-1, 0) end
    def strafe from
        from + (from.up? ? Point2D.new(0, 1) : Point2D.new(0, -1))
    end

    def ==(other) other.is_a?(West) end
    def coerce(other) return self, other end

    def to_s() "West" end
end

class SouthWest
    def right() West.new end
    def left() SouthEast.new end

    def reflect_sw_ne() SouthWest.new end
    def reflect_nw_se() East.new end
    def reflect_w_e() NorthWest.new end
    def reflect_n_s() SouthEast.new end
    def reflect_boundary(pos) (pos.up? ? NorthWest.new : East.new) end
    
    def reverse() NorthEast.new end
    def vec() Point2D.new(-1,1) end

    def step from
        from + (from.up? ? Point2D.new(0, 1) : Point2D.new(-1, 0))
    end
    def strafe from
        from + (from.up? ? Point2D.new(-1, 0) : Point2D.new(1, 0))
    end

    def ==(other) other.is_a?(SouthWest) end
    def coerce(other) return self, other end

    def to_s() "South West" end
end

class SouthEast
    def right() SouthWest.new end
    def left() East.new end

    def reflect_sw_ne() West.new end
    def reflect_nw_se() SouthEast.new end
    def reflect_w_e() NorthEast.new end
    def reflect_n_s() SouthWest.new end
    def reflect_boundary(pos) (pos.up? ? NorthEast.new : West.new) end
    
    def reverse() NorthWest.new end
    def vec() Point2D.new(1,1) end

    def step from
        from + (from.up? ? Point2D.new(0, 1) : Point2D.new(1, 0))
    end
    def strafe from
        from + (from.up? ? Point2D.new(1, 0) : Point2D.new(-1, 0))
    end

    def ==(other) other.is_a?(SouthEast) end
    def coerce(other) return self, other end

    def to_s() "South East" end
end

class East
    def right() SouthEast.new end
    def left() NorthEast.new end

    def reflect_sw_ne() NorthWest.new end
    def reflect_nw_se() SouthWest.new end
    def reflect_w_e() East.new end
    def reflect_n_s() West.new end
    def reflect_boundary(pos) (pos.up? ? SouthWest.new : NorthWest.new) end
    
    def reverse() West.new end
    def vec() Point2D.new(1,0) end

    def step(from) from + Point2D.new(1, 0) end
    def strafe from
        from + (from.up? ? Point2D.new(0, 1) : Point2D.new(0, -1))
    end

    def ==(other) other.is_a?(East) end
    def coerce(other) return self, other end

    def to_s() "East" end
end