#!/usr/bin/env ruby

module CommandWithOption
    def port_option
        self.options
    end
end

class  Command
    def self.options

    end
end

class ThirdCommand < Command
    extend CommandWithOption

    options
    port_option
end

class SecondCommand < Command
    extend CommandWithOption

    options
    port_option
end

# first/second/thrid/forth.rb
module First
    module Second
        class Third
            module Forth