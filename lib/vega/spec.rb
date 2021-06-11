module Vega
  class Spec
    def initialize(spec)
      spec = spec.spec if spec.respond_to?(:spec)
      raise ArgumentError, "Expected Hash, not #{spec.class.name}" unless spec.is_a?(Hash)
      @spec = spec.transform_keys!(&:to_s)
    end

    def to_s
      html, js = generate_output
      output = <<~EOS
        #{html}
        <script>
          #{js}
        </script>
      EOS
      output.respond_to?(:html_safe) ? output.html_safe : output
    end

    # TODO only load vega-lite if $schema requires it
    def to_iruby
      html, js = generate_output
      output = <<~EOS
        #{html}
        <script>
          require.config({
            paths: {
              'vega': 'https://cdn.jsdelivr.net/npm/vega@5.20.2?noext',
              'vega-lite': 'https://cdn.jsdelivr.net/npm/vega-lite@5.1.0?noext',
              'vega-util': 'https://cdn.jsdelivr.net/npm/vega-util@1.16.1?noext',
              'vega-embed': 'https://cdn.jsdelivr.net/npm/vega-embed@6.18.2?noext'
            }
          });
          require(['vega', 'vega-lite', 'vega-embed', 'vega-util'], function(vega, vegaLite, vegaEmbed, vegaUtil) {
            #{js}
          });
        </script>
      EOS
      ["text/html", output]
    end

    private

    def generate_output
      id = "chart-#{SecureRandom.hex(16)}" # 2**128 values
      width = @spec["width"].is_a?(Integer) ? "#{@spec["width"]}px" : "100%"
      height = @spec["height"].is_a?(Integer) ? "#{@spec["height"]}px" : "300px"

      # user can override with usermeta: {embedOptions: ...}
      embed_options = {actions: false, logLevel: "vega.Info"}

      # html vars
      html_vars = {
        id: id
      }
      html_vars.each_key do |k|
        html_vars[k] = ERB::Util.html_escape(html_vars[k])
      end

      # css vars
      css_vars = {
        height: height,
        width: width
      }
      css_vars.each_key do |k|
        # limit to alphanumeric and % for simplicity
        # this prevents things like calc() but safety is the priority
        raise ArgumentError, "Invalid #{k}" unless css_vars[k] =~ /\A[a-zA-Z0-9%]*\z/
        # we limit above, but escape for safety as fail-safe
        # to prevent XSS injection in worse-case scenario
        css_vars[k] = ERB::Util.html_escape(css_vars[k])
      end

      # js vars
      js_vars = {
        el: "##{id}",
        spec: @spec,
        opt: embed_options
      }
      js_vars.each_key do |k|
        js_vars[k] = json_escape(js_vars[k].to_json)
      end

      # needs width to be set for vegaEmbed to work
      html = %(<div id="%{id}" style="width: %{width}; height: %{height};"></div>) % html_vars.merge(css_vars)
      js = "vegaEmbed(%{el}, %{spec}, %{opt}).catch(console.error);" % js_vars

      [html, js]
    end

    # from https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/string/output_safety.rb
    JSON_ESCAPE = { "&" => '\u0026', ">" => '\u003e', "<" => '\u003c', "\u2028" => '\u2028', "\u2029" => '\u2029' }
    JSON_ESCAPE_REGEXP = /[\u2028\u2029&><]/u
    def json_escape(s)
      if ERB::Util.respond_to?(:json_escape)
        ERB::Util.json_escape(s)
      else
        s.to_s.gsub(JSON_ESCAPE_REGEXP, JSON_ESCAPE)
      end
    end
  end
end
