class BidirectionalMap

    def initialize(map_to_i=Hash.new, map_to_s=Array.new, count=0)

        @map_to_i = map_to_i
        @map_to_s = map_to_s
        @count = count
    end

    def [](value)

        if !@map_to_i.has_key?(value)
            @map_to_i[value] = @count
            @map_to_s << value
            @count+= 1
        end
        return @map_to_i[value]
    end

    def reverse(number)
        return @map_to_s[number]
    end

    def to_s
        "In BidirectionalMap:\n   #{@map_to_i}, #{@map_to_s}, #{@count}\n"
    end

    def to_json
        {
            "json_class" => self.class.name,
            "data" => {'map_to_i' => @map_to_i,
                       'map_to_s' => @map_to_s,
                       'count' => @count}
        }.to_json
    end

    def to_json(*a)
        {
            "json_class" => self.class.name,
            "data" => {'map_to_i' => @map_to_i,
                       'map_to_s' => @map_to_s,
                       'count' => @count}
        }.to_json(*a)
    end

    def self.json_create(o)
        new(o['data']['map_to_i'], o['data']['map_to_s'], o['data']['count'])
    end
end