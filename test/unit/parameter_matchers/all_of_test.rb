# frozen_string_literal: true

require File.expand_path('../../../test_helper', __FILE__)

require 'mocha/parameter_matchers/all_of'
require 'mocha/inspect'
require 'parameter_matchers/stub_matcher'

class AllOfTest < Mocha::TestCase
  include Mocha::ParameterMatchers

  def test_should_match_if_all_matchers_match
    matcher = all_of(StubMatcher.new(true), StubMatcher.new(true), StubMatcher.new(true))
    assert matcher.matches?(['any_old_value'])
  end

  def test_should_not_match_if_any_matcher_does_not_match
    matcher = all_of(StubMatcher.new(true), StubMatcher.new(false), StubMatcher.new(true))
    assert !matcher.matches?(['any_old_value'])
  end

  def test_should_describe_matcher
    matcher = all_of(StubMatcher.new(true), StubMatcher.new(false), StubMatcher.new(true))
    assert_equal 'all_of(matcher(true), matcher(false), matcher(true))', matcher.mocha_inspect
  end
end
