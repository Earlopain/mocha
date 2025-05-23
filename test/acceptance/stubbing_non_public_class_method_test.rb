# frozen_string_literal: true

require File.expand_path('../acceptance_test_helper', __FILE__)
require 'mocha/configuration'

class StubbingNonPublicClassMethodTest < Mocha::TestCase
  include AcceptanceTestHelper

  def setup
    setup_acceptance_test
  end

  def teardown
    teardown_acceptance_test
  end

  def test_should_allow_stubbing_private_class_method
    Mocha.configure { |c| c.stubbing_non_public_method = :allow }
    klass = Class.new do
      class << self
        def private_method; end
        private :private_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:private_method)
    end
    assert_passed(test_result)
    assert !@logger.warnings.include?("stubbing non-public method: #{klass.mocha_inspect}.private_method")
  end

  def test_should_allow_stubbing_protected_class_method
    Mocha.configure { |c| c.stubbing_non_public_method = :allow }
    klass = Class.new do
      class << self
        def protected_method; end
        protected :protected_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:protected_method)
    end
    assert_passed(test_result)
    assert !@logger.warnings.include?("stubbing non-public method: #{klass.mocha_inspect}.protected_method")
  end

  def test_should_warn_when_stubbing_private_class_method
    Mocha.configure { |c| c.stubbing_non_public_method = :warn }
    klass = Class.new do
      class << self
        def private_method; end
        private :private_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:private_method)
    end
    assert_passed(test_result)
    assert @logger.warnings.include?("stubbing non-public method: #{klass.mocha_inspect}.private_method")
  end

  def test_should_warn_when_stubbing_protected_class_method
    Mocha.configure { |c| c.stubbing_non_public_method = :warn }
    klass = Class.new do
      class << self
        def protected_method; end
        protected :protected_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:protected_method)
    end
    assert_passed(test_result)
    assert @logger.warnings.include?("stubbing non-public method: #{klass.mocha_inspect}.protected_method")
  end

  def test_should_prevent_stubbing_private_class_method
    Mocha.configure { |c| c.stubbing_non_public_method = :prevent }
    klass = Class.new do
      class << self
        def private_method; end
        private :private_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:private_method)
    end
    assert_errored(test_result)
    assert test_result.error_messages.include?("Mocha::StubbingError: stubbing non-public method: #{klass.mocha_inspect}.private_method")
  end

  def test_should_prevent_stubbing_protected_class_method
    Mocha.configure { |c| c.stubbing_non_public_method = :prevent }
    klass = Class.new do
      class << self
        def protected_method; end
        protected :protected_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:protected_method)
    end
    assert_errored(test_result)
    assert test_result.error_messages.include?("Mocha::StubbingError: stubbing non-public method: #{klass.mocha_inspect}.protected_method")
  end

  def test_should_default_to_allow_stubbing_private_class_method
    klass = Class.new do
      class << self
        def private_method; end
        private :private_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:private_method)
    end
    assert_passed(test_result)
    assert !@logger.warnings.include?("stubbing non-public method: #{klass.mocha_inspect}.private_method")
  end

  def test_should_default_to_allow_stubbing_protected_class_method
    klass = Class.new do
      class << self
        def protected_method; end
        protected :protected_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:protected_method)
    end
    assert_passed(test_result)
    assert !@logger.warnings.include?("stubbing non-public method: #{klass.mocha_inspect}.protected_method")
  end

  def test_should_allow_stubbing_public_class_method
    Mocha.configure { |c| c.stubbing_non_public_method = :prevent }
    klass = Class.new do
      class << self
        def public_method; end
        public :public_method
      end
    end
    test_result = run_as_test do
      klass.stubs(:public_method)
    end
    assert_passed(test_result)
  end

  def test_should_allow_stubbing_method_to_which_class_responds
    Mocha.configure { |c| c.stubbing_non_public_method = :prevent }
    klass = Class.new do
      class << self
        def respond_to_missing?(method, _include_all = false)
          (method == :method_to_which_class_responds)
        end
      end
    end
    test_result = run_as_test do
      klass.stubs(:method_to_which_class_responds)
    end
    assert_passed(test_result)
  end
end
