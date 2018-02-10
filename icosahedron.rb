# coding: utf-8

class Icosahedron
    attr_accessor :faces

    def initialize()
        @faces = [0]*20
        @indices = (1..20).to_a
    end

    def store val
        @faces[@indices[0]-1] = val
    end

    def load
        @faces[@indices[0]-1]
    end

    def active_face
        @indices[0]
    end

    def permute p
        @indices = p.map{|i| @indices[i] }
    end

    def rot_edge_nw!()    permute [1, 0, 7, 8, 9, 10, 11, 2, 3, 4, 5, 6, 16, 17, 18, 19, 12, 13, 14, 15] end    # Tip onto northwestern face, then rotate 180°.
    def rot_edge_ne!()    permute [4, 5, 6, 7, 0, 1, 2, 3, 13, 14, 15, 16, 17, 8, 9, 10, 11, 12, 19, 18] end    # Tip onto northeastern face, then rotate 180°.
    def rot_edge_s!()     permute [7, 6, 16, 17, 8, 9, 1, 0, 4, 5, 14, 15, 19, 18, 10, 11, 2, 3, 13, 12] end    # Tip onto southern face, then rotate 180°.

    def rot_edge_nw_n!()  permute [11, 2, 1, 9, 10, 18, 19, 12, 13, 3, 4, 0, 7, 8, 17, 16, 15, 14, 5, 6] end    # Tip onto northwestern face, tip onto northern edge, rotate 180°, undo tippings.
    def rot_edge_ne_se!() permute [14, 15, 16, 6, 5, 4, 3, 13, 12, 19, 18, 17, 8, 7, 0, 1, 2, 11, 10, 9] end    # Tip onto northeastern face, tip onto southeastern edge, rotate 180°, undo tippings.
    def rot_edge_s_sw!()  permute [17, 16, 15, 19, 18, 10, 9, 8, 7, 6, 5, 14, 13, 12, 11, 2, 1, 0, 4, 3] end    # Tip onto southern face, tip onto southwestern edge, rotate 180°, undo tippings.

    def rot_corner_n!()   permute [1, 2, 3, 4, 0, 7, 8, 9, 10, 11, 12, 13, 14, 5, 6, 16, 17, 18, 19, 15] end    # Tip onto northern corner, rotate by one face (72°) counterclockwise, then tip back.
    def rot_corner_se!()  permute [4, 3, 13, 14, 5, 6, 7, 0, 1, 2, 11, 12, 19, 15, 16, 17, 8, 9, 10, 18] end    # Tip onto southeastern corner, rotate by one face (72°) counterclockwise, then tip back.
    def rot_corner_sw!()  permute [7, 0, 4, 5, 6, 16, 17, 8, 9, 1, 2, 3, 13, 14, 15, 19, 18, 10, 11, 12] end    # Tip onto southwestern corner, rotate by one face (72°) counterclockwise, then tip back.

    def rot_face!()       permute [0, 4, 5, 6, 7, 8, 9, 1, 2, 3, 13, 14, 15, 16, 17, 18, 10, 11, 12, 19] end    # Rotate 120° counterclockwise.

    def rot_flip!()       permute [19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0] end    # 180° rotation about the west-east axis (swapping 1 and 20).

    def to_s
        nets = <<~END
                                 ______                 ______
                               /|      /|            /|      /|
                              /  | 13 /  |          /  | 02 /  |
                             / 14 |  / 12 |        / 03 |  />01<|
                            /______|/______|      /______|/______|
                            |      /|             |      /|
                             | 04 /  |             | 04 /  |
                              |  / 03 |             |  / 05 |
                         ______|/______|             |/______| ______  ______  ______  ______
               /|      /|      /|      /              |      /|      /|      /|      /|      /|
              /  |    /  | 05 /  | 02 /                | 06 /  | 08 /  | 10 /  | 12 /  | 14 /  |
             / 15 |  / 06 |  />01<|  /                  |  / 07 |  / 09 |  / 11 |  / 13 |  / 15 |
            /______|/______|/______|/______              |/______|/______|/______|/______|/______|
            |      /|      /|      /|      /|                                             |      /|
             | 16 /  | 07 /  | 08 /  | 10 /  |                                             | 16 /  |
              |  / 17 |  /    |  / 09 |  / 11 |                                             |  / 17 |
               |/______|/      |/______|/______|                                       ______|/______|
                                       /|      /|                                     |      /|      /
                                      /  | 19 /  |                                     | 20 /  | 18 /
                                     / 18 |  / 20 |                                     |  / 19 |  /
                                    /______|/______|                                     |/______|/
        END
        nets.tr!('|', '\\').gsub!(/\d{2}/) {|m| "%02d" % @indices[m.to_i-1]}

        nets << "\nFace:  |"
        @faces.each_with_index {|f, i| nets << (" %02d " % (i+1)) << ' '*[f.to_s.size-2, 0].max << '|' }
        nets << "\nValue: |"
        @faces.each_with_index {|f, i| nets << (" %-2d |" % f) }
        nets
    end
end