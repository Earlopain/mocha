# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)
require 'mocha/expectation'
require 'mocha/invocation'
require 'mocha/sequence'
require 'execution_point'
require 'simple_counter'

class ExpectationTest < Mocha::TestCase
  include Mocha

  def new_expectation
    Expectation.new(nil, :expected_method)
  end

  def invoke(expectation, &block)
    expectation.invoke(Invocation.new(:irrelevant, :expected_method, [], block))
  end

  def test_should_match_calls_to_same_method_with_any_parameters
    assert new_expectation.match?(Invocation.new(:irrelevant, :expected_method, [1, 2, 3]))
  end

  def test_should_match_calls_to_same_method_with_exactly_zero_parameters
    assert new_expectation.with.match?(Invocation.new(:irrelevant, :expected_method))
  end

  def test_should_not_match_calls_to_same_method_with_more_than_zero_parameters
    assert !new_expectation.with.match?(Invocation.new(:irrelevant, :expected_method, [1, 2, 3]))
  end

  def test_should_match_calls_to_same_method_with_expected_parameter_values
    assert new_expectation.with(1, 2, 3).match?(Invocation.new(:irrelevant, :expected_method, [1, 2, 3]))
  end

  def test_should_match_calls_to_same_method_with_parameters_constrained_as_expected
    expectation = new_expectation.with { |x, y, z| x + y == z }
    assert expectation.match?(Invocation.new(:irrelevant, :expected_method, [1, 2, 3]))
  end

  def test_should_not_match_calls_to_different_method_with_parameters_constrained_as_expected
    expectation = new_expectation.with { |x, y, z| x + y == z }
    assert !expectation.match?(Invocation.new(:irrelevant, :different_method, [1, 2, 3]))
  end

  def test_should_not_match_calls_to_different_methods_with_no_parameters
    assert !new_expectation.match?(Invocation.new(:irrelevant, :unexpected_method))
  end

  def test_should_not_match_calls_to_same_method_with_too_few_parameters
    assert !new_expectation.with(1, 2, 3).match?(Invocation.new(:irrelevant, :expected_method, [1, 2]))
  end

  def test_should_not_match_calls_to_same_method_with_too_many_parameters
    assert !new_expectation.with(1, 2).match?(Invocation.new(:irrelevant, :expected_method, [1, 2, 3]))
  end

  def test_should_not_match_calls_to_same_method_with_unexpected_parameter_values
    assert !new_expectation.with(1, 2, 3).match?(Invocation.new(:irrelevant, :expected_method, [1, 0, 3]))
  end

  def test_should_not_match_calls_to_same_method_with_parameters_not_constrained_as_expected
    expectation = new_expectation.with { |x, y, z| x + y == z }
    assert !expectation.match?(Invocation.new(:irrelevant, :expected_method, [1, 0, 3]))
  end

  def test_should_allow_invocations_until_expected_invocation_count_is_one_and_actual_invocation_count_would_be_two
    expectation = new_expectation.times(1)
    assert expectation.invocations_allowed?
    invoke(expectation)
    assert !expectation.invocations_allowed?
  end

  def test_should_allow_invocations_until_expected_invocation_count_is_two_and_actual_invocation_count_would_be_three
    expectation = new_expectation.times(2)
    2.times do
      assert expectation.invocations_allowed?
      invoke(expectation)
    end
    assert !expectation.invocations_allowed?
  end

  def test_should_allow_invocations_until_expected_invocation_count_is_a_range_from_two_to_three_and_actual_invocation_count_would_be_four
    expectation = new_expectation.times(2..3)
    3.times do
      assert expectation.invocations_allowed?
      invoke(expectation)
    end
    assert !expectation.invocations_allowed?
  end

  def test_should_never_allow_invocations
    expectation = new_expectation.never
    assert expectation.invocations_never_allowed?
    invoke(expectation)
    assert expectation.invocations_never_allowed?
  end

  def test_should_store_provided_backtrace
    backtrace = Object.new
    assert_equal backtrace, Expectation.new(nil, :expected_method, backtrace).backtrace
  end

  def test_should_default_backtrace_to_caller
    execution_point = ExecutionPoint.current; expectation = Expectation.new(nil, :expected_method)
    assert_equal execution_point, ExecutionPoint.new(expectation.backtrace)
  end

  def test_should_not_yield
    yielded = false
    invoke(new_expectation) { yielded = true }
    assert_equal false, yielded
  end

  def test_should_yield_no_parameters
    yielded_parameters = nil
    invoke(new_expectation.yields) { |*parameters| yielded_parameters = parameters }
    assert_equal [], yielded_parameters
  end

  def test_yields_should_raise_local_jump_error_when_the_caller_does_not_provide_a_block
    assert_raises(LocalJumpError) { invoke(new_expectation.yields(:foo)) }
  end

  def test_multiple_yields_should_raise_local_jump_error_when_caller_does_not_provide_block
    assert_raises(LocalJumpError) { invoke(new_expectation.multiple_yields(:foo, 1, [2, 3])) }
  end

  def test_should_yield_with_specified_parameters
    yielded_parameters = nil
    invoke(new_expectation.yields(1, 2, 3)) { |*parameters| yielded_parameters = parameters }
    assert_equal [1, 2, 3], yielded_parameters
  end

  def test_should_yield_different_parameters_on_consecutive_invocations
    expectation = new_expectation.yields(1, 2, 3).yields(4, 5)
    yielded_parameters = []
    invoke(expectation) { |*parameters| yielded_parameters << parameters }
    invoke(expectation) { |*parameters| yielded_parameters << parameters }
    assert_equal [[1, 2, 3], [4, 5]], yielded_parameters
  end

  def test_should_yield_multiple_times_for_single_invocation
    yielded_parameters = []
    invoke(new_expectation.multiple_yields([1, 2, 3], [4, 5])) { |*parameters| yielded_parameters << parameters }
    assert_equal [[1, 2, 3], [4, 5]], yielded_parameters
  end

  def test_should_yield_multiple_times_for_first_invocation_and_once_for_second_invocation
    expectation = new_expectation.multiple_yields([1, 2, 3], [4, 5]).then.yields(6, 7)
    yielded_parameters = []
    invoke(expectation) { |*parameters| yielded_parameters << parameters }
    invoke(expectation) { |*parameters| yielded_parameters << parameters }
    assert_equal [[1, 2, 3], [4, 5], [6, 7]], yielded_parameters
  end

  def test_should_return_specified_value
    assert_equal 99, invoke(new_expectation.returns(99))
  end

  def test_should_return_same_specified_value_multiple_times
    expectation = new_expectation.returns(99)
    assert_equal 99, invoke(expectation)
    assert_equal 99, invoke(expectation)
  end

  def test_should_return_specified_values_on_consecutive_calls
    expectation = new_expectation.returns(99, 100, 101)
    assert_equal 99, invoke(expectation)
    assert_equal 100, invoke(expectation)
    assert_equal 101, invoke(expectation)
  end

  def test_should_return_specified_values_on_consecutive_calls_even_if_values_are_modified
    values = [99, 100, 101]
    expectation = new_expectation.returns(*values)
    values.shift
    assert_equal 99, invoke(expectation)
    assert_equal 100, invoke(expectation)
    assert_equal 101, invoke(expectation)
  end

  def test_should_return_nil_by_default
    assert_nil invoke(new_expectation)
  end

  def test_should_return_nil_if_no_value_specified
    assert_nil invoke(new_expectation.returns)
  end

  def test_should_raise_runtime_exception
    assert_raises(RuntimeError) { invoke(new_expectation.raises) }
  end

  def test_should_raise_custom_exception
    exception = Class.new(StandardError)
    assert_raises(exception) { invoke(new_expectation.raises(exception)) }
  end

  def test_should_raise_same_instance_of_custom_exception
    exception_klass = Class.new(StandardError)
    expected_exception = exception_klass.new
    actual_exception = assert_raises(exception_klass) { invoke(new_expectation.raises(expected_exception)) }
    assert_same expected_exception, actual_exception
  end

  def test_should_use_the_default_exception_message
    exception = assert_raises(Exception) { invoke(new_expectation.raises(Exception)) }
    assert_equal Exception.new.message, exception.message
  end

  def test_should_raise_custom_exception_with_message
    exception_msg = 'exception message'
    exception = assert_raises(Exception) { invoke(new_expectation.raises(Exception, exception_msg)) }
    assert_equal exception_msg, exception.message
  end

  def test_should_return_values_then_raise_exception
    expectation = new_expectation.returns(1, 2).then.raises
    assert_equal 1, invoke(expectation)
    assert_equal 2, invoke(expectation)
    assert_raises(RuntimeError) { invoke(expectation) }
  end

  def test_should_raise_exception_then_return_values
    expectation = new_expectation.raises.then.returns(1, 2)
    assert_raises(RuntimeError) { invoke(expectation) }
    assert_equal 1, invoke(expectation)
    assert_equal 2, invoke(expectation)
  end

  def test_should_verify_successfully_if_expected_call_was_made
    expectation = new_expectation
    invoke(expectation)
    assert expectation.verified?
  end

  def test_should_not_verify_successfully_if_call_expected_once_but_invoked_twice
    expectation = new_expectation.once
    invoke(expectation)
    invoke(expectation)
    assert !expectation.verified?
  end

  def test_should_not_verify_successfully_if_call_expected_once_but_not_invoked
    assert !new_expectation.once.verified?
  end

  def test_should_verify_successfully_if_call_expected_once_and_invoked_once
    expectation = new_expectation.once
    invoke(expectation)
    assert expectation.verified?
  end

  def test_should_not_verify_successfully_if_call_expected_thrice_and_invoked_four_times
    expectation = new_expectation.thrice
    invoke(expectation)
    invoke(expectation)
    invoke(expectation)
    invoke(expectation)
    assert !expectation.verified?
  end

  def test_should_not_verify_successfully_if_call_expected_thrice_but_invoked_twice
    expectation = new_expectation.thrice
    invoke(expectation)
    invoke(expectation)
    assert !expectation.verified?
  end

  def test_should_verify_successfully_if_call_expected_thrice_and_invoked_thrice
    expectation = new_expectation.thrice
    invoke(expectation)
    invoke(expectation)
    invoke(expectation)
    assert expectation.verified?
  end

  def test_should_not_verify_successfully_if_call_expected_twice_and_invoked_three_times
    expectation = new_expectation.twice
    invoke(expectation)
    invoke(expectation)
    invoke(expectation)
    assert !expectation.verified?
  end

  def test_should_not_verify_successfully_if_call_expected_twice_but_invoked_once
    expectation = new_expectation.twice
    invoke(expectation)
    assert !expectation.verified?
  end

  def test_should_verify_successfully_if_call_expected_twice_and_invoked_twice
    expectation = new_expectation.twice
    invoke(expectation)
    invoke(expectation)
    assert expectation.verified?
  end

  def test_should_verify_successfully_if_expected_call_was_made_at_least_once
    expectation = new_expectation.at_least_once
    3.times { invoke(expectation) }
    assert expectation.verified?
  end

  def test_should_not_verify_successfully_if_expected_call_was_not_made_at_least_once
    expectation = new_expectation.with(1, 2, 3).at_least_once
    assert !expectation.verified?
    assert_match(/expected at least once, invoked never/i, expectation.mocha_inspect)
  end

  def test_should_verify_successfully_if_expected_call_was_made_expected_number_of_times
    expectation = new_expectation.times(2)
    2.times { invoke(expectation) }
    assert expectation.verified?
  end

  def test_should_not_verify_successfully_if_expected_call_was_made_too_few_times
    expectation = new_expectation.times(2)
    1.times { invoke(expectation) }
    assert !expectation.verified?
    assert_match(/expected exactly twice, invoked once/i, expectation.mocha_inspect)
  end

  def test_should_not_verify_successfully_if_expected_call_was_made_too_many_times
    expectation = new_expectation.times(2)
    3.times { invoke(expectation) }
    assert !expectation.verified?
  end

  def test_should_increment_assertion_counter_for_expectation_because_it_does_need_verifyng
    expectation = new_expectation
    invoke(expectation)
    assertion_counter = SimpleCounter.new
    expectation.verified?(assertion_counter)
    assert_equal 1, assertion_counter.count
  end

  def test_should_not_increment_assertion_counter_for_stub_because_it_does_not_need_verifying
    assertion_counter = SimpleCounter.new
    Expectation.new(nil, :expected_method).at_least(0).verified?(assertion_counter)
    assert_equal 0, assertion_counter.count
  end

  def test_should_store_backtrace_from_point_where_expectation_was_created
    execution_point = ExecutionPoint.current; expectation = Expectation.new(nil, :expected_method)
    assert_equal execution_point, ExecutionPoint.new(expectation.backtrace)
  end

  class FakeMock
    def initialize(name)
      @name = name
    end

    def mocha_inspect
      @name
    end
  end

  def test_should_raise_error_with_message_indicating_which_method_was_expected_to_be_called_on_which_mock_object_with_which_parameters_and_in_what_sequences
    mock = FakeMock.new('mock')
    sequence_one = Sequence.new('one')
    sequence_two = Sequence.new('two')
    expectation = Expectation.new(mock, :expected_method).with(1, 2, { 'a' => true }, { b: false }, [1, 2, 3]).in_sequence(sequence_one, sequence_two)
    assert !expectation.verified?
    assert_match %{mock.expected_method(1, 2, {"a" => true}, {b: false}, [1, 2, 3]); in sequence "one"; in sequence "two"}, expectation.mocha_inspect
  end

  class FakeConstraint
    def initialize(allows_invocation_now)
      @allows_invocation_now = allows_invocation_now
    end

    def allows_invocation_now?
      @allows_invocation_now
    end
  end

  def test_should_be_in_correct_order_if_all_ordering_constraints_allow_invocation_now
    constraint_one = FakeConstraint.new(true)
    constraint_two = FakeConstraint.new(true)
    expectation = Expectation.new(nil, :method_one)
    expectation.add_ordering_constraint(constraint_one)
    expectation.add_ordering_constraint(constraint_two)
    assert expectation.in_correct_order?
  end

  def test_should_not_be_in_correct_order_if_one_ordering_constraint_does_not_allow_invocation_now
    constraint_one = FakeConstraint.new(true)
    constraint_two = FakeConstraint.new(false)
    expectation = Expectation.new(nil, :method_one)
    expectation.add_ordering_constraint(constraint_one)
    expectation.add_ordering_constraint(constraint_two)
    assert !expectation.in_correct_order?
  end

  def test_should_match_if_all_ordering_constraints_allow_invocation_now
    constraint_one = FakeConstraint.new(true)
    constraint_two = FakeConstraint.new(true)
    expectation = Expectation.new(nil, :method_one)
    expectation.add_ordering_constraint(constraint_one)
    expectation.add_ordering_constraint(constraint_two)
    assert expectation.match?(Invocation.new(:irrelevant, :method_one))
  end

  def test_should_not_match_if_one_ordering_constraints_does_not_allow_invocation_now
    constraint_one = FakeConstraint.new(true)
    constraint_two = FakeConstraint.new(false)
    expectation = Expectation.new(nil, :method_one)
    expectation.add_ordering_constraint(constraint_one)
    expectation.add_ordering_constraint(constraint_two)
    assert !expectation.match?(Invocation.new(:irrelevant, :method_one))
  end

  def test_should_not_be_satisfied_when_required_invocation_has_not_been_made
    assert !Expectation.new(nil, :method_one).times(1).satisfied?
  end

  def test_should_be_satisfied_when_required_invocation_has_been_made
    expectation = Expectation.new(nil, :method_one).times(1)
    invoke(expectation)
    assert expectation.satisfied?
  end

  def test_should_not_be_satisfied_when_minimum_number_of_invocations_has_not_been_made
    expectation = Expectation.new(nil, :method_one).at_least(2)
    invoke(expectation)
    assert !expectation.satisfied?
  end

  def test_should_be_satisfied_when_minimum_number_of_invocations_has_been_made
    expectation = Expectation.new(nil, :method_one).at_least(2)
    2.times { invoke(expectation) }
    assert expectation.satisfied?
  end

  class FakeSequence
    attr_reader :expectations

    def initialize
      @expectations = []
    end

    def constrain_as_next_in_sequence(expectation)
      @expectations << expectation
    end
  end

  def test_should_tell_sequences_to_constrain_expectation_as_next_in_sequence
    sequence_one = FakeSequence.new
    sequence_two = FakeSequence.new
    expectation = Expectation.new(nil, :method_one)
    assert_equal expectation, expectation.in_sequence(sequence_one, sequence_two)
    assert_equal [expectation], sequence_one.expectations
    assert_equal [expectation], sequence_two.expectations
  end

  class FakeState
    def initialize
      @active = false
    end

    def activate
      @active = true
    end

    def active?
      @active
    end
  end

  def test_should_change_state_when_expectation_is_invoked
    state = FakeState.new
    expectation = Expectation.new(nil, :method_one)

    expectation.then(state)

    invoke(expectation)
    assert state.active?
  end

  def test_should_match_when_state_is_active
    state = FakeState.new
    expectation = Expectation.new(nil, :method_one)

    expectation.when(state)
    assert !expectation.match?(Invocation.new(:irrelevant, :method_one))

    state.activate
    assert expectation.match?(Invocation.new(:irrelevant, :method_one))
  end

  def test_should_include_default_representation_of_object_in_inspect
    object = Object.new
    class << object
      define_method(:inspect) { 'mock' }
    end
    assert_match Regexp.new('^#<Expectation:0x[0-9A-Fa-f]{1,12} .* >$'), Expectation.new(object, :method_one).inspect
  end

  def test_should_include_output_of_mocha_inspect_in_inspect
    object = Object.new
    class << object
      define_method(:inspect) { 'mock' }
    end
    expectation = Expectation.new(object, :method_one)
    assert expectation.inspect.include?(expectation.mocha_inspect)
  end
end
