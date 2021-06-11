module Vega
  class LiteChart < BaseChart
    # https://vega.github.io/vega-lite/docs/spec.html
    scalar_methods \
      :background, :padding, :autosize, :title, :name, :description, :width, :height, :repeat

    hash_methods \
      :config, :usermeta, :projection, :datasets, :encoding, :facet, :resolve, :selection, :view,
      :mark

    array_methods \
      :transform, :params

    def initialize(
      initial_spec = {},
      schema: "https://vega.github.io/schema/vega-lite/v4.json"
    )
      super
    end

    %I[layer hconcat vconcat concat].each do |composition|
      array_method "__#{composition}", composition
      define_method("#{composition}!") do |args|
        args = Array(args).map { |v| LiteChart.to_view_spec(v) }
        send("__#{composition}!", args)
      end
      immutable_method composition
    end

    VIEW_FIELDS = %I[data params mark encoding transform projection
                     selection hconcat vconcat layer repeat facet
                     spec width height].freeze

    def to_view!
      @spec = @spec.slice(*VIEW_FIELDS)
      @spec.delete(:width) if @spec[:width] == "container"
      @spec.delete(:height) if @spec[:height] == "container"
      self
    end

    def to_view
      dup.to_view!
    end

    def data!(value)
      @spec[:data] = data_value(value)
      self
    end
    immutable_method :data

    scalar_method :__spec, :spec

    def spec!(view)
      __spec!(LiteChart.to_view_spec(view))
    end

    def spec(*args)
      if args.empty?
        @spec
      else
        dup.spec!(*args)
      end
    end

    def self.to_view_spec(v)
      if v.respond_to?(:to_view)
        v.to_view.spec
      else
        v
      end
    end
  end
end
