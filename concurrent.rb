#! /usr/bin/ruby19

require 'revactor'
require 'mapreduce'

class Concurrent < MapReduce
  def run(input)
    @input = input
    current = Actor.current
    Actor.spawn { do_reduce(current) }
    Actor.receive do |filter|
      filter.when(T[current, Object]) {|_, obj| @output = obj}
    end
  end

  #######
  private
  #######
  def do_reduce(parent)
    reduce_actor = Actor.current
    reduce_actor.trap_exit = true
    @input.each do |element|
      Actor.spawn_link { @map.call(reduce_actor, element) }
    end
    dictionary = collect_partials
    result = {}
    dictionary.each do |key, value|
      result[key] = @reduce.call(key, value)[1]
    end
    parent << [parent, result]
  end
  
  def collect_partials
    n = @input.size
    dictionary = {}
    while n > 0
      Actor.receive do |filter|
        filter.when(Case[:exit, Actor, Object]) { n -= 1 }
        filter.when(T[String, Fixnum]) do |key, value|
          dictionary[key] ||= []
          dictionary[key] << value
        end
      end
    end
    dictionary
  end
end

