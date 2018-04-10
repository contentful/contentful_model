module Contentful
  module Validations
    # Class to define lambda validations
    class LambdaValidation
      def initialize(name, fn)
        @name = name
        fail "#{name}: Validator function or Proc is required" unless fn.is_a?(Proc)
        @validator = fn
      end

      def validate(entry)
        return ["#{@name}: validation not met"] unless @validator[entry]
        []
      end
    end
  end
end
