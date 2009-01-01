#! /usr/bin/ruby19

class Sequential < MapReduce
  def run(input)
    @input = input
    dictionary = {}
    @input.each do |element|
      partial = []
      @map.call(partial, element)
      partial.each do |key, value| 
        dictionary[key] ||= []
        dictionary[key] << value
      end
    end
    result = {}
    dictionary.each do |key, value|
      result[key] = @reduce.call(key, value)[1]
    end
    @output = result
  end
end

