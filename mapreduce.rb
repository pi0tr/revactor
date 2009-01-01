#! /usr/bin/ruby19

class MapReduce
  attr_reader   :input, :output
  attr_accessor	:map, :reduce
	
  def initialize(map, reduce)
    @map, @reduce = map, reduce
  end

  def run(input)
    raise "Override this method in child classes"
  end
  
end
