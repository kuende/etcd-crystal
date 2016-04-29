class BeDirectoryMatcher(T)
  include Spec2::Matcher

  def initialize
  end

  def match(actual : T)
    @actual = actual

    if @actual != nil
      @actual.not_nil!.dir == true
    end
  end

  def failure_message
    "Expected #{@actual.inspect} to be directory"
  end

  def failure_message_when_negated
    "Expected #{@actual.inspect} to not be directory"
  end

  def description
    ""
  end
end
