# frozen_string_literal: true

module Mocha
  class SingleReturnValue
    def initialize(value)
      @value = value
    end

    def evaluate(invocation)
      invocation.returned(@value)
      @value
    end
  end
end
