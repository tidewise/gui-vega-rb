module Vega
  module MethodHelpers
    private

    def scalar_methods(*methods)
      methods.each do |method|
        scalar_method(method, method)
      end
    end

    def scalar_method(method, field_name)
      define_method("#{method}!") do |value|
        @spec[field_name] = value
        self
      end
      immutable_method(method)
    end

    def hash_methods(*methods)
      methods.each do |method|
        define_method("#{method}!") do |value|
          (@spec[method] ||= {}).merge!(value)
          self
        end
        immutable_method(method)
      end
    end

    def array_method(method, field_name)
      define_method("#{method}!") do |value|
        value = [value] unless value.is_a?(Array)
        (@spec[field_name] ||= []).push(*value)
        self
      end
      immutable_method(method)
    end

    def array_methods(*methods)
      methods.each do |method|
        array_method(method, method)
      end
    end

    def immutable_method(method)
      define_method(method) do |value|
        dup.send("#{method}!", value)
      end
    end
  end
end
