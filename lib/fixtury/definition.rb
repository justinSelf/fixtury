# frozen_string_literal: true

module Fixtury
  class Definition

    attr_reader :name
    attr_reader :schema

    attr_reader :callable
    attr_reader :enhancements

    def initialize(schema: nil, name:, &block)
      @name = name
      @schema = schema
      @callable = block
      @enhancements = []
    end

    def enhance(&block)
      @enhancements << block
    end

    def enhanced?
      @enhancements.any?
    end

    def call(store: nil, execution_context: nil)
      maybe_set_store_context(store: store) do
        value = run_callable(store: store, callable: callable, execution_context: execution_context, value: nil)
        enhancements.each do |e|
          value = run_callable(store: store, callable: e, execution_context: execution_context, value: value)
        end
        value
      end
    end

    protected

    def maybe_set_store_context(store:)
      return yield unless store

      store.with_relative_schema(schema) do
        yield
      end
    end

    def run_callable(store:, callable:, execution_context:, value:)
      execution_context ||= self

      args = []
      args << value unless value.nil?
      if callable.arity > args.length
        raise ArgumentError, "A store store must be provided if the definition expects it." unless store

        args << store
      end

      if args.length.positive?
        execution_context.instance_exec(*args, &callable)
      else
        execution_context.instance_eval(&callable)
      end
    end

  end
end
