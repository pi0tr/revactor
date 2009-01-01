#! /usr/bin/ruby19

resources = []
ObjectSpace.each_object(Class) do |klass|
  resources << "http://www.ruby-doc.org/core-1.9/classes/#{klass.name.gsub('::','/')}.html"
end

require 'concurrent'
require 'sequential'
require 'benchmark'
require 'cgi'
require 'uri'

include Benchmark

class WordCount
  def initialize(method)
    @method = method
  end
  
  def run(input)
    @method.run(input)
  end
	
  def output
    @method.output
  end

  def self.each_word(uri)
    words = []
    uri = URI.parse(uri)
		
    sock = Revactor::TCP.connect(uri.host, 80)
    sock.write [ "GET #{uri.path} HTTP/1.0", "Host: #{CGI.escape(uri.host)}",
                            "\r\n" ].join("\r\n")
    begin 
      loop do 
        sock.read.scan(/[a-z]+/i) {|w| yield w}
      end
    rescue EOFError
    end
  end
end

if $0 == __FILE__
  resources = resources[0...(ARGV[0].to_i)]
  map = -> target, uri do
    WordCount.each_word(uri) {|w| target << T[w, 1]}
  end
  reduce = -> key, values { T[key, values.size] }

  test_seq = WordCount.new(Sequential.new(map, reduce))
  test_actor = WordCount.new(Concurrent.new(map, reduce))
  Benchmark.bm(12) do |b|
    b.report("sequential") { test_seq.run(resources) }
    b.report("#{resources.size} actors") { test_actor.run(resources) }
  end

  %w(test_seq test_actor).each do |t|
    File.open(t, "w") do |f|
      f.puts eval(t).output
    end
  end
end
